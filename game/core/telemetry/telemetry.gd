class_name NullTelemetry
extends Node
## Local passive evidence. No network, scene control, RNG use, AI information or live overlay.

signal write_failed(detail: String)

var log_path: String = ""
var session_id: String = ""
var simulation_seconds: float = 0.0
var metrics: Dictionary = {}
var _file: FileAccess
var _sample_time: float = 0.0
var _chase_started: float = -1.0
var _last_encounter: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameFlow.state_changed.connect(_on_flow)
	GameFlow.load_started.connect(_on_load)
	InputGate.invalidated.connect(_on_input_invalidated)
	EventHub.shot_accepted.connect(_on_shot)
	EventHub.objective_committed.connect(_on_objective)
	EventHub.gameplay_metric.connect(record_metric)
	reset_metrics()
	_open_log()

func _exit_tree() -> void:
	if _file != null:
		record(&"shutdown", {"metrics": metrics})
		_file.close()

func _process(delta: float) -> void:
	if GameFlow.state == NullGameFlow.State.PLAYING:
		simulation_seconds += delta
		metrics["play_seconds"] = float(metrics["play_seconds"]) + delta
	_sample_time += delta
	if _sample_time < SnapshotSchema.TUNING.telemetry_frame_sample_seconds:
		return
	_sample_time = 0.0
	record(&"frame_sample", {"frame_ms": delta * 1000.0,
		"cpu_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"cpu_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"gpu_ms": null, "gpu_measurement_available": false,
		"fps": Engine.get_frames_per_second(), "static_memory_bytes": OS.get_static_memory_usage()})

func reset_metrics() -> void:
	metrics = {"play_seconds": 0.0, "deaths": 0, "damage_taken": 0.0, "shots_fired": 0,
		"ammo_collected": {}, "ammo_remaining": {}, "sightings": 0, "chases": 0,
		"chase_seconds": 0.0, "completed_chases": 0, "average_chase_seconds": 0.0,
		"searches": 0, "false_investigations": 0,
		"encounter_intervals": [], "objective_times": {}, "errors": 0}
	_chase_started = -1.0
	_last_encounter = -1.0

func record(kind: StringName, values: Dictionary = {}) -> void:
	if _file == null:
		return
	var entry: Dictionary = {"event": String(kind), "utc": Time.get_datetime_string_from_system(true),
		"monotonic_usec": Time.get_ticks_usec(), "simulation_seconds": simulation_seconds,
		"frame": Engine.get_process_frames(), "physics_tick": Engine.get_physics_frames(),
		"session_id": session_id, "flow": NullGameFlow.State.keys()[GameFlow.state],
		"focused": InputGate.focused, "paused": get_tree().paused,
		"input_provenance": String(InputGate.input_provenance), "values": values}
	_file.store_line(JSON.stringify(entry))
	_file.flush()
	if _file.get_error() != OK:
		_file.close()
		_file = null
		write_failed.emit("Telemetry write failed; gameplay continues.")

func record_metric(kind: StringName, values: Dictionary) -> void:
	match kind:
		&"damage":
			metrics["damage_taken"] += maxf(float(values.get("amount", 0.0)), 0.0)
		&"ammo_collected":
			var weapon: String = str(values.get("weapon_id", "unknown"))
			metrics["ammo_collected"][weapon] = int(metrics["ammo_collected"].get(weapon, 0)) + maxi(int(values.get("amount", 0)), 0)
		&"ammo_remaining":
			metrics["ammo_remaining"] = values.duplicate(true)
		&"sighting":
			metrics["sightings"] += 1
		&"chase_started":
			if _chase_started < 0.0:
				_chase_started = simulation_seconds
				metrics["chases"] += 1
		&"chase_ended":
			_close_chase()
		&"search_started":
			metrics["searches"] += 1
		&"false_investigation":
			metrics["false_investigations"] += 1
		&"encounter_started":
			if _last_encounter >= 0.0:
				metrics["encounter_intervals"].append(simulation_seconds - _last_encounter)
			_last_encounter = simulation_seconds
		&"error":
			metrics["errors"] += 1
	record(kind, values)

func _open_log() -> void:
	var directory: String = "user://telemetry"
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		write_failed.emit("Cannot create local telemetry directory.")
		return
	log_path = directory.path_join("run_%s_%s.jsonl" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	_file = FileAccess.open(log_path, FileAccess.WRITE)
	if _file == null:
		write_failed.emit("Cannot create local telemetry log.")
		return
	record(&"boot", {"build_id": AtomicJsonStore.BUILD_ID, "engine": Engine.get_version_info(),
		"os": OS.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"display": DisplayServer.get_name(), "settings": SettingsManager.snapshot(),
		"gpu_ms_available": false, "crash_detection": "external_supervisor_required"})

func _on_flow(_previous: NullGameFlow.State, current: NullGameFlow.State, reason: StringName) -> void:
	if current == NullGameFlow.State.DEAD:
		metrics["deaths"] += 1
	if current in [NullGameFlow.State.DEAD, NullGameFlow.State.ENDING, NullGameFlow.State.MENU]:
		_close_chase()
	record(&"flow_changed", {"reason": reason, "metrics": metrics})

func _on_load(snapshot: Dictionary, generation: int) -> void:
	var next_session: String = snapshot["session"]["id"]
	if next_session != session_id:
		reset_metrics()
		session_id = next_session
	simulation_seconds = float(snapshot["session"]["elapsed_seconds"])
	record(&"checkpoint_restore", {"checkpoint_id": snapshot["checkpoint"]["id"], "generation": generation})

func _on_input_invalidated(generation: int, reason: StringName) -> void:
	record(&"input_invalidated", {"generation": generation, "reason": reason})

func _on_shot(event: ShotEvent) -> void:
	metrics["shots_fired"] += 1
	record(&"shot", {"action_id": event.action_id, "weapon_id": event.weapon_id,
		"generation": event.generation, "hit_count": event.hits.size()})

func _on_objective(objective_id: StringName) -> void:
	metrics["objective_times"][objective_id] = simulation_seconds
	record(&"objective", {"objective_id": objective_id})

func _close_chase() -> void:
	if _chase_started >= 0.0:
		metrics["chase_seconds"] += maxf(simulation_seconds - _chase_started, 0.0)
		metrics["completed_chases"] += 1
		metrics["average_chase_seconds"] = float(metrics["chase_seconds"]) / int(metrics["completed_chases"])
		_chase_started = -1.0
