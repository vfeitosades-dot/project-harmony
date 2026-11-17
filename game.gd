extends Node3D
const Bot = preload("res://bot.gd")
const Hud = preload("res://hud.gd")
var state := "menu"
var previous_state := "play"
var player: CharacterBody3D
var cam: Camera3D
var gun: Node3D
var flash: MeshInstance3D
var hud: Control
var nav := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var bots: Array[CharacterBody3D] = []
var effects: Array[Dictionary] = []
var health := 100.0
var armor := 50.0
var ammo := 25
var reserve := 100
var reload_time := 0.0
var fire_cd := 0.0
var recoil := 0.0
var pitch := 0.0
var sensitivity := 0.0022
var round_no := 1
var kills := 0
var headshots := 0
var shots := 0
var hits := 0
var time_left := 110.0
var elapsed := 0.0
var dash_cd := 0.0
var scan_cd := 0.0
var scan_time := 0.0
var dash_time := 0.0
var damage_flash := 0.0
var hit_time := 0.0
var head_hit := false
var defuse := 0.0
var notice := ""
var notice_time := 0.0
var feed: Array[Dictionary] = []
var reactor: Node3D
var ring: MeshInstance3D
var audio: Dictionary = {}
var round_kills := 0
var test_mode := false
var mouse_guard := 0.0

func _ready() -> void:
	randomize()
	_build_map()
	_build_player()
	hud = Control.new()
	hud.set_script(Hud)
	hud.game = self
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["shot","reload","hit","kill","dash","scan","win","hurt","alarm"]:
		audio[s] = load("res://audio/"+s+".wav")
	cam.position = Vector3(0,12,23)
	cam.look_at_from_position(Vector3(0,12,23),Vector3(0,1,-3))
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	if test_mode: call_deferred("_smoke_test")

func material(c: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.82
	if emission>0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := false, glow := 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color,glow)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		parent.add_child(body)
		body.position = pos
		var col := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = size
		col.shape = b
		body.add_child(col)
		if pos.y>0 and pos.y-size.y/2<2:
			obstacles.append(Rect2(Vector2(pos.x-size.x/2-0.45,pos.z-size.z/2-0.45),Vector2(size.x+0.9,size.z+0.9)))
	return mesh

func cylinder(parent: Node3D,pos: Vector3,r: float,h: float,c: Color,top := -1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = r if top<0 else top
	shape.bottom_radius = r
	shape.height = h
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = material(c)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func sign3d(text: String,pos: Vector3,size: int,color: Color,rot := 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.012
	l.modulate = color
	l.outline_size = 0
	l.no_depth_test = false
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(l)
	l.position = pos
	l.rotation.y = rot

func _build_map() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("478caa")
	sm.sky_horizon_color = Color("c8d9d6")
	sm.ground_bottom_color = Color("485b64")
	sm.ground_horizon_color = Color("d4ded8")
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b3d6e6")
	e.ambient_light_energy = 0.38
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-55,-32,0)
	sun.light_color = Color("fff1d4")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	var cream := Color("d4c9b6")
	var wall := Color("b5b5aa")
	var dark := Color("253b46")
	var teal := Color("378d88")
	var coral := Color("ca6f59")
	box(self,Vector3(0,-0.3,0),Vector3(46,0.6,54),Color("8b9694"),true)
	for x in range(-20,23,4):
		box(self,Vector3(x,0.005,0),Vector3(0.025,0.01,52),Color("a4adaa"))
	for z in range(-24,26,4):
		box(self,Vector3(0,0.006,z),Vector3(44,0.01,0.025),Color("a4adaa"))
	box(self,Vector3(-23,3,0),Vector3(2,6,56),cream,true)
	box(self,Vector3(23,3,0),Vector3(2,6,56),cream,true)
	box(self,Vector3(0,3,-27),Vector3(48,6,2),cream,true)
	box(self,Vector3(0,3,27),Vector3(48,6,2),cream,true)
	# Main architecture: two lanes and an open reactor court.
	for side in [-1,1]:
		box(self,Vector3(side*12,2.8,10),Vector3(7,5.6,9),cream,true)
		box(self,Vector3(side*12,2.8,-12),Vector3(7,5.6,10),wall,true)
		box(self,Vector3(side*12,5.7,10),Vector3(7.6,0.4,9.6),dark)
		box(self,Vector3(side*12,5.7,-12),Vector3(7.6,0.4,10.6),dark)
		box(self,Vector3(side*12,3.5,14.55),Vector3(6,1.5,0.12),teal if side<0 else coral)
		box(self,Vector3(side*12,1.4,14.6),Vector3(3,2.8,0.18),dark)
		for z in [-14,-11,-8]:
			box(self,Vector3(side*12,3.5,z),Vector3(7.05,1.4,0.65),teal)
		for z in range(-22,25,6):
			box(self,Vector3(side*21.8,2.8,z),Vector3(0.15,0.18,3),Color("72ddcf"),false,1)
		# raised skyline structures beyond the play area
		for j in range(6):
			box(self,Vector3(side*(25+j%2*4),4+j%3*2,-22+j*9),Vector3(5,8+j%3*4,6),Color("8faaa9"))
		box(self,Vector3(side*19,0.45,19),Vector3(3,0.9,3),dark,true)
		for j in range(4):
			cylinder(self,Vector3(side*19+randf_range(-0.8,0.8),1.5,19+randf_range(-0.8,0.8)),0.7,1.8,Color("477f65"),0.05)
	# crate groups, with distinct trims and inset panels
	for p in [Vector3(-4,0,7),Vector3(5,0,1),Vector3(-5,0,-8),Vector3(6,0,-19),Vector3(-18,0,-3),Vector3(18,0,3),Vector3(2,0,15)]:
		crate(p,Vector3(2.6,2.2,2.4))
	box(self,Vector3(0,0.06,-3.5),Vector3(9,0.1,9),Color("677c7c"))
	for x in [-4.5,4.5]: box(self,Vector3(x,0.13,-3.5),Vector3(0.09,0.05,9),Color("5debd0"),false,1)
	for z in [-8,1]: box(self,Vector3(0,0.13,z),Vector3(9,0.05,0.09),Color("5debd0"),false,1)
	for x in [-20,20]:
		box(self,Vector3(x,3,-25.7),Vector3(0.35,6,0.35),dark)
	box(self,Vector3(0,5.7,-25.4),Vector3(40,0.25,0.5),dark)
	sign3d("VERTICE  /  RESEARCH DIVISION",Vector3(0,4.3,-25.9),48,dark)
	sign3d("01",Vector3(-12,3.5,14.7),100,Color("e5f3e9"))
	sign3d("02",Vector3(12,3.5,14.7),100,Color("ffe5d2"))
	sign3d("A   /   REACTOR",Vector3(0,2.7,-25.8),40,teal)
	sign3d("SECTOR  07",Vector3(-21.9,3,0),55,dark,PI/2)
	reactor = Node3D.new()
	add_child(reactor)
	reactor.position = Vector3(0,0,-3.5)
	cylinder(reactor,Vector3(0,0.25,0),1.25,0.5,dark)
	cylinder(reactor,Vector3(0,1,0),0.65,1.3,Color("28464d"),0.45)
	box(reactor,Vector3(0,1.25,0),Vector3(0.45,1.3,0.45),Color("54f7d7"),false,2)
	for a in range(4):
		var fin := box(reactor,Vector3(sin(a*PI/2)*0.68,1.1,cos(a*PI/2)*0.68),Vector3(0.2,1.8,0.42),dark)
		fin.rotation.y = a*PI/2
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.05
	ring = MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = material(Color("54f7d7"),2)
	reactor.add_child(ring)
	ring.position.y = 1.8
	nav.region = Rect2i(-21,-25,43,51)
	nav.cell_size = Vector2.ONE
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for x in range(-21,22):
		for z in range(-25,26):
			for rect in obstacles:
				if rect.has_point(Vector2(x,z)):
					nav.set_point_solid(Vector2i(x,z))
					break

func crate(p: Vector3,s: Vector3) -> void:
	box(self,p+Vector3(0,s.y/2,0),s,Color("345c62"),true)
	box(self,p+Vector3(0,s.y+0.04,0),Vector3(s.x+0.1,0.12,s.z+0.1),Color("253d47"))
	for x in [-1,1]:
		box(self,p+Vector3(x*(s.x/2-0.2),s.y/2,s.z/2+0.015),Vector3(0.15,s.y,0.04),Color("8eb1a6"))
	box(self,p+Vector3(0,s.y*0.65,s.z/2+0.035),Vector3(s.x*0.65,0.14,0.04),Color("71e5ca"),false,0.5)

func _build_player() -> void:
	player = CharacterBody3D.new()
	add_child(player)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	player.add_child(shape)
	cam = Camera3D.new()
	player.add_child(cam)
	cam.position.y = 1.65
	cam.fov = 85
	cam.near = 0.04
	gun = Node3D.new()
	cam.add_child(gun)
	gun.position = Vector3(0.31,-0.29,-0.5)
	gun.scale = Vector3.ONE*0.82
	var dark := Color("182b38")
	var metal := Color("41616b")
	box(gun,Vector3(0,0,-0.22),Vector3(0.15,0.17,0.58),dark)
	box(gun,Vector3(0,0.08,-0.25),Vector3(0.11,0.06,0.55),metal)
	box(gun,Vector3(0,0,-0.67),Vector3(0.065,0.065,0.38),dark)
	box(gun,Vector3(0,0,-0.85),Vector3(0.1,0.09,0.09),metal)
	box(gun,Vector3(0,-0.13,-0.16),Vector3(0.12,0.25,0.16),metal).rotation.x = -0.2
	box(gun,Vector3(0,-0.09,0.02),Vector3(0.1,0.22,0.11),dark).rotation.x = 0.25
	box(gun,Vector3(0,0,0.19),Vector3(0.12,0.16,0.3),metal)
	box(gun,Vector3(0,0.16,-0.17),Vector3(0.08,0.1,0.12),dark)
	box(gun,Vector3(0,0.19,-0.11),Vector3(0.045,0.035,0.01),Color("55f7d6"),false,1)
	box(gun,Vector3(0.079,0,-0.25),Vector3(0.009,0.035,0.34),Color("6cf4d3"),false,1)
	for z in [-0.32,-0.4,-0.48]: box(gun,Vector3(0.08,0.04,z),Vector3(0.01,0.05,0.025),Color("bdd8cd"))
	# Gloved hands and sleeve silhouettes, built from beveled low-poly primitives.
	cylinder(gun,Vector3(-0.075,-0.15,-0.42),0.065,0.16,Color("263d46")).rotation.z = PI/2
	box(gun,Vector3(-0.16,-0.24,-0.31),Vector3(0.13,0.14,0.33),Color("ccd3c3")).rotation.y = -0.35
	box(gun,Vector3(0.02,-0.22,0.06),Vector3(0.13,0.16,0.21),Color("263d46"))
	box(gun,Vector3(0.04,-0.32,0.19),Vector3(0.15,0.14,0.3),Color("ccd3c3"))
	flash = box(gun,Vector3(0,0,-0.97),Vector3(0.12,0.12,0.24),Color("ffe5a0"),false,3)
	flash.visible = false
	for mesh in gun.get_children():
		if mesh is MeshInstance3D: mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func spawn_bot(pos: Vector3,index: int) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.set_script(Bot)
	b.game = self
	b.number = index
	b.shot_cd = 1.8+index*0.13
	add_child(b)
	b.position = pos
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.9
	cap.radius = 0.38
	col.shape = cap
	col.position.y = 0.95
	b.add_child(col)
	var model := Node3D.new()
	b.add_child(model)
	b.torso = model
	var body := Color("313c4c")
	var red := Color("d4695c")
	cylinder(model,Vector3(0,1.18,0),0.31,0.6,body,0.39)
	box(model,Vector3(0,1.25,-0.25),Vector3(0.53,0.42,0.13),red)
	box(model,Vector3(0,1.38,-0.33),Vector3(0.3,0.06,0.03),Color("ffb4a0"),false,1)
	cylinder(model,Vector3(0,1.78,0),0.24,0.39,body,0.20)
	box(model,Vector3(0,1.82,-0.21),Vector3(0.34,0.09,0.08),Color("ff725f"),false,1.5)
	for s in [-1,1]:
		var leg := Node3D.new()
		model.add_child(leg)
		leg.position = Vector3(s*0.18,0.85,0)
		box(leg,Vector3(0,-0.32,0),Vector3(0.22,0.65,0.25),body)
		box(leg,Vector3(0,-0.64,-0.07),Vector3(0.25,0.16,0.4),Color("1e2b36"))
		b.limbs.append(leg)
		box(model,Vector3(s*0.41,1.37,0),Vector3(0.23,0.3,0.3),red)
		box(model,Vector3(s*0.4,1.1,-0.16),Vector3(0.18,0.36,0.23),body)
	box(model,Vector3(0.25,1.15,-0.52),Vector3(0.14,0.14,0.64),Color("192c38"))
	bots.append(b)
	return b

func start_round(reset := false) -> void:
	if reset:
		round_no = 1
		kills = 0
		headshots = 0
		shots = 0
		hits = 0
	for b in bots:
		if is_instance_valid(b): b.queue_free()
	bots.clear()
	player.position = Vector3(0,0.2,22)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	cam.position = Vector3(0,1.65,0)
	cam.rotation = Vector3.ZERO
	pitch = 0
	ammo = 25
	reserve = 100
	health = 100
	armor = 50
	reload_time = 0
	dash_cd = 0
	scan_cd = 0
	scan_time = 0
	fire_cd = 0.3
	dash_time = 0
	damage_flash = 0
	defuse = 0
	time_left = 110
	round_kills = 0
	feed.clear()
	state = "play"
	var positions := [Vector3(-5,0,-15),Vector3(6,0,-10),Vector3(-18,0,-18),Vector3(18,0,-16),Vector3(0,0,-22),Vector3(-18,0,5),Vector3(18,0,11)]
	for i in range(3+round_no): spawn_bot(positions[i],i)
	mouse_guard = 0.18
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	message("OPERAÇÃO %02d  /  ELIMINE OS SENTINELAS" % round_no,3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.keycode == KEY_ESCAPE:
			if state=="play":
				state="pause"
				Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			elif state=="pause": resume()
		if event.keycode == KEY_ENTER:
			activate()
		if event.keycode == KEY_MINUS: sensitivity=maxf(0.0006,sensitivity-0.0002)
		if event.keycode == KEY_EQUAL: sensitivity=minf(0.006,sensitivity+0.0002)
		if event.keycode == KEY_M: AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		if state=="play":
			if event.keycode == KEY_R: reload_gun()
			if event.keycode == KEY_Q and dash_cd<=0:
				dash_time=0.16
				dash_cd=7
				sound("dash")
			if event.keycode == KEY_E and scan_cd<=0:
				scan_cd=16
				scan_time=5
				sound("scan")
				message("PULSO ATIVO  /  ALVOS REVELADOS",2)
	if event is InputEventMouseMotion and state=="play" and mouse_guard<=0:
		player.rotation.y -= event.relative.x*sensitivity
		pitch = clampf(pitch-event.relative.y*sensitivity,-1.4,1.4)
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and state!="play":
		var p: Vector2 = event.position / get_viewport().get_visible_rect().size * Vector2(1600,900)
		if Rect2(100,655,390,66).has_point(p): activate()
		if Rect2(100,737,390,45).has_point(p):
			if state=="menu": get_tree().quit()
			else:
				state="menu"
				Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func activate() -> void:
	if state=="menu" or state=="lose" or state=="victory": start_round(true)
	elif state=="pause": resume()
	elif state=="round_win":
		round_no+=1
		start_round()

func resume() -> void:
	state="play"
	mouse_guard=0.18
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _physics_process(dt: float) -> void:
	if state!="play": return
	time_left-=dt
	if time_left<=0:
		finish(false)
		return
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var direction: Vector3 = player.basis * Vector3(input.x,0,input.y)
	var speed := 5.6
	if Input.is_physical_key_pressed(KEY_SHIFT): speed=2.6
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): speed=3.3
	if dash_time>0:
		speed=24
		if direction.length()<0.1: direction=-player.basis.z
	player.velocity.x=direction.x*speed
	player.velocity.z=direction.z*speed
	player.velocity.y-=22*dt
	if Input.is_physical_key_pressed(KEY_SPACE) and player.is_on_floor(): player.velocity.y=7
	player.move_and_slide()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): shoot()
	update_defuse(dt,Input.is_physical_key_pressed(KEY_F))

func update_defuse(dt: float,holding: bool) -> void:
	var close: bool = player.position.distance_to(reactor.position)<2.8
	if close and bots.is_empty() and holding:
		defuse+=dt
		if defuse>=4: finish(true)
	else: defuse=maxf(0,defuse-dt*0.5)

func _process(dt: float) -> void:
	elapsed+=dt
	mouse_guard=maxf(0,mouse_guard-dt)
	ring.rotation.y+=dt
	ring.position.y=1.7+sin(elapsed*2)*0.09
	if state=="menu":
		player.position=Vector3.ZERO
		player.rotation=Vector3.ZERO
		cam.position=Vector3(18*cos(elapsed*0.045),12,20)
		cam.look_at(Vector3(0,0,-4))
		gun.visible=false
	else: gun.visible=true
	if state=="play":
		fire_cd=maxf(0,fire_cd-dt)
		dash_cd=maxf(0,dash_cd-dt)
		scan_cd=maxf(0,scan_cd-dt)
		scan_time=maxf(0,scan_time-dt)
		dash_time=maxf(0,dash_time-dt)
		hit_time=maxf(0,hit_time-dt)
		damage_flash=maxf(0,damage_flash-dt*1.8)
		notice_time=maxf(0,notice_time-dt)
		recoil=lerpf(recoil,0,dt*9)
		cam.rotation.x=pitch+recoil*0.1
		var ads := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		cam.fov=lerpf(cam.fov,64 if ads else 85,dt*10)
		var sway := sin(elapsed*10)*minf(player.velocity.length(),6)*0.0015
		gun.position=gun.position.lerp(Vector3(0.05 if ads else 0.31,-0.26+sway,-0.5+recoil*0.12),dt*15)
		gun.rotation.x=-recoil*0.25
		gun.rotation.z=sin(reload_time*5)*0.4 if reload_time>0 else 0.0
		flash.visible=fire_cd>0.085
		if reload_time>0:
			reload_time-=dt
			if reload_time<=0:
				var take := mini(25-ammo,reserve)
				ammo+=take
				reserve-=take
		for i in range(feed.size()-1,-1,-1):
			feed[i].time-=dt
			if feed[i].time<=0: feed.remove_at(i)
	for i in range(effects.size()-1,-1,-1):
		effects[i].time-=dt
		if effects[i].time<=0:
			effects[i].node.queue_free()
			effects.remove_at(i)
	hud.queue_redraw()

func shoot() -> void:
	if fire_cd>0 or reload_time>0 or defuse>0.1: return
	if ammo<=0:
		reload_gun()
		return
	ammo-=1
	shots+=1
	fire_cd=0.115
	recoil=minf(1.1,recoil+0.32)
	sound("shot",-7)
	var spread := 0.0015+minf(player.velocity.length(),6)*0.0018+recoil*0.006
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): spread*=0.5
	var dir := -cam.global_basis.z+cam.global_basis.x*randf_range(-spread,spread)+cam.global_basis.y*randf_range(-spread,spread)
	var from := cam.global_position
	var to := from+dir*90
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	query.exclude=[player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		to=result.position
		if result.collider is CharacterBody3D and result.collider in bots:
			hits+=1
			head_hit=to.y-result.collider.position.y>1.55
			hit_time=0.2
			result.collider.damage(110 if head_hit else 34,head_hit)
			sound("hit",-10)
		else:
			var mark := box(self,to,Vector3(0.06,0.06,0.06),Color("ffe4b5"),false,1)
			effects.append({"node":mark,"time":0.18})
	tracer(flash.global_position,to,Color("ffe2a1"))

func reload_gun() -> void:
	if reload_time<=0 and ammo<25 and reserve>0:
		reload_time=1.7
		sound("reload",-5)
	elif reserve<=0 and ammo==0:
		# Emergency magazine prevents an unwinnable mission.
		reserve=25
		reload_time=2.8
		message("CARREGADOR DE EMERGÊNCIA",2)

func tracer(from: Vector3,to: Vector3,color: Color) -> void:
	var length := from.distance_to(to)
	if length<0.01: return
	var m := box(self,(from+to)*0.5,Vector3(0.015,0.015,length),color,false,1)
	m.look_at(to)
	effects.append({"node":m,"time":0.055})

func killed(bot: CharacterBody3D,head: bool) -> void:
	bots.erase(bot)
	kills+=1
	round_kills+=1
	if head: headshots+=1
	reserve=mini(reserve+15,125)
	feed.push_front({"text":"VOCÊ   /   "+("HEADSHOT" if head else "SENTINELA"),"time":4.0})
	if feed.size()>4: feed.pop_back()
	sound("kill",-5)
	for j in range(6):
		var p: Vector3=bot.position+Vector3(randf_range(-0.4,0.4),randf_range(0.2,1.8),randf_range(-0.4,0.4))
		var fragment := box(self,p,Vector3(0.12,0.12,0.12),Color("ffb08d"),false,1)
		effects.append({"node":fragment,"time":0.3})
	if bots.is_empty(): message("ÁREA LIMPA  /  SEGURE F NO REATOR",5)

func damage_player(amount: float) -> void:
	if test_mode: return
	var absorbed := minf(armor,amount*0.65)
	armor-=absorbed
	health-=amount-absorbed
	damage_flash=0.5
	sound("hurt",-16)
	if health<=0: finish(false)

func finish(win: bool) -> void:
	state = ("victory" if round_no>=3 else "round_win") if win else "lose"
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	sound("win" if win else "alarm")

func message(t: String,duration: float) -> void:
	notice=t
	notice_time=duration

func sound(id: String,volume := 0.0) -> void:
	if not audio.has(id): return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream=audio[id]
	p.volume_db=volume
	p.play()
	p.finished.connect(p.queue_free)

func _smoke_test() -> void:
	start_round(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(bots.size()==4)
	assert(ammo==25)
	fire_cd=0
	shoot()
	assert(ammo==24)
	reload_gun()
	assert(reload_time>0)
	await get_tree().create_timer(2).timeout
	assert(ammo==25)
	for b in bots.duplicate(): b.damage(110,true)
	assert(bots.is_empty())
	assert(kills==4)
	finish(true)
	assert(state=="round_win")
	activate()
	assert(round_no==2 and bots.size()==5)
	finish(false)
	assert(state=="lose")
	start_round(true)
	for b in bots.duplicate():
		bots.erase(b)
		b.queue_free()
	await get_tree().physics_frame
	var target := spawn_bot(Vector3(0,0,18),0)
	target.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	cam.look_at(target.position+Vector3(0,1.78,0))
	fire_cd=0
	shoot()
	assert(bots.is_empty(), "Headshot ray must eliminate target")
	assert(headshots==1)
	test_mode=false
	damage_player(20)
	assert(is_equal_approx(armor,37))
	assert(is_equal_approx(health,93))
	test_mode=true
	player.position=reactor.position+Vector3(0,0,2)
	defuse=0
	update_defuse(2,true)
	assert(is_equal_approx(defuse,2))
	update_defuse(1,false)
	assert(is_equal_approx(defuse,1.5))
	update_defuse(2.5,true)
	assert(state=="round_win")
	for r in [1,2,3]:
		round_no=r
		finish(true)
		assert(state==("victory" if r==3 else "round_win"))
	await get_tree().create_timer(1.5).timeout
	print("SMOKE_TEST_PASS: spawn, wall ray, reload, kills, headshot ray, armor damage, timed defuse, all round outcomes")
	get_tree().quit()
