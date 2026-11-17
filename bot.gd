extends CharacterBody3D
var game: Node3D
var hp := 100.0
var shot_cd := 1.0
var path_cd := 0.0
var path: PackedVector2Array
var anim := 0.0
var number := 0
var limbs: Array[Node3D] = []
var torso: Node3D
var hurt := 0.0

func _physics_process(dt: float) -> void:
	if game.state != "play": return
	shot_cd -= dt
	path_cd -= dt
	hurt = maxf(0.0, hurt-dt)
	var target: Vector3 = game.player.position
	var offset: Vector3 = target-position
	var distance := offset.length()
	var origin := position+Vector3(0,1.55,0)
	var aim: Vector3 = game.cam.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, aim, 1)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var visible: bool = not result.is_empty() and result.collider == game.player
	var dir := Vector3.ZERO
	if distance > 10 or not visible:
		if path_cd <= 0:
			path_cd = 0.65+randf()*0.2
			path = game.nav.get_point_path(Vector2i(clampi(roundi(position.x),-21,21),clampi(roundi(position.z),-25,25)),Vector2i(clampi(roundi(target.x),-21,21),clampi(roundi(target.z),-25,25)))
		if path.size()>1:
			var p := Vector3(path[1].x,position.y,path[1].y)
			if position.distance_to(p)<0.65: path.remove_at(0)
			dir = (p-position).normalized()
	elif visible and distance>4:
		dir = Vector3(offset.z,0,-offset.x).normalized()*sin(anim*0.65+number)*0.45
	velocity.x = dir.x * (2.1+game.round_no*0.18)
	velocity.z = dir.z * (2.1+game.round_no*0.18)
	velocity.y -= 22*dt
	move_and_slide()
	anim += dt*7
	if offset.length()>0.1:
		torso.rotation.y = lerp_angle(torso.rotation.y,atan2(-offset.x,-offset.z),dt*8)
	for i in limbs.size():
		limbs[i].rotation.x = sin(anim+PI*(i%2))*minf(velocity.length()*0.13,0.5)
	if visible and shot_cd<=0 and distance<34:
		shot_cd = randf_range(0.8,1.45) / (1+game.round_no*0.06)
		game.tracer(origin,aim+Vector3(randf_range(-0.4,0.4),randf_range(-0.25,0.25),0),Color(1,0.28,0.19))
		if randf()>0.30+minf(game.player.velocity.length()*0.04,0.4):
			game.damage_player(randf_range(6,11))

func damage(amount: float, head: bool) -> void:
	hp -= amount
	hurt = 0.15
	if hp<=0:
		game.killed(self,head)
		queue_free()
