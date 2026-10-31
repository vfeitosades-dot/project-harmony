extends SceneTree

# Run three independent instances with --script res://tests/multiplayer_smoke.gd
# -- host / gravi / liga. See run_multiplayer_smoke.py for orchestration.
var game: Node
var role: String = "host"
var failures: int = 0
var started_ms: int = 0
var disconnected_seen: bool = false
var snapshots: int = 0

func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if not arguments.is_empty():
		role = arguments[0]
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_script(load("res://tests/multiplayer_actor.gd"))
	root.add_child(game)
	current_scene = game
	game.network.disconnected.connect(func(_reason: String) -> void: disconnected_seen = true)
	game.network.snapshot_received.connect(func(_state: Dictionary) -> void: snapshots += 1)
	if role == "host":
		game._host(24601)
	else:
		game._join("127.0.0.1", 24601)
	var deadline: int = Time.get_ticks_msec() + 10000
	while not game.playing and Time.get_ticks_msec() < deadline:
		if role == "host" and game.network.roster.size() == 3:
			game.network.start_game()
		await create_timer(0.05).timeout
	check(game.playing, "three-instance session started")
	if not game.playing:
		await finish()
		return
	started_ms = Time.get_ticks_msec()
	check(game.network.roster.size() == 3, "roster has host plus two clients")
	if role == "host":
		await host_scenario()
	elif role == "gravi":
		await gravi_scenario()
	else:
		await liga_scenario()
	await finish()

func host_scenario() -> void:
	game.robots[0].reset_at(Vector3(-4, 0.1, -6))
	game.robots[1].reset_at(Vector3(0, 0.1, -6))
	game.robots[2].reset_at(Vector3(-5, 0.1, -7))
	await at(1.2)
	check(game.robots[1].position.x > 2.0, "client movement simulated on server")
	check(game.puzzles.flags.release, "Liga client ability released first support")
	game.test_events.ability = true
	await at(1.5)
	check(game.puzzles.held == 0, "host magnet selected first sphere")
	var previous: Vector3 = game.puzzles.orbs[0].position
	game.test_move = Vector2(1, 0)
	await at(2.1)
	game.test_move = Vector2.ZERO
	check(game.puzzles.orbs[0].position.distance_to(previous) > 0.4, "magnetic force moved shared physics sphere")
	game.test_events.ability = true
	await at(3.0)
	# Seed an already transported object at its receiver: verify real puzzle detection.
	game.puzzles.orbs[0].position = game.puzzles.goals[0]
	game.puzzles.orbs[0].linear_velocity = Vector3.ZERO
	await at(3.5)
	check(game.puzzles.stage == 1 and game.puzzles.flags.one, "first puzzle set checkpoint one")
	check(game.lab._door_open[0], "first shared door opened")
	game.robots[0].reset_at(Vector3(-3, 0.1, -26))
	game.robots[1].reset_at(Vector3(-3, 0.1, -25))
	game.robots[2].reset_at(Vector3(5, 0.1, -42))
	await at(4.9)
	check(game.puzzles.flags.lift, "Gravi client field stabilized second core")
	check(game.puzzles.flags.bridge and game.puzzles.bridge.visible, "Liga client extended real bridge")
	game.puzzles.orbs[1].position = game.puzzles.goals[1]
	game.puzzles.orbs[1].linear_velocity = Vector3.ZERO
	await at(5.3)
	check(game.puzzles.stage == 2 and game.lab._door_open[1], "second checkpoint and door opened")
	game.robots[0].reset_at(Vector3(-6, 0.1, -74))
	game.robots[1].reset_at(Vector3(0, 0.1, -76))
	game.robots[2].reset_at(Vector3(6, 0.1, -72))
	game.puzzles.orbs[2].position = game.puzzles.goals[2]
	game.puzzles.orbs[2].linear_velocity = Vector3.ZERO
	await at(9.5)
	check(game.puzzles.flags.magnet, "final magnetic module locked")
	check(game.puzzles.flags.elastic, "client elastic tether maintained three seconds")
	await at(14.8)
	check(game.puzzles.flags.gravity, "client gravity field maintained three seconds")
	check(game.puzzles.flags.won and game.lab._door_open[2], "reactor and final door activated on server")
	game.robots[0].reset_at(Vector3(0, 0.1, -89))
	await at(15.4)
	check(game.won and game.puzzles.stage == 3, "exit triggered shared victory")
	await at(23.7)
	check(game.ui.screen == "victory", "host received eight-second victory screen")
	await at(24.8)
	check(game.playing and not game.won and game.puzzles.stage == 0 and not game.puzzles.flags.one and not game.lab._door_open[0] and game.network.round_id == 2, "client-requested replay reset server without dropping session")
	await at(26.2)
	check(game.network.roster.size() == 2, "client menu disconnect freed its slot")
	game.network.leave_game()
	await create_timer(0.5).timeout

func gravi_scenario() -> void:
	check(game.active_robot == 1, "first client assigned Gravi")
	await at(0.2)
	game.test_move = Vector2(1, 0)
	await at(1.0)
	game.test_move = Vector2.ZERO
	await at(1.3)
	var before: float = game.elapsed
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ESCAPE
	game._unhandled_input(key)
	check(game.paused and game.ui.screen == "pause", "client pause menu opened")
	await at(2.3)
	check(game.elapsed > before + 0.6, "client pause kept server time and snapshots running")
	game._resume()
	await at(3.8)
	check(game.puzzles.stage == 1 and game.puzzles.flags.one and game.lab._door_open[0], "client received first checkpoint and door state")
	await at(4.1)
	game.test_events.ability = true
	await at(5.7)
	check(game.puzzles.stage == 2 and game.puzzles.flags.lift and game.puzzles.flags.bridge, "client received second puzzle and checkpoint")
	await at(11.4)
	game.test_events.ability = true
	await at(15.8)
	check(game.won and game.puzzles.stage == 3 and game.puzzles.flags.won, "client received final reactor and shared victory")
	check(snapshots > 150, "client received continuous server snapshots")
	await at(23.8)
	check(game.ui.screen == "victory", "client received eight-second victory screen")
	await at(24.8)
	check(game.playing and not game.won and game.puzzles.stage == 0 and not game.puzzles.flags.won and game.network.round_id == 2, "Gravi received fresh replay round and cleared victory")
	await at(27.0)
	check(disconnected_seen and not game.playing and game.ui.screen == "menu", "host close returned client safely to menu")

func liga_scenario() -> void:
	check(game.active_robot == 2, "second client assigned Liga")
	await at(0.5)
	game.test_events.ability = true
	await at(2.7)
	check(game.puzzles.flags.release, "client received its authoritative ability result")
	await at(4.1)
	game.test_events.ability = true # Release the first-room tether.
	await at(4.5)
	game.test_events.ability = true # Connect the room-two bridge anchor.
	# Teleporting out of range already releases the room-two tether.
	await at(6.0)
	game.test_events.ability = true
	await at(15.8)
	check(game.won and game.puzzles.flags.elastic and game.puzzles.flags.gravity, "Liga client received all final module states")
	await at(23.8)
	check(game.ui.screen == "victory", "Liga client received victory screen")
	await at(24.1)
	game._restart()
	await at(24.8)
	check(game.playing and not game.won and game.puzzles.stage == 0 and not game.puzzles.flags.release and game.network.round_id == 2, "Liga replay button requested and received a fresh shared round")
	await at(25.3)
	game._menu()
	check(not game.network.online and game.ui.screen == "menu", "client can leave session through menu")
	await create_timer(0.4).timeout

func at(seconds: float) -> void:
	var remaining: float = seconds - float(Time.get_ticks_msec() - started_ms) / 1000.0
	if remaining > 0:
		await create_timer(remaining).timeout
	else:
		await process_frame

func check(condition: bool, description: String) -> void:
	print("%s %s %s" % ["PASS" if condition else "FAIL", role, description])
	if not condition:
		failures += 1

func finish() -> void:
	print("RESULT %s failures=%d snapshots=%d" % [role, failures, snapshots])
	if is_instance_valid(game):
		game.network.leave_game()
		game.queue_free()
		game = null
		current_scene = null
		await create_timer(0.25).timeout
		await process_frame
		await process_frame
	quit(1 if failures > 0 else 0)
