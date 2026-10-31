extends Node3D
class_name TrioLab

## Original procedural environment for TRIOBUG. All geometry is created here.
var doors: Array[StaticBody3D] = []
var _door_open: Array[bool] = [false, false, false]
var _door_tweens: Array[Tween] = []
var _rings: Array[Node3D] = []
var _fans: Array[Node3D] = []
var _holograms: Array[Node3D] = []
var _reactor_core: MeshInstance3D
var _reactor_light: OmniLight3D
var _reactor_on: bool = false
var _time: float = 0.0
var _built: bool = false
var _m: Dictionary = {}

const NAVY: Color = Color("0c1322")
const STEEL: Color = Color("2e4056")
const CYAN: Color = Color("42e3d2")
const YELLOW: Color = Color("ffd166")
const CORAL: Color = Color("ff6b82")
const PURPLE: Color = Color("a58bff")
const WHITE: Color = Color("edf5ff")

func build() -> void:
	if _built:
		return
	_built = true
	name = "LaboratorioZero"
	_materials()
	_lighting()
	_room_shell("ODespertar", 8.0, 3.0, -20.0, CYAN)
	_room_shell("GravidadeQuebrada", 10.0, -24.0, -52.0, YELLOW, true)
	_room_shell("NucleoCentral", 12.0, -56.0, -88.0, PURPLE)
	_corridor(-20.0, -24.0, CYAN)
	_corridor(-52.0, -56.0, PURPLE)
	_corridor(-88.0, -93.0, CYAN)
	_box(self, Vector3(0, 4.5, 3.3), Vector3(16.5, 9, 0.6), _m.wall, true)
	_box(self, Vector3(0, 2.5, -93.3), Vector3(6.6, 5, 0.6), _m.wall, true)
	# Final bulkhead seals the full width so the exit cannot be bypassed.
	for side in [-1.0, 1.0]:
		_box(self, Vector3(side * 7.6, 4.5, -86), Vector3(9.2, 9.0, 0.8), _m.wall, true)
		_box(self, Vector3(side * 7.6, 5.3, -85.55), Vector3(9.0, 0.08, 0.08), _m.purple_glow)
	_door(-21.5, 0, CYAN)
	_door(-53.5, 1, YELLOW)
	_box(self, Vector3(0, 6.7, -86), Vector3(6.4, 4.6, 0.8), _m.wall, true)
	_door(-86.0, 2, PURPLE)
	_first_room()
	_second_room()
	_third_room()
	_sign(self, "SAÍDA  /  EXPERIMENTO 03", Vector3(0, 3.8, -92.8), CYAN, 38)

func _materials() -> void:
	_m.wall = _material(NAVY.lightened(0.045), 0.76, 0.32)
	_m.floor = _material(Color("1b293b"), 0.87, 0.23)
	_m.plate = _material(STEEL.darkened(0.2), 0.72, 0.45)
	_m.trim = _material(STEEL.lightened(0.08), 0.46, 0.65)
	_m.dark = _material(Color("080e19"), 0.82, 0.16)
	_m.white = _material(WHITE, 0.5, 0.13)
	_m.yellow = _material(YELLOW.darkened(0.13), 0.58, 0.35)
	_m.coral = _material(CORAL.darkened(0.1), 0.55, 0.25)
	_m.cyan_glow = _material(CYAN, 0.35, 0.25, 1.3)
	_m.yellow_glow = _material(YELLOW, 0.4, 0.1, 1.1)
	_m.purple_glow = _material(PURPLE, 0.38, 0.2, 1.2)
	_m.coral_glow = _material(CORAL, 0.4, 0.2, 1.0)
	_m.screen = _material(Color("112e40"), 0.22, 0.2, 0.3)
	var glass: StandardMaterial3D = _material(Color(0.15, 0.52, 0.65, 0.17), 0.18, 0.16)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_m.glass = glass
	var holo: StandardMaterial3D = _material(Color(0.26, 0.89, 0.82, 0.12), 0.2, 0.0, 0.8)
	holo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo.cull_mode = BaseMaterial3D.CULL_DISABLED
	_m.holo = holo

func _material(color: Color, roughness: float, metal: float, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metal
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = glow
	return material

func _lighting() -> void:
	var env := WorldEnvironment.new()
	env.name = "Ambiente"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("080f20")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9bb8de")
	settings.ambient_light_energy = 0.65
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.tonemap_exposure = 1.0
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "LuzPrincipal"
	sun.rotation_degrees = Vector3(-52, -25, 0)
	sun.light_color = Color("d8e8ff")
	sun.light_energy = 1.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)
	for z in [-8.0, -31.0, -47.0, -69.0, -82.0]:
		var fill := OmniLight3D.new()
		fill.position = Vector3(0, 5.5, z)
		fill.light_color = CYAN if z > -56.0 else PURPLE
		fill.light_energy = 1.2
		fill.omni_range = 13.0
		fill.shadow_enabled = false
		add_child(fill)

func _room_shell(room_name: String, half_width: float, front: float, back: float, accent: Color, gap: bool = false) -> void:
	var room := Node3D.new()
	room.name = room_name
	add_child(room)
	var length: float = front - back
	var center: float = (front + back) * 0.5
	if gap:
		_floor(room, half_width, front, -35.0)
		_floor(room, half_width, -41.0, back)
		_box(room, Vector3(0, -5.2, -38), Vector3(half_width * 2, 0.4, 6), _m.dark, true)
		for side in [-1.0, 1.0]:
			_box(room, Vector3(side * (half_width - 0.8), -0.18, -38), Vector3(1.6, 0.36, 6), _m.plate, true)
			_box(room, Vector3(side * (half_width - 1.58), 0.045, -38), Vector3(0.06, 0.045, 6), _m.yellow_glow)
		for z in [-35.0, -41.0]:
			_box(room, Vector3(0, 0.02, z), Vector3(16.8, 0.055, 0.15), _m.yellow)
			for x in range(-7, 8, 2):
				var stripe: MeshInstance3D = _box(room, Vector3(x, 0.056, z), Vector3(0.48, 0.025, 0.28), _m.dark)
				stripe.rotation.y = 0.4
	else:
		_floor(room, half_width, front, back)
	var accent_mat: StandardMaterial3D = _material(accent, 0.5, 0.1, 0.8)
	for side in [-1.0, 1.0]:
		_box(room, Vector3(side * (half_width + 0.18), 4.5, center), Vector3(0.5, 9.0, length), _m.wall, true)
		_box(room, Vector3(side * (half_width - 0.08), 0.33, center), Vector3(0.22, 0.66, length), _m.trim, true)
		_box(room, Vector3(side * (half_width - 0.23), 0.7, center), Vector3(0.07, 0.06, length - 0.5), accent_mat)
		_box(room, Vector3(side * (half_width - 0.1), 5.5, center), Vector3(0.22, 0.3, length), _m.trim)
		_box(room, Vector3(side * (half_width - 0.23), 5.65, center), Vector3(0.08, 0.08, length - 0.5), accent_mat)
		var z: float = front - 2.5
		while z > back + 1:
			_box(room, Vector3(side * (half_width - 0.1), 2.95, z), Vector3(0.4, 5.6, 0.33), _m.trim)
			_box(room, Vector3(side * (half_width - 0.34), 1.7, z), Vector3(0.06, 1.0, 0.12), accent_mat)
			z -= 5.0
	# Closed end walls surround a six-unit-wide corridor opening.
	for end in [front, back]:
		if is_equal_approx(front, 3.0) and is_equal_approx(end, front):
			continue
		for side in [-1.0, 1.0]:
			var section_width: float = half_width - 3.0
			_box(room, Vector3(side * (3.0 + section_width * 0.5), 4.5, end), Vector3(section_width, 9.0, 0.45), _m.wall, true)
			_box(room, Vector3(side * (3.0 + section_width * 0.5), 4.6, end + 0.25), Vector3(section_width - 0.5, 0.07, 0.07), accent_mat)
	# Parallel floor lanes draw players towards the next challenge.
	for side in [-1.0, 1.0]:
		if gap:
			_box(room, Vector3(side * 6.9, 0.018, (front - 35) * 0.5), Vector3(0.055, 0.03, front + 35), accent_mat)
			_box(room, Vector3(side * 6.9, 0.018, (-41 + back) * 0.5), Vector3(0.055, 0.03, -41 - back), accent_mat)
		else:
			_box(room, Vector3(side * (half_width - 1.5), 0.018, center), Vector3(0.055, 0.03, length - 0.5), accent_mat)

func _floor(parent: Node3D, half_width: float, front: float, back: float) -> void:
	var length: float = front - back
	var center: float = (front + back) * 0.5
	_box(parent, Vector3(0, -0.3, center), Vector3(half_width * 2, 0.6, length), _m.floor, true)
	# Thin recessed seams suggest industrial panels without hundreds of draw calls.
	var x: float = -half_width + 2.0
	while x < half_width:
		_box(parent, Vector3(x, 0.004, center), Vector3(0.035, 0.008, length - 0.2), _m.dark)
		x += 2.0
	var z: float = front - 2.0
	while z > back:
		_box(parent, Vector3(0, 0.005, z), Vector3(half_width * 2 - 0.2, 0.009, 0.035), _m.dark)
		z -= 2.0

func _corridor(front: float, back: float, accent: Color) -> void:
	var center: float = (front + back) * 0.5
	var length: float = front - back
	_box(self, Vector3(0, -0.2, center), Vector3(6.1, 0.4, length + 0.2), _m.plate, true)
	var glow: StandardMaterial3D = _material(accent, 0.5, 0.1, 1.0)
	for side in [-1.0, 1.0]:
		_box(self, Vector3(side * 3.15, 2.6, center), Vector3(0.35, 5.2, length), _m.wall, true)
		_box(self, Vector3(side * 2.93, 0.25, center), Vector3(0.07, 0.08, length), glow)
	_box(self, Vector3(0, 5.1, center), Vector3(6.4, 0.2, length), _m.trim)
	_box(self, Vector3(0, 4.95, center), Vector3(4.5, 0.05, 0.3), _m.white)

func _door(z: float, index: int, accent: Color) -> void:
	var frame := Node3D.new()
	frame.name = "Porta_%d" % index
	add_child(frame)
	for side in [-1.0, 1.0]:
		_box(frame, Vector3(side * 3.0, 2.35, z), Vector3(0.35, 4.7, 1.0), _m.trim)
		_box(frame, Vector3(side * 2.78, 2.35, z + 0.54), Vector3(0.09, 3.9, 0.06), _m.coral_glow)
	_box(frame, Vector3(0, 4.65, z), Vector3(6.4, 0.5, 1.0), _m.trim, true)
	var body := StaticBody3D.new()
	body.name = "Folha"
	body.position = Vector3(0, 2.2, z)
	frame.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.7, 4.4, 0.55)
	col.shape = shape
	body.add_child(col)
	_box(body, Vector3.ZERO, Vector3(5.7, 4.4, 0.55), _m.plate)
	_box(body, Vector3(-1.39, 0, 0.3), Vector3(2.65, 4.0, 0.08), _m.wall)
	_box(body, Vector3(1.39, 0, 0.3), Vector3(2.65, 4.0, 0.08), _m.wall)
	_box(body, Vector3(0, 0, 0.36), Vector3(0.055, 4.1, 0.04), _m.coral_glow)
	for y in [-1.5, 1.5]:
		_box(body, Vector3(0, y, 0.37), Vector3(4.7, 0.07, 0.05), _m.trim)
	_sign(body, "0%d   /   BLOQUEADO" % (index + 1), Vector3(0, 0.3, 0.4), WHITE, 32)
	_sign(frame, ["O DESPERTAR", "GRAVIDADE QUEBRADA", "SAÍDA DO LABORATÓRIO"][index], Vector3(0, 4.27, z + 0.57), accent, 26)
	doors.append(body)

func set_door_open(index: int, opened: bool) -> void:
	if index < 0 or index >= doors.size():
		return
	if _door_open[index] == opened:
		return
	_door_open[index] = opened
	var door: StaticBody3D = doors[index]
	for node in door.get_children():
		if node is CollisionShape3D:
			node.set_deferred("disabled", opened)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door, "position:y", 7.0 if opened else 2.2, 1.15)
	_door_tweens.append(tween)

func _first_room() -> void:
	_sign(self, "01", Vector3(-5.8, 4.5, -19.65), CYAN, 150)
	_sign(self, "O DESPERTAR", Vector3(5.7, 4.7, -19.65), WHITE, 40)
	_sign(self, "ENERGIA MAGNÉTICA", Vector3(5.7, 3.9, -19.64), CYAN, 23)
	for i in range(3):
		var x: float = (i - 1) * 2.0
		var glow: StandardMaterial3D = [_m.yellow_glow, _m.cyan_glow, _m.coral_glow][i]
		_cylinder(self, Vector3(x, 0.045, 0), 0.9, 0.08, _m.trim)
		_torus(self, Vector3(x, 0.1, 0), 0.67, 0.76, glow)
	for z in [-3.0, -8.0, -15.0]:
		_machine(Vector3(6.9, 0, z), CYAN)
	_window(Vector3(-7.68, 3.2, -6), Vector2(4.5, 2.4), PI * 0.5)
	_window(Vector3(-7.68, 3.2, -15.7), Vector2(3.8, 2.4), PI * 0.5)
	_console(Vector3(-5.8, 0, -3.3), "EXPERIMENTO 03", "SISTEMA REINICIADO", CYAN, -0.12)
	_crate(Vector3(5.8, 0, -11.2), 0.9, -0.18)
	_crate(Vector3(6.6, 0, -12.0), 0.72, 0.15)
	_pipe(Vector3(-7.3, 5.1, -8.5), Vector3(0, 0, -18), 0.13, _m.trim)
	_pipe(Vector3(7.3, 5.1, -8.5), Vector3(0, 0, -18), 0.13, _m.trim)
	_sign(self, "LABORATÓRIO ZERO", Vector3(0, 4.8, 2.9), WHITE, 54, PI)
	_sign(self, "ROBÓTICA EXPERIMENTAL  /  SETOR 03", Vector3(0, 4.05, 2.89), CYAN, 24, PI)

func _second_room() -> void:
	_sign(self, "02", Vector3(-6.7, 4.3, -51.65), YELLOW, 150)
	_sign(self, "GRAVIDADE", Vector3(6.5, 4.6, -51.65), WHITE, 40)
	_sign(self, "QUEBRADA", Vector3(6.5, 3.85, -51.64), YELLOW, 33)
	for side in [-1.0, 1.0]:
		_turbine(Vector3(side * 9.65, 3.4, -31), side)
		_turbine(Vector3(side * 9.65, 3.4, -46.5), side)
		for z in [-34.6, -41.4]:
			_box(self, Vector3(side * 6.3, 0.45, z), Vector3(0.18, 0.9, 0.18), _m.yellow)
			_box(self, Vector3(side * 4.1, 0.45, z), Vector3(0.18, 0.9, 0.18), _m.yellow)
			_box(self, Vector3(side * 5.2, 0.9, z), Vector3(2.4, 0.12, 0.12), _m.yellow)
		_pipe(Vector3(side * 8.7, 5.2, -38), Vector3(0, 0, -24), 0.2, _m.trim)
		_pipe(Vector3(side * 8.25, 5.2, -38), Vector3(0, 0, -24), 0.075, _m.yellow_glow)
	# Suspended research platforms are decorative and do not obstruct the crossing.
	for i in range(3):
		var root := Node3D.new()
		root.position = Vector3(-5.7 + i * 5.3, 2.7 + (i % 2) * 0.9, -38)
		root.rotation_degrees = Vector3(0, i * 19 - 12, 0)
		add_child(root)
		_box(root, Vector3.ZERO, Vector3(2, 0.22, 2), _m.trim)
		_box(root, Vector3(0, -0.14, 0), Vector3(1.7, 0.05, 1.7), _m.purple_glow)
		_holograms.append(root)
	_console(Vector3(7.8, 0, -28), "GRAVITON / 02", "CAMPO INSTÁVEL", YELLOW, -0.2)
	_sign(self, "CUIDADO  /  ZONA DE BAIXA GRAVIDADE", Vector3(0, 0.03, -33.0), YELLOW, 35, 0, -PI * 0.5)
	for i in range(6):
		var crystal := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.45, 1.1, 0.45)
		crystal.mesh = mesh
		crystal.material_override = _m.purple_glow
		crystal.position = Vector3(-6.5 + i * 2.6, -2.5 + (i % 2) * 0.7, -38)
		crystal.rotation.z = i * 0.6
		add_child(crystal)
		_holograms.append(crystal)

func _third_room() -> void:
	_sign(self, "03", Vector3(-7.5, 4.1, -85.5), PURPLE, 150)
	_sign(self, "NÚCLEO CENTRAL", Vector3(7.4, 4.2, -85.5), WHITE, 39)
	_sign(self, "TRÊS ROBÔS. UMA SAÍDA.", Vector3(7.4, 3.48, -85.49), PURPLE, 22)
	var base: MeshInstance3D = _cylinder(self, Vector3(0, 0.16, -73.8), 2.35, 0.32, _m.dark, true)
	base.name = "BaseReator"
	_cylinder(self, Vector3(0, 0.36, -73.8), 1.85, 0.18, _m.trim)
	_torus(self, Vector3(0, 0.49, -73.8), 1.6, 1.72, _m.purple_glow)
	_reactor_core = _sphere(self, Vector3(0, 3.0, -73.8), 1.0, _m.purple_glow)
	_reactor_core.name = "CoracaoDoLaboratorio"
	_cylinder(self, Vector3(0, 1.0, -73.8), 0.7, 0.8, _m.trim)
	_cylinder(self, Vector3(0, 1.7, -73.8), 0.44, 0.7, _m.cyan_glow)
	for i in range(3):
		var pivot := Node3D.new()
		pivot.position = Vector3(0, 3.0, -73.8)
		pivot.rotation_degrees = Vector3(25 + 28 * i, 33 * i, 18 + 32 * i)
		add_child(pivot)
		_torus(pivot, Vector3.ZERO, 1.65 + i * 0.27, 1.72 + i * 0.27, _m.trim)
		_torus(pivot, Vector3(0, 0.025, 0), 1.60 + i * 0.27, 1.63 + i * 0.27, _m.cyan_glow if i % 2 == 0 else _m.purple_glow)
		_rings.append(pivot)
	_reactor_light = OmniLight3D.new()
	_reactor_light.position = Vector3(0, 4.0, -73.8)
	_reactor_light.light_color = PURPLE
	_reactor_light.light_energy = 2.4
	_reactor_light.omni_range = 13.0
	add_child(_reactor_light)
	for side in [-1.0, 1.0]:
		for z in [-61.0, -68.0, -81.0]:
			_machine(Vector3(side * 10.65, 0, z), PURPLE)
			_cylinder(self, Vector3(side * 10.2, 3.2, z), 0.18, 5.2, _m.trim)
			_cylinder(self, Vector3(side * 10.2, 3.2, z), 0.09, 4.6, _m.purple_glow)
		_window(Vector3(side * 11.68, 3.2, -74), Vector2(5.8, 2.8), side * -PI * 0.5)
	for x in [-5.8, 0.0, 5.8]:
		var glow: StandardMaterial3D = _m.yellow_glow if x < -1 else (_m.coral_glow if x > 1 else _m.cyan_glow)
		_box(self, Vector3(x, 0.022, -82.5), Vector3(0.08, 0.04, 4.5), glow)
	_console(Vector3(-8.8, 0, -58.5), "NÚCLEO / 03", "REINÍCIO MANUAL", PURPLE, 0.1)

func set_reactor_active(active: bool) -> void:
	_reactor_on = active
	if is_instance_valid(_reactor_core):
		_reactor_core.material_override = _m.cyan_glow if active else _m.purple_glow
	if is_instance_valid(_reactor_light):
		_reactor_light.light_color = CYAN if active else PURPLE

func _machine(pos: Vector3, accent: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	if pos.x < 0:
		root.rotation.y = PI
	add_child(root)
	var light_mat: StandardMaterial3D = _material(accent, 0.45, 0.1, 0.7)
	_box(root, Vector3(0, 1.0, 0), Vector3(1.25, 2, 1.25), _m.plate, true)
	_box(root, Vector3(0, 2.1, 0), Vector3(1.4, 0.22, 1.35), _m.trim)
	_box(root, Vector3(-0.65, 1.22, 0), Vector3(0.04, 1.1, 0.85), _m.dark)
	for z in [-0.28, 0.0, 0.28]:
		_box(root, Vector3(-0.68, 1.2, z), Vector3(0.04, 0.75, 0.075), light_mat)
	for z in [-0.3, 0.3]:
		_cylinder(root, Vector3(z, 2.35, 0), 0.11, 0.35, _m.trim)

func _window(pos: Vector3, size: Vector2, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	_box(root, Vector3.ZERO, Vector3(size.x + 0.24, size.y + 0.24, 0.16), _m.trim)
	_box(root, Vector3(0, 0, 0.1), Vector3(size.x, size.y, 0.04), _m.screen)
	_box(root, Vector3(0, 0, 0.15), Vector3(size.x - 0.1, size.y - 0.1, 0.02), _m.glass)
	for offset in [-0.3, 0.3]:
		_box(root, Vector3(offset * size.x, 0, 0.18), Vector3(0.07, size.y, 0.05), _m.trim)
	_box(root, Vector3(0, -size.y * 0.36, 0.2), Vector3(size.x - 0.2, 0.04, 0.03), _m.cyan_glow)

func _console(pos: Vector3, title: String, subtitle: String, color: Color, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	_box(root, Vector3(0, 0.4, 0), Vector3(1.9, 0.8, 1.0), _m.trim, true)
	var panel := Node3D.new()
	panel.position = Vector3(0, 1.5, -0.15)
	panel.rotation.x = -0.15
	root.add_child(panel)
	_box(panel, Vector3.ZERO, Vector3(2.6, 1.45, 0.16), _m.dark)
	_box(panel, Vector3(0, 0, 0.1), Vector3(2.4, 1.25, 0.02), _m.screen)
	_sign(panel, title, Vector3(0, 0.3, 0.15), color, 22)
	_sign(panel, subtitle, Vector3(0, -0.04, 0.15), WHITE, 15)
	for i in range(7):
		_box(panel, Vector3(-0.95 + 0.29 * i, -0.4, 0.15), Vector3(0.18, 0.035 + (i % 3) * 0.06, 0.02), _m.cyan_glow)

func _crate(pos: Vector3, size: float, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	_box(root, Vector3(0, size * 0.5, 0), Vector3.ONE * size, _m.plate, true)
	for side in [-1.0, 1.0]:
		_box(root, Vector3(side * size * 0.35, size * 0.5, size * 0.51), Vector3(size * 0.1, size * 0.9, 0.04), _m.yellow)
	_box(root, Vector3(0, size * 0.55, size * 0.53), Vector3(size * 0.35, size * 0.23, 0.03), _m.dark)

func _turbine(pos: Vector3, side: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.z = PI * 0.5 * side
	add_child(root)
	_cylinder(root, Vector3.ZERO, 1.7, 0.12, _m.dark)
	_torus(root, Vector3(0, 0.12, 0), 1.48, 1.7, _m.trim)
	_torus(root, Vector3(0, 0.15, 0), 1.37, 1.42, _m.yellow_glow)
	var rotor := Node3D.new()
	root.add_child(rotor)
	for i in range(5):
		var blade := Node3D.new()
		blade.rotation.y = i * TAU / 5.0
		rotor.add_child(blade)
		var part: MeshInstance3D = _box(blade, Vector3(0, 0.15, 0.85), Vector3(0.35, 0.1, 1.2), _m.trim)
		part.rotation.z = -0.2
	_cylinder(root, Vector3(0, 0.25, 0), 0.3, 0.35, _m.yellow)
	_fans.append(rotor)

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		parent.add_child(body)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
	return instance

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		parent.add_child(body)
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		col.shape = shape
		body.add_child(col)
	return instance

func _sphere(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

func _torus(parent: Node3D, pos: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 32
	mesh.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

func _pipe(pos: Vector3, offset: Vector3, radius: float, material: Material) -> void:
	var cylinder: MeshInstance3D = _cylinder(self, pos, radius, offset.length(), material)
	if absf(offset.z) > 0.1:
		cylinder.rotation.x = PI * 0.5
	elif absf(offset.x) > 0.1:
		cylinder.rotation.z = PI * 0.5

func _sign(parent: Node3D, content: String, pos: Vector3, color: Color, font_size: int = 32, yaw: float = 0.0, pitch: float = 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = content
	label.position = pos
	label.rotation = Vector3(pitch, yaw, 0)
	label.font_size = font_size
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_modulate = Color("08101c")
	label.outline_size = 3
	label.no_depth_test = false
	label.shaded = false
	parent.add_child(label)
	return label

func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	var speed: float = 0.35 if not _reactor_on else 1.1
	for i in range(_rings.size()):
		_rings[i].rotate_y(delta * speed * (1.0 if i % 2 == 0 else -0.7))
		_rings[i].rotate_x(delta * speed * 0.12)
	for fan in _fans:
		fan.rotate_y(delta * 1.8)
	for i in range(_holograms.size()):
		var holo: Node3D = _holograms[i]
		holo.position.y += sin(_time * 1.1 + i * 1.2) * delta * 0.13
		holo.rotate_y(delta * 0.13)
	if is_instance_valid(_reactor_core):
		_reactor_core.position.y = 3.0 + sin(_time * 1.6) * 0.12
		_reactor_core.scale = Vector3.ONE * (1.0 + sin(_time * 2.3) * 0.025)
