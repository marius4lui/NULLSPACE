class_name NullEventHub
extends Node
## Passive interfaces only. Does not fire, charge ammo, propagate acoustics or choose AI goals.

signal shot_accepted(event: ShotEvent)
signal observation_received(observation: PerceptionObservation)
signal objective_committed(objective_id: StringName)
signal gameplay_metric(kind: StringName, values: Dictionary)

var _sound_propagator: Callable
var _spatial_audio: Callable

func register_sound_propagator(receiver: Callable) -> Error:
	if _sound_propagator.is_valid() or not receiver.is_valid():
		return ERR_ALREADY_IN_USE if _sound_propagator.is_valid() else ERR_INVALID_PARAMETER
	_sound_propagator = receiver
	return OK

func register_spatial_audio(receiver: Callable) -> Error:
	if _spatial_audio.is_valid() or not receiver.is_valid():
		return ERR_ALREADY_IN_USE if _spatial_audio.is_valid() else ERR_INVALID_PARAMETER
	_spatial_audio = receiver
	return OK

func submit_sound(event: SoundEvent) -> void:
	if _sound_propagator.is_valid():
		_sound_propagator.call(event)
	if _spatial_audio.is_valid():
		_spatial_audio.call(event)

