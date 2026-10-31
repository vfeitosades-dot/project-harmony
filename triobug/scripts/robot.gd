extends CharacterBody3D
class_name TrioRobot

## Procedural character and server-driven character controller. No downloaded art.
var robot_index: int = 0
var controlled: bool = false
var face_camera: bool = false
var input_move: Vector2 = Vector2.ZERO
var input_jump: bool = false
var input_run: bool = false
var view_yaw: float = 0.0
var simulate: bool = true
var low_gravity: bool = false
var using_ability: bool = false
var display_name: String = ""
var celebrate: bool = false
var animation_speed: float = 0.0
var remote_velocity: Vector3 = Vector3.ZERO
var visual: Node3D

var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _antenna: Node3D
var _core: MeshInstance3D
var _badge: Label3D
var _eyes: Array[MeshInstance3D] = []
var _rings: Array[MeshInstance3D] = []
var _selection: MeshInstance3D
var _shell: StandardMaterial3D
var _glow: StandardMaterial3D
var _dark: StandardMaterial3D
var _white: StandardMaterial3D
var _metal: StandardMaterial3D
var _time: float = 0.0
var _stride: float = 0.0
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _squash: float = 0.0
var _last_grounded: bool = true
var _ready_model: bool = false
var _facing: float = 0.0
var _bump_cooldown: float = 0.0
var _surprise_time: float = 0.0

func setup(index: int) -> void:
	if _ready_model:
		return
	_ready_model = true
	robot_index = clampi(index, 0, 2)
	var colors: Array[Color] = [Color("ffd166"), Color("42e3d2"), Color("ff6b82")]
	var names: Array[String] = ["BIPO", "GRAVI", "LIGA"]
	if display_name.is_empty():
		display_name = names[robot_index]
	_shell = _material(colors[robot_index], 0.15, 0.38)
	_glow = _material(colors[robot_index].lightened(0.25), 0.15, 0.26, 1.6)
	_dark = _material(Color("101e30"), 0.35, 0.32)
	_white = _material(Color("edf5ff"), 0.16, 0.3, 0.25)
	_metal = _material(Color("708ba2"), 0.72, 0.3)
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.4
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.7
	add_child(collision)
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.2
	floor_max_angle = deg_to_rad(48.0)
	visual = Node3D.new()
	visual.name = "RobotVisual"
	add_child(visual)
	_build_torso()
	_build_head()
	_left_arm = _build_arm(-1.0)
	_right_arm = _build_arm(1.0)
	_left_leg = _build_leg(-1.0)
	_right_leg = _build_leg(1.0)
	_selection = _torus(visual, Vector3(0, 0.035, 0), 0.43, 0.46, _glow)
	_badge = Label3D.new()
	_badge.name = "PlayerName"
	_badge.position = Vector3(0, 1.82, 0)
	_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge.font_size = 36
	_badge.pixel_size = 0.0032
	_badge.modulate = colors[robot_index].lightened(0.2)
	_badge.outline_size = 8
	_badge.outline_modulate = Color("0c1322")
	_badge.visibility_range_end = 24.0
	_badge.text = display_name
	add_child(_badge)

func set_badge(text: String) -> void:
	display_name = text.left(28)
	if is_instance_valid(_badge):
		_badge.text = display_name

func reset_at(pos: Vector3) -> void:
	if is_inside_tree():
		global_position = pos
	else:
		position = pos
	velocity = Vector3.ZERO
	input_move = Vector2.ZERO
	input_jump = false
	_jump_buffer = 0.0
	_coyote = 0.0

func _physics_process(delta: float) -> void:
	if not _ready_model or not simulate:
		return
	var grounded: bool = is_on_floor()
	_bump_cooldown = maxf(0.0, _bump_cooldown - delta)
	_coyote = 0.12 if grounded else maxf(0.0, _coyote - delta)
	if input_jump:
		_jump_buffer = 0.12
		input_jump = false
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	var move: Vector2 = input_move.limit_length(1.0)
	var direction: Vector3 = Vector3(move.x, 0, move.y).rotated(Vector3.UP, view_yaw)
	var target_speed: float = 7.0 if input_run else 5.0
	var acceleration: float = 15.0 if direction.length_squared() > 0.001 else 18.0
	velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	if not grounded:
		velocity.y = maxf(velocity.y - (4.8 if low_gravity else 22.0) * delta, -22.0)
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = 7.6 if low_gravity else 7.0
		_coyote = 0.0
		_jump_buffer = 0.0
		_squash = -0.07
	if direction.length_squared() > 0.04:
		_facing = atan2(-direction.x, -direction.z)
	elif using_ability:
		_facing = view_yaw
	move_and_slide()
	if _bump_cooldown <= 0.0 and move.length_squared() > 0.1:
		for collision_index in range(get_slide_collision_count()):
			var contact: KinematicCollision3D = get_slide_collision(collision_index)
			if contact.get_collider() is CharacterBody3D and absf(contact.get_normal().y) < 0.4:
				_squash = 0.065
				_surprise_time = 0.28
				_bump_cooldown = 0.55
				break
	var landed: bool = is_on_floor() and not _last_grounded
	if landed:
		_squash = 0.1
	_last_grounded = is_on_floor()
	animation_speed = Vector2(velocity.x, velocity.z).length()

func _process(delta: float) -> void:
	if not _ready_model:
		return
	_time += delta
	_surprise_time = maxf(0.0, _surprise_time - delta)
	var speed: float = animation_speed if simulate else Vector2(remote_velocity.x, remote_velocity.z).length()
	if not simulate:
		if speed > 0.05:
			_facing = atan2(-remote_velocity.x, -remote_velocity.z)
		elif using_ability:
			_facing = view_yaw
	_stride += delta * (6.0 + speed * 1.25)
	var walk: float = minf(speed / 5.0, 1.35)
	var grounded: bool = is_on_floor() if simulate else absf(remote_velocity.y) < 0.3
	_squash = move_toward(_squash, 0.0, delta * 0.65)
	visual.scale = Vector3(1.0 + _squash * 0.45, 1.0 - _squash, 1.0 + _squash * 0.45)
	visual.rotation.y = lerp_angle(visual.rotation.y, PI if face_camera else _facing, minf(1.0, delta * 13.0))
	visual.position.y = sin(_time * 2.7 + robot_index) * 0.012 + absf(sin(_stride)) * 0.034 * walk
	if robot_index == 1:
		visual.position.y += 0.04 + sin(_time * 3.2) * 0.025
	visual.rotation.z = sin(_stride) * 0.025 * walk
	visual.rotation.x = lerpf(visual.rotation.x, -0.08 * walk, minf(1.0, delta * 8.0))
	_head.rotation.z = sin(_time * 1.7) * 0.035 + sin(_stride - 0.4) * 0.025 * walk
	_head.rotation.x = sin(_time * 2.0) * 0.025
	var leg_swing: float = sin(_stride) * 0.65 * walk if grounded else 0.22
	_left_leg.rotation.x = leg_swing
	_right_leg.rotation.x = -leg_swing
	_left_arm.rotation.x = -leg_swing * 0.8
	_right_arm.rotation.x = leg_swing * 0.8
	_left_arm.rotation.z = 0.06
	_right_arm.rotation.z = -0.06
	if using_ability:
		_left_arm.rotation.x = -1.2 + sin(_time * 16.0) * 0.045
		_right_arm.rotation.x = -1.2 - sin(_time * 16.0) * 0.045
		_head.rotation.x = -0.07
	if celebrate:
		_left_arm.rotation.z = 2.4 + sin(_time * 12.0) * 0.25
		_right_arm.rotation.z = -2.4 - sin(_time * 12.0) * 0.25
		visual.position.y += absf(sin(_time * 6.0)) * 0.13
		_head.rotation.z = sin(_time * 8.0) * 0.12
	if _antenna != null:
		_antenna.rotation.z = sin(_time * 5.0) * 0.09 + sin(_stride + 0.5) * 0.12 * walk
	var blink_phase: float = fmod(_time + robot_index * 0.8, 4.1)
	var eye_scale: float = 0.12 if blink_phase > 3.92 else 1.0
	if _surprise_time > 0.0:
		eye_scale = 1.22
		_head.rotation.x = -0.1
	if celebrate:
		eye_scale = 0.55
	for eye: MeshInstance3D in _eyes:
		eye.scale.y = 0.108 * eye_scale
	for i: int in range(_rings.size()):
		_rings[i].rotation.z = sin(_time * 1.8 + i) * 0.22
		_rings[i].rotation.x = sin(_time * 1.4 + i) * 0.16
	if _core != null:
		var pulse: float = 1.0 + sin(_time * (12.0 if using_ability else 3.0)) * (0.12 if using_ability else 0.04)
		_core.scale = Vector3(0.13, 0.13, 0.042) * pulse
	_selection.visible = controlled
	_selection.rotation.y += delta

func _build_torso() -> void:
	var body_scale: Vector3 = Vector3(0.55, 0.6, 0.39)
	if robot_index == 1:
		body_scale = Vector3(0.61, 0.66, 0.45)
	elif robot_index == 2:
		body_scale = Vector3(0.47, 0.55, 0.36)
	_sphere(visual, Vector3(0, 0.65, 0), body_scale, _shell)
	_sphere(visual, Vector3(0, 0.63, -0.175), Vector3(0.35, 0.34, 0.13), _dark)
	_core = _sphere(visual, Vector3(0, 0.68, -0.252), Vector3(0.13, 0.13, 0.042), _glow)
	_torus(visual, Vector3(0, 0.68, -0.245), 0.071, 0.086, _metal).rotation_degrees.x = 90.0
	for x: float in [-0.13, 0.0, 0.13]:
		_box(visual, Vector3(x, 0.48, -0.18), Vector3(0.055, 0.028, 0.04), _metal)
	_box(visual, Vector3(0, 0.69, 0.23), Vector3(0.32, 0.35, 0.15), _dark)
	for x: float in [-0.095, 0.095]:
		_cylinder(visual, Vector3(x, 0.7, 0.33), 0.062, 0.28, _metal)
		for y: float in [0.61, 0.66, 0.71, 0.76]:
			_torus(visual, Vector3(x, y, 0.33), 0.061, 0.073, _glow if robot_index == 1 else _shell)
	if robot_index == 1:
		_rings.append(_torus(visual, Vector3(0, 0.6, 0), 0.39, 0.415, _glow))
		_rings.append(_torus(visual, Vector3(0, 0.43, 0), 0.31, 0.327, _metal))
	elif robot_index == 2:
		for side: float in [-1.0, 1.0]:
			_sphere(visual, Vector3(side * 0.2, 0.64, 0), Vector3(0.08, 0.35, 0.32), _white)

func _build_head() -> void:
	_head = Node3D.new()
	_head.position.y = 1.1
	visual.add_child(_head)
	_cylinder(visual, Vector3(0, 0.935, 0), 0.105, 0.12, _dark)
	var head_scale: Vector3 = Vector3(0.76, 0.48, 0.53)
	if robot_index == 1:
		head_scale = Vector3(0.66, 0.56, 0.53)
	elif robot_index == 2:
		head_scale = Vector3(0.7, 0.43, 0.47)
	_sphere(_head, Vector3.ZERO, head_scale, _shell)
	_sphere(_head, Vector3(0, 0.015, -0.228), Vector3(0.57, 0.265, 0.14), _dark)
	for side: float in [-1.0, 1.0]:
		var eye_pos: Vector3 = Vector3(side * 0.135, 0.025, -0.291)
		var eye: MeshInstance3D = _sphere(_head, eye_pos, Vector3(0.065, 0.108, 0.025), _white)
		_eyes.append(eye)
		var ear: MeshInstance3D = _cylinder(_head, Vector3(side * (0.34 if robot_index == 1 else 0.38), 0, 0), 0.09, 0.1, _dark)
		ear.rotation_degrees.z = 90
		var cap: MeshInstance3D = _cylinder(_head, Vector3(side * (0.395 if robot_index == 1 else 0.435), 0, 0), 0.065, 0.025, _glow if robot_index == 1 else _metal)
		cap.rotation_degrees.z = 90
	if robot_index == 0:
		_antenna = Node3D.new()
		_antenna.position = Vector3(0.14, 0.19, 0.04)
		_head.add_child(_antenna)
		_cylinder(_antenna, Vector3(0, 0.105, 0), 0.014, 0.21, _dark)
		_sphere(_antenna, Vector3(0, 0.22, 0), Vector3.ONE * 0.095, _glow)
		_box(_head, Vector3(-0.2, 0.16, -0.04), Vector3(0.09, 0.04, 0.32), _white)
	elif robot_index == 1:
		_torus(_head, Vector3(0, 0.27, 0), 0.19, 0.212, _glow)
		for x: float in [-0.1, 0.0, 0.1]:
			_sphere(_head, Vector3(x, -0.14, -0.205), Vector3.ONE * 0.035, _metal)
	else:
		for side: float in [-1.0, 1.0]:
			_sphere(_head, Vector3(side * 0.24, -0.075, -0.235), Vector3(0.065, 0.035, 0.022), _glow)
		_box(_head, Vector3(0, 0.18, 0.03), Vector3(0.24, 0.045, 0.16), _white)

func _build_arm(side: float) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.position = Vector3(side * 0.325, 0.84, 0)
	visual.add_child(pivot)
	_sphere(pivot, Vector3.ZERO, Vector3.ONE * 0.13, _metal)
	_cylinder(pivot, Vector3(0, -0.13, 0), 0.055 if robot_index == 2 else 0.067, 0.24, _dark)
	_sphere(pivot, Vector3(0, -0.2, 0), Vector3.ONE * 0.11, _shell)
	if robot_index == 0:
		_box(pivot, Vector3(0, -0.29, 0), Vector3(0.16, 0.08, 0.13), _metal)
		for fork: float in [-1.0, 1.0]:
			_box(pivot, Vector3(fork * 0.056, -0.335, -0.06), Vector3(0.048, 0.12, 0.1), _shell)
			_box(pivot, Vector3(fork * 0.056, -0.405, -0.06), Vector3(0.049, 0.034, 0.103), _white)
	elif robot_index == 1:
		_sphere(pivot, Vector3(0, -0.32, -0.01), Vector3(0.15, 0.18, 0.15), _shell)
		_torus(pivot, Vector3(0, -0.27, 0), 0.075, 0.087, _glow)
	else:
		for y: float in [-0.09, -0.14, -0.19, -0.24]:
			_torus(pivot, Vector3(0, y, 0), 0.055, 0.072, _white)
		_sphere(pivot, Vector3(0, -0.33, -0.02), Vector3(0.15, 0.15, 0.18), _shell)
	return pivot

func _build_leg(side: float) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.position = Vector3(side * 0.16, 0.4, 0)
	visual.add_child(pivot)
	_sphere(pivot, Vector3.ZERO, Vector3.ONE * 0.12, _metal)
	_cylinder(pivot, Vector3(0, -0.12, 0), 0.06, 0.22, _dark)
	_sphere(pivot, Vector3(0, -0.15, -0.02), Vector3(0.11, 0.11, 0.11), _shell)
	var foot_width: float = 0.25 if robot_index == 2 else 0.22
	_sphere(pivot, Vector3(0, -0.29, -0.065), Vector3(foot_width, 0.18, 0.34), _shell)
	_box(pivot, Vector3(0, -0.355, -0.06), Vector3(foot_width * 0.85, 0.035, 0.25), _dark)
	_box(pivot, Vector3(0, -0.28, -0.21), Vector3(0.1, 0.025, 0.018), _glow)
	return pivot

func _material(color: Color, metalness: float, roughness_value: float, emission_strength: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalness
	material.roughness = roughness_value
	if emission_strength > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength
	return material

func _instance(parent: Node3D, pos: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 20
	sphere.rings = 12
	var instance: MeshInstance3D = _instance(parent, pos, sphere, material)
	instance.scale = size
	return instance

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return _instance(parent, pos, box, material)

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 16
	return _instance(parent, pos, cylinder, material)

func _torus(parent: Node3D, pos: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 20
	torus.ring_segments = 8
	return _instance(parent, pos, torus, material)
