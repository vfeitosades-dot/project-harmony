extends Node3D

const Lab = preload("res://scripts/lab_world.gd")
const Robot = preload("res://scripts/robot.gd")
const Puzzles = preload("res://scripts/puzzles.gd")
const Interface = preload("res://scripts/interface.gd")
const Network = preload("res://scripts/network.gd")
const NAMES: Array[String] = ["BIPO", "GRAVI", "LIGA"]
var lab: Node3D
var puzzles: Node3D
var ui: CanvasLayer
var network: Node
var robots: Array = []
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var active_robot: int = 0
var playing: bool = false
var paused: bool = false
var won: bool = false
var elapsed: float = 0.0
var yaw: float = 0.0
var pitch: float = -0.23
var sensitivity: float = 0.6
var pending: Dictionary = {"jump": false, "ability": false, "interact": false, "regroup": false, "switch": -1}
var commands: Dictionary = {}
var command_clock: float = 0.0
var snapshot_clock: float = 0.0
var hud_clock: float = 0.0
var remote_states: Array = []
var sound_streams: Dictionary = {}
var ambience: AudioStreamPlayer
var step_clock: float = 0.0
var last_grounded: bool = true
var intro_clock: float = 0.0

func _ready() -> void:
	process_physics_priority = -10
	lab = Lab.new()
	lab.name = "LaboratorioZero"
	add_child(lab)
	lab.build()
	for i in range(3):
		var robot: CharacterBody3D = Robot.new()
		robot.name = "Robot%d" % i
		add_child(robot)
		robot.setup(i)
		robot.collision_layer = 2
		robot.collision_mask = 1 | 2
		robots.append(robot)
	pivot = Node3D.new()
	pivot.name = "CameraOrbit"
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 5.5
	arm.margin = 0.2
	arm.collision_mask = 1
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	arm.shape = shape
	pivot.add_child(arm)
	for robot in robots:
		arm.add_excluded_object(robot.get_rid())
	camera = Camera3D.new()
	camera.fov = 70
	camera.far = 130
	camera.current = true
	arm.add_child(camera)
	network = Network.new()
	network.name = "Network"
	add_child(network)
	network.command_received.connect(_receive_command)
	network.snapshot_received.connect(_receive_snapshot)
	network.roster_changed.connect(_roster_changed)
	network.session_started.connect(_start_session)
	network.status_changed.connect(_network_status)
	network.disconnected.connect(_disconnected)
	network.restart_requested.connect(func(_peer_id: int) -> void:
		if won and network.is_host:
			network.restart_game()
	)
	ui = Interface.new()
	ui.name = "Interface"
	add_child(ui)
	ui.solo_requested.connect(_solo)
	ui.host_requested.connect(_host)
	ui.join_requested.connect(_join)
	ui.start_requested.connect(func() -> void: network.start_game())
	ui.resume_requested.connect(_resume)
	ui.menu_requested.connect(_menu)
	ui.restart_requested.connect(_restart)
	ui.regroup_requested.connect(_regroup_requested)
	ui.settings_changed.connect(_settings_changed)
	_load_audio()
	_load_settings()
	_reset_level()
	pivot.position = Vector3(0, 1, -1)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# These flags are for the supplied repeatable local test harness only.
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--solo"):
		_solo.call_deferred()
	elif args.has("--host-test"):
		_host.call_deferred(24601)
	elif args.has("--join-test"):
		_join.call_deferred("127.0.0.1", 24601)

func _reset_level() -> void:
	if is_instance_valid(puzzles):
		remove_child(puzzles)
		puzzles.queue_free()
	for i in range(3):
		lab.set_door_open(i, false)
		robots[i].reset_at(Vector3((i - 1) * 2, 0.15, 0))
		robots[i].celebrate = false
		robots[i].simulate = true
		robots[i].view_yaw = 0
	lab.set_reactor_active(false)
	puzzles = Puzzles.new()
	puzzles.name = "Puzzles"
	add_child(puzzles)
	puzzles.build(lab)
	puzzles.message.connect(_message)
	puzzles.checkpoint_reached.connect(_checkpoint)
	puzzles.victory_reached.connect(_victory)
	puzzles.sound_requested.connect(_play_sound)
	puzzles.set_authority(not network.online or network.is_host)
	commands.clear()
	remote_states.clear()
	_clear_pending()
	elapsed = 0
	won = false
	active_robot = network.local_robot if network.online else 0
	yaw = 0
	pitch = -0.23

func _solo() -> void:
	network.leave_game()
	_reset_level()
	_start_session()

func _host(port: int) -> void:
	_play_sound("click")
	var error: Error = network.host_game(port)
	if error == OK:
		_reset_level()
		ui.show_lobby(true, network.roster.size(), "UDP %d • Compartilhe o IP local deste computador." % port)
		ui.set_status("IPs locais: %s" % _local_addresses())

func _join(address: String, port: int) -> void:
	_play_sound("click")
	var error: Error = network.join_game(address, port)
	if error == OK:
		_reset_level()
		ui.show_lobby(false, 1, "Conectando a %s:%d…" % [address, port])

func _start_session() -> void:
	_reset_level()
	playing = true
	paused = false
	won = false
	elapsed = 0
	active_robot = network.local_robot if network.online else 0
	puzzles.set_authority(not network.online or network.is_host)
	ui.show_hud()
	ui.set_online(network.online)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	intro_clock = 1.0
	_play_sound("success")
	pivot.position = robots[active_robot].position + Vector3(0, 1.2, 0)

func _menu() -> void:
	_play_sound("click")
	playing = false
	paused = false
	network.leave_game()
	_reset_level()
	ui.show_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	paused = false
	ui.show_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_clear_pending()

func _restart() -> void:
	if network.online:
		if won:
			network.restart_game()
		return
	_solo()

func _regroup_requested() -> void:
	pending.regroup = true
	_resume()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if playing and not won:
			if ui.screen == "hud":
				paused = true
				_clear_pending()
				ui.show_pause()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			elif ui.screen == "pause":
				_resume()
		return
	if not playing or paused or won or ui.screen != "hud":
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw = wrapf(yaw - event.relative.x * sensitivity * 0.004, -PI, PI)
		pitch = clampf(pitch - event.relative.y * sensitivity * 0.004, -1.05, 0.3)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pending.ability = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(2.3, arm.spring_length - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(8, arm.spring_length + 0.4)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				pending.jump = true
			KEY_E:
				pending.interact = true
			KEY_R:
				pending.regroup = true
			KEY_TAB:
				var desired: int = (active_robot + 1) % 3
				if network.online:
					for offset in range(1, 4):
						var candidate: int = (active_robot + offset) % 3
						if not network.roster.values().has(candidate):
							desired = candidate
							break
				pending.switch = desired
			KEY_1, KEY_2, KEY_3:
				pending.switch = int(event.keycode - KEY_1)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(puzzles):
		return
	var server: bool = not network.online or network.is_host
	var freeze_solo: bool = paused and not network.online
	for i in range(3):
		robots[i].simulate = server and not freeze_solo
		robots[i].face_camera = not playing
		if server:
			var locked: bool = bool(puzzles.flags[["one", "two", "magnet"][i]]) or (i == 0 and not puzzles.flags.release)
			puzzles.orbs[i].freeze = locked or freeze_solo
		robots[i].controlled = playing and i == active_robot
		if not playing or freeze_solo:
			robots[i].input_move = Vector2.ZERO
	if not playing:
		return
	if not won and not freeze_solo:
		elapsed += delta
	command_clock += delta
	if command_clock >= 1.0 / 30.0:
		command_clock = 0
		var command: Dictionary = _read_command()
		if network.online:
			network.send_command(command)
		else:
			_receive_command(1, command)
		_clear_pending()
	if server:
		for i in range(3):
			robots[i].input_move = Vector2.ZERO
		for peer in commands:
			var entry: Dictionary = commands[peer]
			if Time.get_ticks_msec() - int(entry.get("time", 0)) > 400:
				continue
			var index: int = int(network.roster.get(peer, active_robot)) if network.online else active_robot
			var command: Dictionary = entry.command
			robots[index].input_move = Vector2(float(command.x), float(command.y))
			robots[index].input_run = bool(command.run)
			robots[index].view_yaw = float(command.yaw)
		if not freeze_solo:
			puzzles.step(delta, robots)
			for i in range(3):
				if robots[i].position.y < -6.5:
					_respawn(i)
		snapshot_clock += delta
		if network.online and snapshot_clock >= 1.0 / 15.0:
			snapshot_clock = 0
			network.send_snapshot(_snapshot())
	else:
		puzzles.step(delta, robots)
		for i in range(mini(remote_states.size(), 3)):
			var state: Dictionary = remote_states[i]
			var target: Vector3 = state.position
			robots[i].position = robots[i].position.lerp(target, 1 - exp(-delta * 22)) if robots[i].position.distance_to(target) < 5 else target
			robots[i].remote_velocity = state.velocity
			robots[i].view_yaw = float(state.yaw)
			robots[i].using_ability = bool(state.ability)
			robots[i].low_gravity = bool(state.low)

func _process(delta: float) -> void:
	if robots.is_empty() or not is_instance_valid(ui):
		return
	if playing:
		camera.fov = lerpf(camera.fov, 70.0, minf(1, delta * 6))
		var target: Vector3 = robots[active_robot].position + Vector3(0, 1.15, 0)
		pivot.position = pivot.position.lerp(target, 1 - exp(-delta * 12))
		pivot.rotation = Vector3(pitch, yaw, 0)
		camera.h_offset = 0.35
	else:
		pivot.position = pivot.position.lerp(Vector3(-0.7, 1.0, -1.4), 1 - exp(-delta * 3))
		pivot.rotation = Vector3(-0.18, -0.3 + sin(Time.get_ticks_msec() * 0.00015) * 0.1, 0)
		arm.spring_length = 6.8
		camera.h_offset = -1.5
		camera.fov = lerpf(camera.fov, 84.0, minf(1, delta * 6))
	if playing and ui.screen == "hud":
		hud_clock += delta
		if hud_clock > 0.08:
			hud_clock = 0
			ui.update_hud(active_robot, puzzles.stage, puzzles.objective(), puzzles.prompt(robots[active_robot]), puzzles.recharge if active_robot == 1 else 0.0, puzzles.progress_text(), network.roster.size() if network.online else 1)
		if intro_clock > 0:
			intro_clock -= delta
			if intro_clock <= 0:
				_message("EXPERIMENTO 03 — Fuja do laboratório! TAB troca de robô; clique usa a habilidade.")
		var velocity: Vector3 = robots[active_robot].velocity if not network.online or network.is_host else robots[active_robot].remote_velocity
		var grounded: bool = robots[active_robot].is_on_floor()
		step_clock -= delta
		if Vector2(velocity.x, velocity.z).length() > 1 and grounded and step_clock <= 0:
			_play_sound("step", -17)
			step_clock = 0.28
		if grounded and not last_grounded:
			_play_sound("land", -12)
		last_grounded = grounded

func _read_command() -> Dictionary:
	var allow: bool = playing and not paused and not won and ui.screen == "hud"
	var command: Dictionary = {"x": 0.0, "y": 0.0, "yaw": yaw, "pitch": pitch, "jump": false, "run": false, "ability": false, "interact": false, "regroup": false, "switch": -1}
	if allow:
		command.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		command.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		command.run = Input.is_physical_key_pressed(KEY_SHIFT)
		for key in pending:
			command[key] = pending[key]
	return command

func _receive_command(peer_id: int, command: Dictionary) -> void:
	if not playing or won or (network.online and not network.is_host):
		return
	if network.online and not network.roster.has(peer_id):
		return
	var index: int = int(network.roster[peer_id]) if network.online else active_robot
	if int(command.get("switch", -1)) >= 0:
		robots[index].input_move = Vector2.ZERO
		if network.online:
			index = network.try_switch(peer_id, int(command.switch))
		else:
			index = int(command.switch)
			active_robot = index
			_play_sound("click")
	commands[peer_id] = {"command": command, "time": Time.get_ticks_msec()}
	var robot: CharacterBody3D = robots[index]
	robot.view_yaw = float(command.get("yaw", 0))
	if command.get("jump", false):
		robot.input_jump = true
		_play_sound("jump", -8)
	if command.get("ability", false):
		var direction := Vector3(0, 0, -1).rotated(Vector3.UP, robot.view_yaw)
		puzzles.use_ability(index, robot, robot.position + direction * 6)
	if command.get("interact", false):
		puzzles.interact(robot)
	if command.get("regroup", false):
		if not network.online:
			for i in range(3):
				_respawn(i)
		else:
			_respawn(index)
		puzzles.reset_unsolved()
		_message("Checkpoint restaurado. Os dispositivos concluídos continuam ativos.")

func _snapshot() -> Dictionary:
	var states: Array = []
	for robot in robots:
		states.append({"position": robot.position, "velocity": robot.velocity, "yaw": robot.view_yaw, "ability": robot.using_ability, "low": robot.low_gravity})
	return {"robots": states, "puzzle": puzzles.state(), "time": elapsed}

func _receive_snapshot(state: Dictionary) -> void:
	remote_states = state.get("robots", [])
	if not state.has("puzzle"):
		return
	elapsed = float(state.get("time", elapsed))
	puzzles.apply_state(state.puzzle)

func _roster_changed(roster: Dictionary) -> void:
	for peer in commands.keys():
		if not roster.has(peer):
			commands.erase(peer)
	if network.online:
		active_robot = network.local_robot
	for i in range(3):
		var occupied: bool = roster.values().has(i)
		robots[i].set_badge(NAMES[i] + (" • VOCÊ" if i == active_robot else (" • AMIGO" if occupied else "")))
	if is_instance_valid(ui) and not playing and network.online:
		ui.show_lobby(network.is_host, roster.size(), "O host pode iniciar. TAB alterna entre os robôs livres.")

func _network_status(text: String) -> void:
	if is_instance_valid(ui):
		ui.set_status(text)

func _disconnected(reason: String) -> void:
	_menu()
	ui.set_status(reason)

func _respawn(index: int) -> void:
	var z: float = [0.0, -25.0, -57.0, -83.0][clampi(puzzles.stage, 0, 3)]
	robots[index].reset_at(Vector3((index - 1) * 1.5, 0.2, z))

func _checkpoint(_stage: int) -> void:
	_play_sound("door")
	for robot in robots:
		robot.celebrate = true
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		for robot in robots:
			robot.celebrate = false
	)

func _victory() -> void:
	if won:
		return
	won = true
	paused = false
	commands.clear()
	_clear_pending()
	for robot in robots:
		robot.input_move = Vector2.ZERO
		robot.celebrate = true
	_message("EXPERIMENTO CONCLUÍDO... OU QUASE.")
	_play_sound("success")
	get_tree().create_timer(8).timeout.connect(func() -> void:
		if won and playing:
			ui.show_victory(elapsed)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)

func _message(text: String) -> void:
	if is_instance_valid(ui):
		ui.toast(text)

func _clear_pending() -> void:
	for key in ["jump", "ability", "interact", "regroup"]:
		pending[key] = false
	pending.switch = -1

func _settings_changed(settings: Dictionary) -> void:
	sensitivity = float(settings.get("sensitivity", 0.6))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
	if not settings.get("fullscreen", false):
		DisplayServer.window_set_size(settings.get("resolution", Vector2i(1280, 720)))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.get("vsync", true) else DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if settings.get("low_graphics", false) else Viewport.MSAA_2X
	for child in lab.get_children():
		if child is Light3D:
			child.shadow_enabled = not settings.get("low_graphics", false) and child is DirectionalLight3D
	var volume: float = float(settings.get("volume", 0.65))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, volume)))
	AudioServer.set_bus_mute(0, volume < 0.001)
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", str(key), settings[key])
	config.save("user://preferences.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://preferences.cfg") == OK:
		for key in ui.settings:
			ui.settings[key] = config.get_value("settings", key, ui.settings[key])
	_settings_changed(ui.settings)

func _load_audio() -> void:
	for cue in ["click", "step", "jump", "land", "magnet", "gravity", "elastic", "door", "success", "reactor"]:
		var path: String = "res://audio/%s.wav" % cue
		if ResourceLoader.exists(path):
			sound_streams[cue] = load(path)
	if ResourceLoader.exists("res://audio/ambience.wav"):
		ambience = AudioStreamPlayer.new()
		var stream: AudioStreamWAV = load("res://audio/ambience.wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
		ambience.stream = stream
		ambience.volume_db = -24
		add_child(ambience)
		ambience.play()

func _play_sound(cue: String, volume: float = -4.0) -> void:
	var name: String = "success" if cue == "puzzle" else cue
	if not sound_streams.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sound_streams[name]
	player.volume_db = volume
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _local_addresses() -> String:
	var addresses: PackedStringArray = []
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127."):
			addresses.append(address)
	return ", ".join(addresses) if not addresses.is_empty() else "consulte as configurações de rede do Windows"
