extends "res://scripts/main.gd"

# A test-only input source. All production simulation, RPCs and snapshots run normally.
var test_move: Vector2 = Vector2.ZERO
var test_run: bool = false
var test_events: Dictionary = {}

func _read_command() -> Dictionary:
	if not playing or paused or won or ui.screen != "hud":
		return super._read_command()
	var command: Dictionary = {"x": test_move.x, "y": test_move.y, "yaw": yaw, "pitch": pitch, "jump": false, "run": test_run, "ability": false, "interact": false, "regroup": false, "switch": -1}
	for key in test_events:
		command[key] = test_events[key]
	test_events.clear()
	return command
