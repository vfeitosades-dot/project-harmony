extends Node3D
class_name TrioPuzzles

signal message(text: String)
signal checkpoint_reached(stage: int)
signal victory_reached()
signal sound_requested(cue: String)

const CYAN := Color("42e3d2")
const YELLOW := Color("ffd166")
const CORAL := Color("ff6b82")
const VIOLET := Color("a58bff")
var stage: int = 0
var flags: Dictionary = {"release": false, "one": false, "lift": false, "bridge": false, "two": false, "magnet": false, "gravity": false, "elastic": false, "won": false}
var lab: Node3D
var authority: bool = true
var orbs: Array[RigidBody3D] = []
var sockets: Array[Node3D] = []
var anchors: Array[Node3D] = []
var homes: Array[Vector3] = [Vector3(-4, 1.0, -10), Vector3(-3, 1.0, -29), Vector3(-6, 1.0, -65)]
var goals: Array[Vector3] = [Vector3(3, 0.8, -15), Vector3(-4, 0.8, -47), Vector3(-6, 0.8, -77)]
var anchor_pos: Array[Vector3] = [Vector3(-5, 2, -12), Vector3(5, 3, -44), Vector3(6, 2, -77)]
var reset_pos: Array[Vector3] = [Vector3(5.5, 0, -6), Vector3(6, 0, -28), Vector3(8, 0, -62)]
var gravity_terminal := Vector3(0, 1.4, -80)
var held: int = -1
var tether: int = -1
var field_time: float = 0.0
var recharge: float = 0.0
var field_center := Vector3.ZERO
var gravity_charge: float = 0.0
var elastic_charge: float = 0.0
var field_mesh: MeshInstance3D
var gravity_core: MeshInstance3D
var beam: MeshInstance3D
var rope: MeshInstance3D
var bridge: StaticBody3D
var markers: Array[Node3D] = []
var game_time: float = 0.0

func build(world: Node3D) -> void:
	lab = world
	for i in range(3):
		var body := RigidBody3D.new()
		body.name = "Nucleo%d" % i
		body.position = homes[i]
		body.mass = 2.0
		body.linear_damp = 3.5
		body.angular_damp = 4.0
		body.collision_layer = 4
		body.collision_mask = 1 | 4
		body.continuous_cd = true
		add_child(body)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.55
		collision.shape = shape
		body.add_child(collision)
		var orb := _sphere(body, Vector3.ZERO, 0.55, _material(Color("667b95"), false, 0.75))
		for axis in range(3):
			var ring := _ring(orb, Vector3.ZERO, 0.57, CYAN if i != 2 else YELLOW)
			ring.rotation[axis] = PI / 2.0
		_sphere(body, Vector3.ZERO, 0.22, _material(CYAN, true))
		orbs.append(body)
		var socket := Node3D.new()
		add_child(socket)
		socket.position = goals[i] - Vector3(0, 0.6, 0)
		_ring(socket, Vector3.ZERO, 0.95, CYAN if i != 2 else YELLOW)
		_box(socket, Vector3(0, -0.12, 0), Vector3(2, 0.25, 2), _material(Color("2e4056")))
		_label(socket, Vector3(0, 1.9, 0), ["01 / ENCAIXE MAGNÉTICO", "02 / TERMINAL DE ENERGIA", "03 / MÓDULO MAGNÉTICO"][i], CYAN)
		sockets.append(socket)
		var anchor := Node3D.new()
		anchor.position = anchor_pos[i]
		add_child(anchor)
		_box(anchor, Vector3(0, -0.18, 0), Vector3(0.8, 0.8, 0.55), _material(Color("2e4056")))
		_ring(anchor, Vector3.ZERO, 0.6, CORAL).rotation.x = PI / 2.0
		_sphere(anchor, Vector3.ZERO, 0.25, _material(CORAL, true))
		_label(anchor, Vector3(0, 1.05, 0), ["LIGA / LIBERAR SUPORTE", "LIGA / ESTENDER PONTE", "LIGA / TENSIONAR REATOR"][i], CORAL)
		anchors.append(anchor)
		var reset := Node3D.new()
		add_child(reset)
		reset.position = reset_pos[i]
		_box(reset, Vector3(0, 0.6, 0), Vector3(0.65, 1.2, 0.65), _material(Color("2e4056")))
		_box(reset, Vector3(0, 1.25, 0), Vector3(0.8, 0.12, 0.8), _material(YELLOW, true))
		_label(reset, Vector3(0, 2, 0), "[E] RESTAURAR NÚCLEO", YELLOW)
		markers.append(reset)
		# Decorative cradle: the first sphere unlocks with Liga.
		for dx in [-0.75, 0.75]:
			_box(self, homes[i] + Vector3(dx, -0.45, 0), Vector3(0.18, 1, 1.3), _material(Color("2e4056")))
	orbs[0].freeze = true
	bridge = StaticBody3D.new()
	bridge.name = "PonteRecuperavel"
	add_child(bridge)
	bridge.position = Vector3(0, -0.22, -38)
	_box(bridge, Vector3.ZERO, Vector3(5, 0.4, 6.2), _material(Color("405775")))
	var bridge_collision := CollisionShape3D.new()
	var bridge_shape := BoxShape3D.new()
	bridge_shape.size = Vector3(5, 0.4, 6.2)
	bridge_collision.shape = bridge_shape
	bridge.add_child(bridge_collision)
	bridge.visible = false
	bridge.collision_layer = 0
	for dx in [-2.3, 2.3]:
		_box(bridge, Vector3(dx, 0.25, 0), Vector3(0.08, 0.08, 6), _material(CORAL, true))
	field_mesh = _sphere(self, Vector3.ZERO, 3.0, _material(Color(0.26, 0.89, 0.82, 0.10), true))
	field_mesh.visible = false
	gravity_core = _sphere(self, gravity_terminal, 0.55, _material(VIOLET, true))
	_ring(self, Vector3(0, 0.15, -80), 1.3, CYAN)
	_label(self, Vector3(0, 3.2, -80), "GRAVI / SUSTENTAR NÚCLEO 3s", CYAN)
	beam = _cable(YELLOW)
	rope = _cable(CORAL)
	_label(self, Vector3(0, 3, -4), "EXPERIMENTO 03 — SISTEMA REINICIADO", CYAN)
	_label(self, Vector3(0, 2.6, -25), "GRAVIDADE QUEBRADA / NADA SE PERDE", VIOLET)
	_label(self, Vector3(0, 3, -58), "TRÊS MÓDULOS. UMA SAÍDA.", YELLOW)

func set_authority(value: bool) -> void:
	authority = value
	if not value:
		for body in orbs:
			body.freeze = true

func step(delta: float, robots: Array) -> void:
	game_time += delta
	field_mesh.visible = field_time > 0
	field_mesh.position = field_center
	field_mesh.rotation.y += delta * 0.25
	gravity_core.position.y = 1.4 + sin(game_time * 1.5) * 0.08 + minf(gravity_charge, 3) * 0.45
	if not authority:
		_update_lines(robots)
		return
	field_time = maxf(0, field_time - delta)
	recharge = maxf(0, recharge - delta)
	for robot in robots:
		robot.low_gravity = field_time > 0 and robot.global_position.distance_to(field_center) < 3.6
		robot.using_ability = (robot.robot_index == 0 and held >= 0) or (robot.robot_index == 1 and field_time > 0) or (robot.robot_index == 2 and tether >= 0)
	for i in range(orbs.size()):
		var body: RigidBody3D = orbs[i]
		if body.position.y < -8 or absf(body.position.x) > 18 or body.position.z > 8 or body.position.z < -96:
			_restore_orb(i)
		var light: bool = field_time > 0 and body.position.distance_to(field_center) < 3.6
		body.gravity_scale = -0.16 if light else 1.0
		if light and i == 1 and not flags.lift:
			flags.lift = true
			message.emit("Núcleo estabilizado! Liga pode estender a ponte do outro lado.")
		body.linear_velocity = body.linear_velocity.limit_length(9)
		body.angular_velocity = body.angular_velocity.limit_length(6)
	if held >= 0:
		var bipo: CharacterBody3D = robots[0]
		var object: RigidBody3D = orbs[held]
		var target: Vector3 = bipo.position + Vector3(0, 1.15, -2.1).rotated(Vector3.UP, bipo.view_yaw)
		if object.position.distance_to(bipo.position) > 8.5:
			held = -1
		else:
			var force: Vector3 = ((target - object.position) * 25 - object.linear_velocity * 8 + Vector3.UP * object.mass * 18.0 * object.gravity_scale).limit_length(90)
			object.apply_central_force(force)
	if tether >= 0:
		var liga: CharacterBody3D = robots[2]
		var vector: Vector3 = anchor_pos[tether] - liga.position - Vector3(0, 0.8, 0)
		if vector.length() > 11:
			tether = -1
		elif tether == 1 and vector.length() > 1.8:
			liga.velocity += vector.normalized() * minf(vector.length() * 2.5, 18) * delta
			liga.velocity = liga.velocity.limit_length(10)
		elif tether == 2:
			elastic_charge = minf(3, elastic_charge + delta)
			if elastic_charge >= 3 and not flags.elastic:
				flags.elastic = true
				message.emit("Módulo elástico travado. Boa, Liga!")
				sound_requested.emit("puzzle")
	if field_time > 0 and field_center.distance_to(gravity_terminal) < 3.5:
		gravity_charge = minf(3, gravity_charge + delta)
		if gravity_charge >= 3 and not flags.gravity:
			flags.gravity = true
			message.emit("Módulo gravitacional travado. Boa, Gravi!")
			sound_requested.emit("puzzle")
	for i in range(3):
		var unlocked: bool = bool(flags.release) if i == 0 else (bool(flags.lift) and bool(flags.bridge) if i == 1 else true)
		var key: String = ["one", "two", "magnet"][i]
		if not flags[key] and unlocked:
			var horizontal := Vector2(orbs[i].position.x - goals[i].x, orbs[i].position.z - goals[i].z).length()
			if horizontal < 1.3 and absf(orbs[i].position.y - goals[i].y) < 2:
				_lock_orb(i)
	if flags.magnet and flags.gravity and flags.elastic and not flags.won:
		flags.won = true
		lab.set_door_open(2, true)
		lab.set_reactor_active(true)
		message.emit("REATOR ESTÁVEL! Atravessem a porta de saída.")
		sound_requested.emit("reactor")
	if flags.won:
		for robot in robots:
			if robot.position.z < -87.5 and stage < 3:
				stage = 3
				victory_reached.emit()
	_update_lines(robots)

func use_ability(index: int, robot: CharacterBody3D, aim: Vector3) -> void:
	if not authority:
		return
	if index == 0:
		if held >= 0:
			held = -1
			message.emit("Magnetismo desligado.")
			return
		var candidate: int = -1
		var best: float = 7.0
		for i in range(orbs.size()):
			if flags[["one", "two", "magnet"][i]]:
				continue
			var distance: float = robot.position.distance_to(orbs[i].position)
			if distance < best:
				candidate = i
				best = distance
		if candidate < 0:
			message.emit("Bipo: aproxime-se de um núcleo metálico (alcance 7 m).")
		elif candidate == 0 and not flags.release:
			message.emit("O suporte está preso. Liga precisa puxar a âncora rosa primeiro.")
		else:
			held = candidate
			orbs[held].freeze = false
			orbs[held].sleeping = false
			message.emit("Núcleo conectado! Leve-o até o encaixe luminoso. Clique para soltar.")
			sound_requested.emit("magnet")
	elif index == 1:
		if recharge > 0:
			message.emit("Campo recarregando: %.1f s" % recharge)
			return
		var direction := Vector3(0, 0, -1).rotated(Vector3.UP, robot.view_yaw)
		field_center = robot.position + direction * 4 + Vector3(0, 1, 0)
		var candidates: Array[Vector3] = [orbs[0].position, orbs[1].position, orbs[2].position, gravity_terminal]
		var score: float = 1000
		for point in candidates:
			var diff: Vector3 = point - robot.position
			var facing: float = direction.dot(Vector3(diff.x, 0, diff.z).normalized())
			if diff.length() <= 8.2 and facing > 0.1:
				var candidate_score: float = point.distance_to(aim) * 0.15 + diff.length() - facing * 4
				if candidate_score < score:
					score = candidate_score
					field_center = point
		field_time = 5.0
		recharge = 7.0
		sound_requested.emit("gravity")
		message.emit("Campo ativo por 5 s. Núcleos flutuam e os saltos ficam mais altos.")
	else:
		if tether >= 0:
			tether = -1
			return
		var target: int = -1
		var best: float = 10.01
		for i in range(3):
			var distance: float = robot.position.distance_to(anchor_pos[i])
			if distance < best:
				best = distance
				target = i
		if target < 0:
			message.emit("Liga: aproxime-se de uma âncora rosa (alcance 10 m).")
			return
		tether = target
		sound_requested.emit("elastic")
		if target == 0:
			flags.release = true
			orbs[0].freeze = false
			message.emit("Suporte liberado! Bipo pode transportar o núcleo.")
		elif target == 1:
			flags.bridge = true
			bridge.visible = true
			bridge.collision_layer = 1
			message.emit("Ponte estendida! Leve o núcleo estabilizado ao terminal.")
		else:
			message.emit("Mantenha o cabo conectado por 3 segundos para travar o módulo.")

func interact(robot: CharacterBody3D) -> void:
	for i in range(3):
		if robot.position.distance_to(reset_pos[i]) < 2.8:
			if not flags[["one", "two", "magnet"][i]]:
				_restore_orb(i)
				message.emit("Núcleo restaurado ao suporte. O progresso foi preservado.")
			else:
				message.emit("Este núcleo já está no encaixe.")
			return
	message.emit("TAB troca de robô livre. R reúne os robôs no checkpoint.")

func objective() -> String:
	if stage == 0:
		return "Liga: libere a âncora rosa. Bipo: leve a esfera ao encaixe." if not flags.release else "Bipo: atraia a esfera e leve-a ao encaixe ciano."
	if stage == 1:
		if not flags.lift:
			return "Gravi: aplique o campo no núcleo próximo à entrada."
		if not flags.bridge:
			return "Liga: conecte a âncora rosa do outro lado do vão."
		return "Bipo: transporte o núcleo pela ponte até o terminal."
	if flags.won:
		return "Tudo estável! Atravesse a saída ao fundo da sala."
	return "Ative os módulos: magnético, gravitacional e elástico."

func progress_text() -> String:
	if stage == 0:
		return "ÂNCORA %s  •  NÚCLEO %s" % [_check(flags.release), _check(flags.one)]
	if stage == 1:
		return "CAMPO %s  •  PONTE %s  •  NÚCLEO %s" % [_check(flags.lift), _check(flags.bridge), _check(flags.two)]
	return "MAG %s  •  GRAV %s  •  LIGA %s" % [_check(flags.magnet), _check(flags.gravity), _check(flags.elastic)]

func prompt(robot: CharacterBody3D) -> String:
	for i in range(3):
		if robot.position.distance_to(reset_pos[i]) < 2.8:
			return "[E] Restaurar núcleo desta sala"
	if robot.robot_index == 0:
		if held >= 0:
			return "MAGNETISMO ATIVO  •  Mire com o mouse para orientar o núcleo"
		for orb in orbs:
			if robot.position.distance_to(orb.position) < 7:
				return "[CLIQUE] Atrair núcleo metálico"
	if robot.robot_index == 1:
		return "[CLIQUE] Campo de gravidade  •  5 s de duração" if recharge <= 0 else "RECARGA %.1f s" % recharge
	if robot.robot_index == 2:
		for point in anchor_pos:
			if robot.position.distance_to(point) < 10:
				return "[CLIQUE] Conectar âncora rosa  •  Clique de novo para soltar"
	return "TAB / outro robô    •    R / checkpoint"

func reset_unsolved() -> void:
	held = -1
	tether = -1
	for i in range(3):
		if not flags[["one", "two", "magnet"][i]]:
			_restore_orb(i)

func state() -> Dictionary:
	var positions: Array = []
	for orb in orbs:
		positions.append(orb.position)
	return {"stage": stage, "flags": flags.duplicate(), "orbs": positions, "held": held, "tether": tether, "field": field_time, "center": field_center, "recharge": recharge, "gc": gravity_charge, "ec": elastic_charge}

func apply_state(data: Dictionary) -> void:
	var old_stage: int = stage
	stage = int(data.get("stage", 0))
	flags = data.get("flags", flags)
	var positions: Array = data.get("orbs", [])
	for i in range(mini(positions.size(), 3)):
		orbs[i].position = positions[i]
	held = int(data.get("held", -1))
	tether = int(data.get("tether", -1))
	field_time = float(data.get("field", 0))
	field_center = data.get("center", Vector3.ZERO)
	recharge = float(data.get("recharge", 0))
	gravity_charge = float(data.get("gc", 0))
	elastic_charge = float(data.get("ec", 0))
	lab.set_door_open(0, bool(flags.one))
	lab.set_door_open(1, bool(flags.two))
	lab.set_door_open(2, bool(flags.won))
	lab.set_reactor_active(bool(flags.won))
	bridge.visible = bool(flags.bridge)
	bridge.collision_layer = 1 if flags.bridge else 0
	if stage == 3 and old_stage != 3:
		victory_reached.emit()

func _restore_orb(index: int) -> void:
	var body: RigidBody3D = orbs[index]
	if held == index:
		held = -1
	body.freeze = index == 0 and not flags.release
	body.position = homes[index]
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.sleeping = false

func _lock_orb(index: int) -> void:
	var key: String = ["one", "two", "magnet"][index]
	flags[key] = true
	orbs[index].freeze = true
	orbs[index].position = goals[index]
	if held == index:
		held = -1
	sound_requested.emit("puzzle")
	if index < 2:
		stage = index + 1
		lab.set_door_open(index, true)
		checkpoint_reached.emit(stage)
		message.emit("DESAFIO CONCLUÍDO! Porta aberta. Checkpoint salvo. R reúne a equipe.")
	else:
		message.emit("Módulo magnético travado. Boa, Bipo!")

func _update_lines(robots: Array) -> void:
	beam.visible = held >= 0
	if held >= 0:
		_connect_line(beam, robots[0].position + Vector3(0, 0.8, 0), orbs[held].position)
	rope.visible = tether >= 0
	if tether >= 0:
		_connect_line(rope, robots[2].position + Vector3(0, 0.85, 0), anchor_pos[tether])

func _check(value: bool) -> String:
	return "✓" if value else "○"

func _material(color: Color, glow: bool = false, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.35 if metallic > 0 else 0.6
	if glow:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b)
		mat.emission_energy_multiplier = 1.5
	if color.a < 1:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 20
	mesh.rings = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

func _ring(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.045
	mesh.outer_radius = radius + 0.045
	mesh.rings = 24
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color, true)
	parent.add_child(node)
	node.position = pos
	return node

func _label(parent: Node3D, pos: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 32
	label.pixel_size = 0.007
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	parent.add_child(label)
	label.position = pos

func _cable(color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.035
	mesh.height = 1
	mesh.radial_segments = 8
	var line := MeshInstance3D.new()
	line.mesh = mesh
	line.material_override = _material(color, true)
	add_child(line)
	line.visible = false
	return line

func _connect_line(line: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var direction: Vector3 = end - start
	line.position = (start + end) * 0.5
	line.scale.y = maxf(0.01, direction.length())
	if direction.length() > 0.01:
		line.quaternion = Quaternion(Vector3.UP, direction.normalized())
