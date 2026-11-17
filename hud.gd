extends Control
var game: Node3D
var font: Font = ThemeDB.fallback_font
var white := Color("e7efe9")
var muted := Color("90a9b0")
var teal := Color("6df4d3")
var red := Color("ff796c")
var ink := Color("101e2a")

func rect(x: float,y: float,w: float,h: float,c: Color) -> void:
	draw_rect(Rect2(x,y,w,h),c)
func text(t: String,x: float,y: float,size: int=20,c: Color=Color("e7efe9")) -> void:
	draw_string(font,Vector2(x,y),t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func center(t: String,x: float,y: float,size: int=20,c: Color=Color("e7efe9")) -> void:
	text(t,x-font.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,y,size,c)
func line(a: Vector2,b: Vector2,c: Color,width:=1.0) -> void:
	draw_line(a,b,c,width,true)

func _draw() -> void:
	if not is_instance_valid(game): return
	draw_set_transform(Vector2.ZERO,0,get_viewport_rect().size/Vector2(1600,900))
	if game.state=="play":
		_draw_hud()
	else:
		_draw_menu()
	text("VERTICE  /  PROTOCOLO ZERO",1280,878,13,Color(0.75,0.88,0.88,0.65))

func _draw_menu() -> void:
	# Broad dark panel and a restrained technical grid over the live arena.
	rect(0,0,1600,900,Color(0.025,0.065,0.095,0.52))
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(790,0),Vector2(650,900),Vector2(0,900)]),PackedColorArray([Color(0.035,0.075,0.11,0.96)]))
	for x in range(0,760,40): line(Vector2(x,0),Vector2(x,900),Color(0.2,0.4,0.43,0.07))
	for y in range(0,900,40): line(Vector2(0,y),Vector2(700,y),Color(0.2,0.4,0.43,0.07))
	rect(100,90,42,5,teal)
	text("V /  TACTICAL SYSTEMS",160,100,17,teal)
	text("01 — OFFLINE SOLO",100,166,16,muted)
	var title := "VÉRTICE"
	var subtitle := "P R O T O C O L O   Z E R O"
	var button := "INICIAR OPERAÇÃO"
	var description := "Entre. Neutralize. Desarme."
	if game.state=="pause":
		title="EM PAUSA"
		subtitle="O P E R A Ç Ã O   S U S P E N S A"
		button="CONTINUAR"
		description="Respire. A missão espera por você."
	elif game.state=="round_win":
		title="ÁREA SEGURA"
		subtitle="R E A T O R   D E S A R M A D O"
		button="PRÓXIMA OPERAÇÃO"
		description="Bom trabalho. O próximo setor está em alerta."
	elif game.state=="victory":
		title="MISSÃO CUMPRIDA"
		subtitle="T R Ê S   S E T O R E S   S E G U R O S"
		button="JOGAR NOVAMENTE"
		description="Protocolo Zero concluído. Você está no controle."
	elif game.state=="lose":
		title="SINAL PERDIDO"
		subtitle="O P E R A Ç Ã O   E N C E R R A D A"
		button="TENTAR NOVAMENTE"
		description="Tempo esgotado." if game.time_left<=0 else "Os sentinelas interromperam a operação."
	text(title,94,272,82 if game.state=="menu" else 46,white)
	text(subtitle,100,318,18,teal)
	line(Vector2(100,350),Vector2(570,350),Color("38505a"))
	text(description,100,395,21,white)
	if game.state in ["menu","pause"]:
		text("Um FPS tático em uma instalação à beira do colapso.",100,433,16,muted)
		text("Elimine os sentinelas e desarme o reator antes do tempo.",100,459,16,muted)
		var controls := [["W A S D","MOVER"],["MOUSE","MIRAR / ATIRAR"],["Q  /  E","DASH / PULSO"],["F","DESARMAR"]]
		for i in controls.size():
			var x: float=100+(i%2)*250
			var y: float=510+floori(i/2.0)*53
			text(controls[i][0],x,y,16,teal)
			text(controls[i][1],x,y+22,13,muted)
	else:
		text("RELATÓRIO DE CAMPO",100,454,15,muted)
		text(str(game.kills),100,521,46,teal)
		text(str(game.headshots),270,521,46,teal)
		text(str(roundi(100.0*game.hits/maxi(1,game.shots)))+"%",445,521,46,teal)
		text("ELIMINAÇÕES",100,550,12,muted)
		text("HEADSHOTS",270,550,12,muted)
		text("PRECISÃO",445,550,12,muted)
	var p := get_global_mouse_position()/get_viewport_rect().size*Vector2(1600,900)
	var hover := Rect2(100,655,390,66).has_point(p)
	rect(100,655,390,66,Color("a0ffe6") if hover else teal)
	text(button,125,697,20,ink)
	text("↗",445,700,26,ink)
	text("ENTER",515,695,14,muted)
	text("SAIR DO JOGO" if game.state=="menu" else "VOLTAR AO MENU",100,767,15,muted)
	text("F11  TELA CHEIA     M  SOM     − / +  SENSIBILIDADE",100,843,12,muted)
	# Mission card on the right.
	rect(1100,90,400,45,Color(0.03,0.1,0.13,0.8))
	draw_circle(Vector2(1122,112),4,teal)
	text("SISTEMA ONLINE",1138,118,14,teal)
	text("BUILD 01",1406,118,13,muted)
	text("A",1130,547,110,Color(0.85,0.96,0.91,0.8))
	text("O P E R A Ç Ã O   /   0 7",1135,588,14,teal)
	text("ESTAÇÃO AURORA",1130,629,27,white)
	line(Vector2(1135,650),Vector2(1500,650),muted)
	text("3 OPERAÇÕES   /   110s POR SETOR",1135,682,14,white)
	text("RIFLE V-25    •    DASH    •    PULSO",1135,711,13,muted)
	text("ARTE E MODELOS ORIGINAIS",1135,797,12,muted)
	text("GODOT 4  /  WINDOWS x64",1135,820,12,muted)

func _draw_hud() -> void:
	# Top objective and operation counter.
	rect(610,26,380,74,Color(0.035,0.075,0.11,0.9))
	rect(610,26,4,74,teal)
	center("OPERAÇÃO  %02d / 03" % game.round_no,800,51,14,muted)
	var seconds := maxi(0,ceili(game.time_left))
	center("%02d:%02d" % [seconds/60,seconds%60],800,87,31,red if seconds<25 else white)
	text("AURORA / SETOR A",46,38,15,white)
	_draw_radar()
	text("%02d  SENTINELAS" % game.bots.size(),46,291,16,red if game.bots.size()>0 else teal)
	text("LIMPE A ÁREA" if not game.bots.is_empty() else "DESARME O REATOR",46,317,12,muted)
	for i in game.feed.size():
		rect(1260,45+i*39,300,32,Color(0.04,0.1,0.14,0.88))
		rect(1260,45+i*39,3,32,teal)
		text(game.feed[i].text,1275,67+i*39,14,white)
	if game.notice_time>0:
		rect(490,130,620,42,Color(0.035,0.075,0.11,0.86))
		center(game.notice,800,157,16,teal)
	# Context and objective marker.
	var point: Vector3=game.reactor.global_position+Vector3(0,2.8,0)
	if not game.cam.is_position_behind(point):
		var screen: Vector2=game.cam.unproject_position(point)/get_viewport_rect().size*Vector2(1600,900)
		if screen.x>300 and screen.x<1400 and screen.y>180 and screen.y<700:
			draw_circle(screen,16,Color(0.03,0.1,0.14,0.8))
			center("A",screen.x,screen.y+6,17,teal)
			center(str(roundi(game.player.position.distance_to(game.reactor.position)))+"m",screen.x,screen.y+36,13,white)
	# Scan projections only while the ability is active.
	if game.scan_time>0:
		for b in game.bots:
			if game.cam.is_position_behind(b.position): continue
			var p: Vector2=game.cam.unproject_position(b.position+Vector3(0,2.2,0))/get_viewport_rect().size*Vector2(1600,900)
			if p.x>0 and p.x<1600 and p.y>0 and p.y<900:
				draw_polyline(PackedVector2Array([p+Vector2(-7,0),p+Vector2(0,7),p+Vector2(7,0),p+Vector2(0,-7),p+Vector2(-7,0)]),red,2,true)
		center("PULSO  /  %.1fs" % game.scan_time,800,208,14,teal)
	var gap: float = 5.0+game.recoil*9+minf(game.player.velocity.length(),6)
	var c := teal
	for dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		line(Vector2(800,450)+dir*gap,Vector2(800,450)+dir*(gap+7),Color(0.02,0.07,0.08,0.8),4)
		line(Vector2(800,450)+dir*gap,Vector2(800,450)+dir*(gap+7),c,2)
	draw_circle(Vector2(800,450),1.5,white)
	if game.hit_time>0:
		var hc := red if game.head_hit else white
		for d in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]: line(Vector2(800,450)+d*10,Vector2(800,450)+d*18,hc,2)
		if game.head_hit: center("HEADSHOT",800,498,14,red)
	var close: bool=game.player.position.distance_to(game.reactor.position)<2.8
	if close:
		center("ELIMINE OS SENTINELAS PRIMEIRO" if not game.bots.is_empty() else "SEGURE [ F ] PARA DESARMAR",800,603,17,white)
	if game.defuse>0:
		rect(650,622,300,7,ink)
		rect(650,622,300*game.defuse/4,7,teal)
		center("DESARMANDO",800,657,13,teal)
	# Bottom information panels.
	rect(35,779,350,85,Color(0.035,0.075,0.11,0.88))
	rect(35,779,4,85,teal)
	text("+",58,834,33,teal)
	text(str(maxi(0,ceili(game.health))),96,838,44,white)
	text("VIDA",98,855,10,muted)
	line(Vector2(214,797),Vector2(214,847),Color("3a535d"))
	text(str(ceili(game.armor)),240,834,32,white)
	text("ESCUDO",240,853,10,muted)
	rect(58,786,303,3,Color("314550"))
	rect(58,786,303*maxf(0,game.health)/100,3,teal if game.health>30 else red)
	ability(638,"Q","DASH",game.dash_cd,7)
	ability(811,"E","PULSO",game.scan_cd,16)
	rect(1230,779,335,85,Color(0.035,0.075,0.11,0.88))
	text("V-25  /  RIFLE",1253,800,12,muted)
	text(str(game.ammo),1250,847,46,red if game.ammo<6 else white)
	text("/ "+str(game.reserve),1330,844,24,muted)
	text("R",1515,840,20,teal)
	if game.reload_time>0:
		center("RECARREGANDO",800,704,14,white)
		rect(700,717,200,3,ink)
		rect(700,717,200*(1-clampf(game.reload_time/1.7,0,1)),3,teal)
	text("SHIFT  ANDAR   •   ESPAÇO  PULAR   •   BOTÃO DIREITO  MIRAR   •   ESC  PAUSA",420,882,11,muted)
	if game.damage_flash>0:
		var alpha: float=game.damage_flash*0.4
		rect(0,0,1600,12,Color(1,0.2,0.15,alpha))
		rect(0,888,1600,12,Color(1,0.2,0.15,alpha))
		rect(0,0,12,900,Color(1,0.2,0.15,alpha))
		rect(1588,0,12,900,Color(1,0.2,0.15,alpha))
		center("▲",800,360,25,Color(1,0.3,0.2,game.damage_flash*2))

func ability(x: float,key: String,title: String,cooldown: float,total: float) -> void:
	rect(x,787,150,72,Color(0.035,0.075,0.11,0.9))
	rect(x,787,150*(1-cooldown/total),3,teal if cooldown<=0 else muted)
	rect(x+12,806,28,28,Color("2c4751"))
	center(key,x+26,827,18,white)
	text(title if cooldown<=0 else "%ds" % ceili(cooldown),x+53,825,17,teal if cooldown<=0 else muted)
	text("PRONTO" if cooldown<=0 else "RECARGA",x+53,845,10,muted)

func _draw_radar() -> void:
	rect(40,54,205,217,Color(0.035,0.075,0.11,0.91))
	var scale := 3.6
	var origin := Vector2(142.5,160)
	for r in game.obstacles:
		var pos: Vector2=origin+r.position*scale
		draw_rect(Rect2(pos,r.size*scale),Color("3c555c"))
	var rp: Vector2=origin+Vector2(0,-3.5)*scale
	draw_circle(rp,6,teal)
	center("A",rp.x,rp.y+4,10,ink)
	for b in game.bots:
		if game.scan_time>0 or b.position.distance_to(game.player.position)<9:
			draw_circle(origin+Vector2(b.position.x,b.position.z)*scale,3.8,red)
	var p: Vector2=origin+Vector2(game.player.position.x,game.player.position.z)*scale
	var forward := Vector2(-sin(game.player.rotation.y),-cos(game.player.rotation.y))
	var side := Vector2(-forward.y,forward.x)
	draw_polygon(PackedVector2Array([p+forward*8,p-forward*5+side*5,p-forward*5-side*5]),PackedColorArray([white]))
	text("N",230,71,10,muted)
