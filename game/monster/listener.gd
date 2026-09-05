class_name Listener
extends CharacterBody3D
## One embodied predator. Planning targets ONLY dated perception, never a hidden transform.

signal state_changed(next: State)
signal heard(kind: StringName, estimated_position: Vector3)
signal footstep

enum State { ROAMING, INVESTIGATING, CHASING, SEARCHING, ATTACKING, STAGGERED, RETREATING }
const MODEL: PackedScene = preload("res://assets/listener/listener_gameplay.glb")
const WALK_SPEED: float = 1.25
const CHASE_SPEED: float = 3.85
const MEMORY_SECONDS: float = 18.0
const ATTACK_REACH: float = 1.35

var player: SectionPlayer
var section: NullspaceSection
var state: State = State.ROAMING
var enabled: bool = true
var patrol: Array[Vector3] = [Vector3(-4.3, 0.05, -11.3), Vector3(2.6, 0.05, -12.0),
	Vector3(3.8, 0.05, -7.1), Vector3(-4.2, 0.05, -7.2)]
var evidence_position: Vector3
var evidence_time: float = -1000.0
var confidence: float = 0.0
var sees_player: bool = false
var navigation: NavigationAgent3D
var animation: AnimationPlayer
var model: Node3D
var _notice: float = 0.0
var _state_time: float = 0.0
var _perception_timer: float = 0.0
var _path_timer: float = 0.0
var _roam_index: int = 0
var _search_index: int = 0
var _search_points: Array[Vector3] = []
var _goal: Vector3
var _rest: float = 0.0
var _attack_applied: bool = false
var _wounds: int = 0
var _last_wound: float = -1000.0
var _quiet_until: float = 18.0
var _travel: float = 0.0
var _metrics_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 4
	collision_mask = 1 | 2
	floor_snap_length = 0.25
	safe_margin = 0.002
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 2.3
	collider.shape = capsule
	collider.position.y = 1.15
	add_child(collider)
	model = MODEL.instantiate() as Node3D
	model.rotation.y = PI # Authored +Z facing, controller -Z facing.
	add_child(model)
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in ["idle", "breathing", "listen", "walk", "run"]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play(&"idle")
	navigation = NavigationAgent3D.new()
	navigation.path_desired_distance = 0.26
	navigation.target_desired_distance = 0.45
	navigation.radius = 0.28
	navigation.height = 2.3
	add_child(navigation)
	_goal = patrol[0]

func reset_at(anchor: Vector3) -> void:
	global_position = anchor
	velocity = Vector3.ZERO
	rotation.y = 0.0
	evidence_position = anchor
	evidence_time = -1000.0
	confidence = 0.0
	sees_player = false
	_notice = 0.0
	_wounds = 0
	_state_time = 0.0
	_rest = 0.0
	_path_timer = 0.0
	_travel = 0.0
	_roam_index = 0
	_goal = patrol[0]
	_quiet_until = _now() + 18.0
	_set_state(State.ROAMING)
	animation.play(&"idle", 0.0)

func _physics_process(delta: float) -> void:
	if not enabled or GameFlow.state != NullGameFlow.State.PLAYING:
		return
	_state_time += delta
	_perception_timer += delta
	if _perception_timer >= 0.10:
		_perceive(_perception_timer)
		_perception_timer = 0.0
	confidence = maxf(0.0, confidence - delta / MEMORY_SECONDS)
	if _now() - _last_wound > 18:
		_wounds = 0
	var speed: float = WALK_SPEED
	var still: bool = false
	match state:
		State.ROAMING:
			still = _now() < _quiet_until or _rest > 0
			if not still and _horizontal_distance(_goal) < 0.6:
				_roam_index = (_roam_index + 1) % patrol.size()
				_goal = patrol[_roam_index]
				_rest = 2.5
		State.INVESTIGATING:
			speed = 1.7
			_goal = evidence_position
			if _horizontal_distance(_goal) < 0.7 or confidence == 0:
				_begin_search()
		State.CHASING:
			speed = CHASE_SPEED
			_goal = evidence_position
			if sees_player and _horizontal_distance(evidence_position) < ATTACK_REACH:
				_set_state(State.ATTACKING)
				still = true
			elif not sees_player and _now() - evidence_time > 0.6:
				_set_state(State.INVESTIGATING)
		State.SEARCHING:
			if confidence == 0.0 or _state_time > 14.0:
				_set_state(State.ROAMING)
				_goal = patrol[_roam_index]
			else:
				still = _rest > 0
				if _horizontal_distance(_goal) < 0.6:
					_search_index += 1
					_rest = 1.2
					if _search_index >= _search_points.size():
						_set_state(State.ROAMING)
						confidence = 0.0
						_goal = patrol[_roam_index]
					else:
						_goal = _search_points[_search_index]
		State.ATTACKING:
			still = true
			if _state_time < .25:
				var aim: Vector3 = evidence_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-aim.x, -aim.z), minf(delta * 7, 1))
			if _state_time >= 0.60 and not _attack_applied:
				_attack_applied = true
				# Physical contact at impact time, not a cached visible flag or through-wall hit.
				if _clear_attack():
					player.take_damage(55.0)
					Telemetry.record(&"listener_hit", {"health": player.health})
			if _state_time >= 1.55:
				_set_state(State.CHASING if sees_player else State.INVESTIGATING)
		State.STAGGERED:
			still = true
			if _state_time >= 0.90:
				if _wounds >= 3:
					_begin_retreat()
				else:
					_set_state(State.INVESTIGATING)
		State.RETREATING:
			speed = 2.2
			if _horizontal_distance(_goal) < 0.7 or _state_time > 5.0:
				_wounds = 0
				confidence = 0.0
				_quiet_until = _now() + 4.5
				_set_state(State.ROAMING)
				_goal = patrol[_roam_index]
	_rest = maxf(_rest - delta, 0)
	_path_timer -= delta
	if _path_timer <= 0:
		_path_timer = 0.25
		navigation.target_position = _goal
	var direction := Vector3.ZERO
	if not still and not navigation.is_navigation_finished():
		direction = navigation.get_next_path_position() - global_position
		direction.y = 0.0
		direction = direction.normalized()
		if direction.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 5, 1))
	var desired: Vector3 = direction * speed
	if direction.length_squared() > .01:
		var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP,
			global_position + Vector3.UP + direction * 1.5, 1, [get_rid()])
		var obstacle: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
		var leaf := obstacle.get("collider") as SectionDoor.Leaf
		if leaf:
			leaf.door.open_for_listener(state == State.CHASING)
	velocity.x = move_toward(velocity.x, desired.x, delta * (12 if still else 4.8))
	velocity.z = move_toward(velocity.z, desired.z, delta * (12 if still else 4.8))
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18 * delta
	var before: Vector3 = global_position
	move_and_slide()
	var moved: float = Vector2(global_position.x - before.x, global_position.z - before.z).length()
	_travel += moved
	var stride: float = 1.15 if speed > 2.7 else 0.70
	if _travel >= stride and is_on_floor():
		_travel = fmod(_travel, stride)
		footstep.emit()
	_update_animation(moved / maxf(delta, 0.001))
	_metrics_time += delta
	if _metrics_time >= 0.5:
		_metrics_time = 0.0
		Telemetry.record(&"listener_pose", {"state": State.keys()[state], "position": _v(global_position),
			"goal": _v(_goal), "evidence": _v(evidence_position), "age": _now() - evidence_time,
			"confidence": confidence, "sees_player": sees_player, "speed": moved / delta})

func _perceive(delta: float) -> void:
	sees_player = false
	var eye: Vector3 = global_position + Vector3.UP * 2.03
	var target: Vector3 = player.global_position + Vector3.UP * (0.75 if player.crouched else 1.30)
	var offset: Vector3 = target - eye
	var distance: float = offset.length()
	if distance < 24 and (-global_basis.z).dot(offset.normalized()) > cos(deg_to_rad(58)):
		var query := PhysicsRayQueryParameters3D.create(eye, target, 1 | 2, [get_rid()])
		var ray: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		sees_player = ray.get("collider") == player
	if sees_player:
		var exposure: float = section.room.light_exposure(player.global_position)
		var motion: float = 1.45 if player.sprinting else (1.0 if player.velocity.length() > 0.4 else 0.7)
		var posture: float = 0.50 if player.crouched else 1.0
		_notice += delta * exposure * motion * posture * (3.8 if distance < 4 else 1.7) * (1.2 if player.flashlight.visible else 1.0)
		if _notice >= 1.0 or state in [State.CHASING, State.ATTACKING]:
			evidence_position = player.global_position # DIRECT SIGHT only.
			evidence_time = _now()
			confidence = 1.0
			if state not in [State.ATTACKING, State.STAGGERED, State.RETREATING]:
				_set_state(State.CHASING)
	else:
		_notice = maxf(0.0, _notice - delta * 1.8)

func hear_at(position_estimate: Vector3, certainty: float, kind: StringName, stamp: SimulationStamp) -> void:
	if not enabled or stamp.epoch != SimulationClock.sample().epoch or sees_player:
		return
	if _now() - evidence_time < 0.8 and certainty < confidence:
		return
	evidence_position = position_estimate
	evidence_time = stamp.elapsed_seconds
	confidence = certainty
	heard.emit(kind, position_estimate)
	Telemetry.record(&"listener_heard", {"kind": kind, "estimate": _v(position_estimate), "certainty": certainty})
	if state not in [State.STAGGERED, State.RETREATING, State.ATTACKING]:
		_set_state(State.INVESTIGATING)

func receive_shot(point: Vector3, _strength: float) -> void:
	if not enabled:
		return
	_wounds += 1
	_last_wound = _now()
	_set_state(State.STAGGERED)
	_state_time = 0.0 # Each physical hit buys its own interruption, including a second stagger hit.
	animation.play(&"stagger", 0.06)
	Telemetry.record(&"listener_stagger", {"point": _v(point), "hits": _wounds})

func _clear_attack() -> bool:
	if _horizontal_distance(player.global_position) > ATTACK_REACH + 0.1:
		return false
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0
	if (-global_basis.z).dot(offset.normalized()) < .35:
		return false # Committed swing cannot hit a target that escaped behind it.
	var origin: Vector3 = global_position + Vector3.UP * 1.35
	var target: Vector3 = player.global_position + Vector3.UP * (0.7 if player.crouched else 1.15)
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1 | 2, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") == player

func _begin_search() -> void:
	_set_state(State.SEARCHING)
	_search_index = 0
	_search_points.clear()
	# Plausible points around OLD evidence, projected onto actual navigable space.
	for offset: Vector3 in [Vector3(2.8, 0, -1.5), Vector3(-2.5, 0, -2.2), Vector3(0.5, 0, 3.3)]:
		_search_points.append(NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, evidence_position + offset))
	_goal = _search_points[0]
	_rest = 1.4

func _begin_retreat() -> void:
	_set_state(State.RETREATING)
	_goal = patrol[0]
	for point: Vector3 in patrol:
		if point.distance_squared_to(evidence_position) > _goal.distance_squared_to(evidence_position):
			_goal = point

func _set_state(next: State) -> void:
	if state == next:
		return
	var previous: State = state
	state = next
	_state_time = 0.0
	if next == State.ATTACKING:
		_attack_applied = false
		animation.play(&"attack", 0.10)
	if next == State.CHASING:
		EventHub.gameplay_metric.emit(&"chase_started", {})
	elif previous == State.CHASING:
		EventHub.gameplay_metric.emit(&"chase_ended", {})
	if next == State.SEARCHING:
		EventHub.gameplay_metric.emit(&"search_started", {})
	state_changed.emit(next)
	Telemetry.record(&"listener_state", {"from": State.keys()[previous], "to": State.keys()[next]})

func _update_animation(speed: float) -> void:
	if state in [State.ATTACKING, State.STAGGERED]:
		animation.speed_scale = 1.0
		return
	var clip: StringName = &"idle"
	if speed > 0.15:
		clip = &"run" if speed > 2.7 else &"walk"
	elif state in [State.SEARCHING, State.INVESTIGATING]:
		clip = &"listen"
	if animation.current_animation != clip:
		animation.play(clip, 0.20)
	animation.speed_scale = clampf(speed / (3.4 if clip == &"run" else 1.15), 0.6, 1.65) if speed > 0.15 else 1.0

func _horizontal_distance(point: Vector3) -> float:
	return Vector2(global_position.x - point.x, global_position.z - point.z).length()

func _now() -> float:
	return SimulationClock.sample().elapsed_seconds

func _v(point: Vector3) -> Array[float]:
	return [point.x, point.y, point.z]
