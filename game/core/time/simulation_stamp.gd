class_name SimulationStamp
extends RefCounted
## A detached read-only public view. No wall clock or scene/player reference.

var elapsed_seconds: float:
	get: return _seconds
var physics_tick: int:
	get: return _tick
var epoch: int:
	get: return _epoch

var _seconds: float
var _tick: int
var _epoch: int

func _init(seconds: float = 0.0, tick: int = 0, load_epoch: int = 0) -> void:
	_seconds = seconds
	_tick = tick
	_epoch = load_epoch
