extends SceneTree
## Integration check: real abilities, rigid-body magnet transport and all checkpoints.
## Run: godot --headless --path . --script tests/solo_smoke.gd
var game: Node3D
var puzzle: Node3D
var failures: Array[String] = []
var checkpoints: Array[int] = []
var victory_seen: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._solo()
	await process_frame
	# The harness supplies controller input, while robots and rigid bodies use Godot physics.
	game.set_physics_process(false)
	puzzle = game.puzzles
	puzzle.checkpoint_reached.connect(func(stage: int) -> void: checkpoints.append(stage))
	puzzle.victory_reached.connect(func() -> void: victory_seen = true)
	_expect(game.playing and game.ui.screen == "hud", "Solo starts and displays HUD")
	await _advance(10)
	game.robots[0].reset_at(Vector3(-4, 0.1, -7))
	game.robots[2].reset_at(Vector3(-5, 0.1, -7))
	_command(0, true)
	_expect(puzzle.held == -1 and puzzle.orbs[0].freeze, "First core cannot be taken before Liga releases its support")
	_command(2, true)
	_expect(bool(puzzle.flags.release) and not puzzle.orbs[0].freeze, "Liga releases the first support")
	_command(0, true)
	_expect(puzzle.held == 0, "Bipo acquires a valid nearby core")
	var first_home: Vector3 = puzzle.orbs[0].position
	var walked: bool = await _walk(0, Vector3(3, 0, -12.9), 420)
	_expect(walked, "Bipo can walk to the first socket while attracting the core")
	await _advance(150)
	_expect(puzzle.orbs[0].position.distance_to(first_home) > 6.0, "Magnet force transports the real rigid body across room one")
	_expect(bool(puzzle.flags.one) and puzzle.stage == 1, "First socket opens the first door and saves checkpoint one")
	_expect(checkpoints.has(1), "Checkpoint one signal is emitted")
	_command(0, false, true)
	await _advance(10)
	_expect(game.robots[0].position.z < -24.0 and bool(puzzle.flags.one), "Regroup moves robots to saved checkpoint and preserves solved puzzle")
	_expect(puzzle.orbs[0].freeze and puzzle.orbs[0].position.distance_to(puzzle.goals[0]) < 0.05, "Regroup preserves the locked first core")
	# Room two requires a gravity activation and an elastic bridge before its core can lock.
	game.robots[1].reset_at(Vector3(-3, 0.1, -25))
	game.robots[1].view_yaw = 0.0
	_command(1, true)
	await _advance(30)
	_expect(bool(puzzle.flags.lift) and puzzle.field_time > 0.0, "Gravi stabilizes the room-two core with an active field")
	game.robots[2].reset_at(Vector3(5, 0.1, -34.5))
	# Previous tether is dropped automatically when checkpoint regroup resets unsolved objects.
	_command(2, true)
	await _advance(3)
	_expect(bool(puzzle.flags.bridge) and puzzle.bridge.collision_layer == 1, "Liga extends a physical bridge from within ten units")
	# Wait out the field before carrying: the completed lift condition remains latched.
	await _advance(290)
	game.robots[0].reset_at(Vector3(-3, 0.1, -26.0))
	game.robots[0].view_yaw = 0.0
	_command(0, true)
	_expect(puzzle.held == 1, "Bipo acquires the second core")
	walked = await _walk(0, Vector3(0, 0, -32), 300)
	_expect(walked, "Bipo approaches the bridge with the core")
	walked = await _walk(0, Vector3(0, 0, -43.8), 420)
	_expect(walked and game.robots[0].position.y > -0.5, "Bipo and the core can cross the collision-enabled bridge")
	walked = await _walk(0, Vector3(-4, 0, -44.9), 240)
	await _advance(150)
	_expect(walked and bool(puzzle.flags.two) and puzzle.stage == 2, "Room two core reaches its terminal and checkpoint two is saved")
	_expect(checkpoints.has(2), "Checkpoint two signal is emitted")
	_command(0, false, true)
	await _advance(5)
	_expect(game.robots[0].position.z < -56 and bool(puzzle.flags.two), "Second checkpoint regroup preserves completed room two")
	# Restore an unsolved core through the actual nearby E interaction.
	puzzle.orbs[2].position = Vector3(2, 1, -66)
	game.robots[0].reset_at(Vector3(8, 0.1, -62))
	puzzle.interact(game.robots[0])
	await _advance(1)
	_expect(puzzle.orbs[2].position.distance_to(puzzle.homes[2]) < 0.15, "Room reset station restores an unsolved core")
	game.robots[0].reset_at(Vector3(-6, 0.1, -62))
	game.robots[0].view_yaw = 0.0
	_command(0, true)
	_expect(puzzle.held == 2, "Final magnetic core can be acquired")
	walked = await _walk(0, Vector3(-6, 0, -74.9), 480)
	await _advance(150)
	_expect(walked and bool(puzzle.flags.magnet), "Final magnetic device locks after real transport")
	game.robots[1].reset_at(Vector3(0, 0.1, -76))
	game.robots[1].view_yaw = 0.0
	_command(1, true)
	await _advance(190)
	_expect(bool(puzzle.flags.gravity) and puzzle.gravity_charge >= 3, "Final gravity device latches after three seconds")
	game.robots[2].reset_at(Vector3(6, 0.1, -73))
	_command(2, true)
	await _advance(190)
	_expect(bool(puzzle.flags.elastic), "Final elastic device latches after three seconds")
	_expect(bool(puzzle.flags.won), "All three devices activate the reactor and unlock the exit")
	game.robots[0].reset_at(Vector3(0, 0.1, -88))
	await _advance(3)
	_expect(puzzle.stage == 3 and victory_seen and game.won, "Crossing the unlocked exit triggers actual victory")
	# The eight-second completion sequence must reach its working replay/menu screen.
	await create_timer(8.1).timeout
	_expect(game.ui.screen == "victory", "Eight-second ending reaches the victory screen")
	game._restart()
	await process_frame
	_expect(game.playing and game.puzzles.stage == 0 and not game.won, "Replay starts a fresh playable solo session")
	# Fixed-FPS tests advance gameplay faster than the audio mixer's wall clock.
	# Release active playback before quitting so the mixer can drain its references.
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	game.sound_streams.clear()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	puzzle = null
	scene = null
	if failures.is_empty():
		print("SOLO_PLAYTHROUGH_OK: all three rooms, three abilities, rigid-body transports, recovery, checkpoints, ending and replay")
		quit(0)
	else:
		for failure in failures:
			push_error("SOLO_CHECK_FAILED: " + failure)
		quit(1)

func _command(index: int, ability: bool = false, regroup: bool = false) -> void:
	var command: Dictionary = {"x": 0.0, "y": 0.0, "yaw": game.robots[index].view_yaw, "pitch": 0.0, "jump": false, "run": false, "ability": ability, "interact": false, "regroup": regroup, "switch": index}
	game._receive_command(1, command)

func _advance(frames: int) -> void:
	for frame in range(frames):
		puzzle.step(1.0 / 60.0, game.robots)
		await physics_frame

func _walk(index: int, target: Vector3, max_frames: int) -> bool:
	var robot: CharacterBody3D = game.robots[index]
	for frame in range(max_frames):
		var offset := Vector2(target.x - robot.position.x, target.z - robot.position.z)
		if offset.length() < 0.18:
			robot.input_move = Vector2.ZERO
			await _advance(15)
			return true
		# Keep the magnet pointing down the corridor; strafe along the route as needed.
		robot.input_move = offset.limit_length(1.0) * minf(1.0, offset.length() * 1.7)
		robot.input_run = false
		await _advance(1)
	robot.input_move = Vector2.ZERO
	print("WALK_TIMEOUT index=", index, " position=", robot.position, " target=", target, " orb=", puzzle.orbs[clampi(puzzle.held, 0, 2)].position)
	return false

func _expect(condition: bool, label: String) -> void:
	print("PASS " if condition else "FAIL ", label)
	if not condition:
		failures.append(label)
