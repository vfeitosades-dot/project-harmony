extends CanvasLayer
class_name TrioInterface

signal solo_requested()
signal host_requested(port: int)
signal join_requested(address: String, port: int)
signal start_requested()
signal resume_requested()
signal menu_requested()
signal restart_requested()
signal regroup_requested()
signal settings_changed(settings: Dictionary)

const NAVY: Color = Color("0c1322")
const PANEL: Color = Color("172539")
const WHITE: Color = Color("edf5ff")
const MUTED: Color = Color("9db0c6")
const CYAN: Color = Color("42e3d2")
const YELLOW: Color = Color("ffd166")
const CORAL: Color = Color("ff6b82")
const ROBOT_NAMES: Array[String] = ["BIPO", "GRAVI", "LIGA"]
const SKILL_NAMES: Array[String] = ["MAGNETISMO", "CAMPO GRAVITACIONAL", "CONEXÃO ELÁSTICA"]
const ROBOT_COLORS: Array[Color] = [YELLOW, CYAN, CORAL]

var screen: String = "menu"
var online_session: bool = false
var settings: Dictionary = {"resolution": Vector2i(1280, 720), "fullscreen": false, "vsync": true, "low_graphics": false, "sensitivity": 0.6, "volume": 0.65}
var _root: Control
var _status: Label
var _toast: Label
var _toast_time: float = 0.0
var _robot_label: Label
var _skill_label: Label
var _stage_label: Label
var _objective_label: Label
var _prompt_label: Label
var _cooldown_label: Label
var _progress_label: Label
var _session_label: Label
var _cooldown_bar: ProgressBar
var _return_from_settings: String = "menu"
var _last_lobby_host: bool = false
var _last_lobby_count: int = 1
var _last_lobby_status: String = ""
var _theme: Theme
var _credits_text: String = ""

func _ready() -> void:
	_make_theme()
	_root = Control.new()
	_root.name = "TrioInterfaceRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _theme
	add_child(_root)
	show_menu()

func _process(delta: float) -> void:
	if _toast_time > 0.0 and is_instance_valid(_toast):
		_toast_time = maxf(0.0, _toast_time - delta)
		_toast.modulate.a = minf(1.0, _toast_time)

func _style(color: Color, border_color: Color = Color.TRANSPARENT, radius: int = 16) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border_color
	box.set_border_width_all(1 if border_color.a > 0.0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 22.0
	box.content_margin_right = 22.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	return box

func _make_theme() -> void:
	_theme = Theme.new()
	_theme.default_font_size = 17
	_theme.set_color("font_color", "Label", WHITE)
	_theme.set_color("font_color", "Button", WHITE)
	_theme.set_color("font_hover_color", "Button", NAVY)
	_theme.set_color("font_pressed_color", "Button", NAVY)
	_theme.set_color("font_focus_color", "Button", WHITE)
	_theme.set_stylebox("normal", "Button", _style(Color("24364b"), Color("38526b"), 11))
	_theme.set_stylebox("hover", "Button", _style(CYAN, CYAN, 11))
	_theme.set_stylebox("pressed", "Button", _style(Color("2abfaf"), CYAN, 11))
	_theme.set_stylebox("focus", "Button", _style(Color(0,0,0,0), CYAN, 11))
	_theme.set_stylebox("disabled", "Button", _style(Color("172439"), Color("2e4056"), 11))
	_theme.set_color("font_disabled_color", "Button", MUTED)
	_theme.set_stylebox("normal", "LineEdit", _style(Color("0c1728"), Color("38526b"), 9))
	_theme.set_stylebox("focus", "LineEdit", _style(Color("0c1728"), CYAN, 9))
	_theme.set_color("font_color", "LineEdit", WHITE)
	_theme.set_color("caret_color", "LineEdit", CYAN)
	_theme.set_stylebox("panel", "PanelContainer", _style(Color(0.047, 0.075, 0.133, 0.94), Color("2e4056"), 20))
	_theme.set_stylebox("panel", "AcceptDialog", _style(PANEL, Color("38526b"), 12))
	var dialog_border: StyleBoxFlat = ThemeDB.get_default_theme().get_stylebox("embedded_border", "Window").duplicate() as StyleBoxFlat
	if dialog_border != null:
		dialog_border.bg_color = PANEL
		dialog_border.border_color = CYAN
		_theme.set_stylebox("embedded_border", "Window", dialog_border)
	_theme.set_color("title_color", "Window", WHITE)
	_theme.set_stylebox("background", "ProgressBar", _style(Color("24364b"), Color.TRANSPARENT, 4))
	_theme.set_stylebox("fill", "ProgressBar", _style(CYAN, Color.TRANSPARENT, 4))

func _clear(next_screen: String, darken: bool = true) -> void:
	screen = next_screen
	for child: Node in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	_toast_time = 0.0
	if darken:
		var shade: ColorRect = ColorRect.new()
		shade.color = Color(0.025, 0.045, 0.08, 0.58)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(shade)
	_status = _label("", 15, YELLOW)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -38.0
	_status.offset_bottom = -10.0
	_status.offset_left = 24.0
	_status.offset_right = -24.0
	_root.add_child(_status)
	_toast = _label("", 18, CYAN)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -440.0
	_toast.offset_right = 440.0
	_toast.offset_top = 110.0
	_toast.offset_bottom = 144.0
	_toast.modulate.a = 0.0
	_root.add_child(_toast)

func _label(value: String, size: int = 18, color: Color = WHITE) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String, callback: Callable, parent: Node, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0.0, 47.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if primary:
		button.add_theme_stylebox_override("normal", _style(CYAN, CYAN, 11))
		button.add_theme_color_override("font_color", NAVY)
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void:
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "modulate", Color(1.07, 1.07, 1.07), 0.12)
	)
	button.mouse_exited.connect(func() -> void:
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "modulate", Color.WHITE, 0.12)
	)
	parent.add_child(button)
	return button

func _panel(width: float, height: float, left: bool = false) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	if left:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		panel.offset_left = 45.0
		panel.offset_right = 45.0 + width
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.offset_left = -width * 0.5
		panel.offset_right = width * 0.5
	panel.offset_top = -height * 0.5
	panel.offset_bottom = height * 0.5
	_root.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column

func _space(parent: Node, height: float) -> void:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)

func _heading(column: VBoxContainer, eyebrow: String, title: String, description: String = "") -> void:
	column.add_child(_label(eyebrow, 13, CYAN))
	column.add_child(_label(title, 34))
	if not description.is_empty():
		var desc: Label = _label(description, 16, MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(desc)
	_space(column, 5.0)

func show_menu() -> void:
	online_session = false
	_clear("menu", false)
	var column: VBoxContainer = _panel(450.0, 640.0, true)
	column.add_theme_constant_override("separation", 8)
	column.add_child(_label("BETA  /  LABORATÓRIO ZERO", 13, CYAN))
	var title: Label = _label("TRIOBUG", 64)
	column.add_child(title)
	column.add_child(_label("AMIGOS EM PANE!", 23, YELLOW))
	var desc: Label = _label("Três robôs. Uma fuga.\nA física está por sua conta.", 18, MUTED)
	column.add_child(desc)
	_space(column, 10.0)
	_button("JOGAR SOLO    →", func() -> void: solo_requested.emit(), column, true)
	_button("HOSPEDAR PARTIDA", _show_host, column)
	_button("ENTRAR EM PARTIDA", _show_join, column)
	_button("CONFIGURAÇÕES", _show_settings, column)
	_button("SAIR", func() -> void: get_tree().quit(), column)
	column.add_child(_label("1–3 jogadores  •  Solo ou rede local / IP direto", 12, MUTED))
	var license_link: LinkButton = LinkButton.new()
	license_link.text = "Créditos e licenças"
	license_link.add_theme_font_size_override("font_size", 13)
	license_link.add_theme_color_override("font_color", CYAN)
	license_link.add_theme_color_override("font_hover_color", WHITE)
	license_link.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	license_link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	license_link.pressed.connect(show_credits)
	column.add_child(license_link)
	var note: Label = _label("03 UNIDADES\n01 PLANO DE FUGA.", 27, WHITE)
	note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	note.offset_left = -435.0
	note.offset_right = -46.0
	note.offset_top = -160.0
	note.offset_bottom = -82.0
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(note)
	var credits: Label = _label("BIPO   /   GRAVI   /   LIGA", 14, CYAN)
	credits.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credits.offset_left = -430.0
	credits.offset_right = -46.0
	credits.offset_top = -76.0
	credits.offset_bottom = -48.0
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(credits)

func show_credits() -> void:
	_clear("credits")
	var column: VBoxContainer = _panel(1100.0, 620.0)
	_heading(column, "TRIOBUG / BETA", "Créditos e licenças", "Código original: MIT. Malhas procedurais e áudio sintetizado originais: CC0. Engine e componentes mantêm suas próprias licenças.")
	var content: RichTextLabel = RichTextLabel.new()
	content.bbcode_enabled = false
	content.scroll_active = true
	content.selection_enabled = true
	content.custom_minimum_size.y = 360.0
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 14)
	content.add_theme_color_override("default_color", MUTED)
	if _credits_text.is_empty():
		_credits_text = _build_credits_text()
	content.text = _credits_text
	column.add_child(content)
	_button("VOLTAR AO MENU    →", show_menu, column, true)

func _build_credits_text() -> String:
	var text: String = "TRIOBUG: AMIGOS EM PANE!\nLaboratório Zero — Beta\n\nOs personagens, cenários e sons desta beta são originais, construídos por código e síntese de áudio.\n\n"
	if FileAccess.file_exists("res://LICENSE"):
		text += "CÓDIGO-FONTE ORIGINAL\n" + FileAccess.get_file_as_string("res://LICENSE") + "\n\n"
	if FileAccess.file_exists("res://licenses/ORIGINAL-ASSETS-CC0.txt"):
		text += "RECURSOS VISUAIS E ÁUDIO ORIGINAIS\n" + FileAccess.get_file_as_string("res://licenses/ORIGINAL-ASSETS-CC0.txt") + "\n\n"
	text += "GODOT ENGINE " + str(Engine.get_version_info().get("string", "")) + "\nhttps://godotengine.org\n\n" + Engine.get_license_text() + "\n\n"
	text += "LICENÇAS DOS COMPONENTES DA ENGINE\n\n"
	var license_info: Dictionary = Engine.get_license_info()
	var names: Array = license_info.keys()
	names.sort()
	for license_name: Variant in names:
		text += str(license_name) + "\n" + str(license_info[license_name]) + "\n\n"
	if FileAccess.file_exists("res://licenses/GODOT-COPYRIGHT.txt"):
		text += "AVISOS COMPLETOS DE COPYRIGHT DA GODOT E COMPONENTES\n\n" + FileAccess.get_file_as_string("res://licenses/GODOT-COPYRIGHT.txt")
	return text

func _port_field(parent: Node) -> SpinBox:
	parent.add_child(_label("PORTA UDP", 13, MUTED))
	var port: SpinBox = SpinBox.new()
	port.min_value = 1024.0
	port.max_value = 65535.0
	port.step = 1.0
	port.value = 24569.0
	port.custom_minimum_size.y = 44.0
	parent.add_child(port)
	return port

func _show_host() -> void:
	_clear("host")
	var column: VBoxContainer = _panel(520.0, 400.0)
	_heading(column, "MULTIPLAYER / 1–3 JOGADORES", "Hospedar partida", "Seu computador será o servidor. Seus amigos usam seu IP local e a mesma porta UDP.")
	var port: SpinBox = _port_field(column)
	_space(column, 9.0)
	_button("CRIAR SESSÃO    →", func() -> void: host_requested.emit(int(port.value)), column, true)
	_button("VOLTAR", show_menu, column)

func _show_join() -> void:
	_clear("join")
	var column: VBoxContainer = _panel(520.0, 480.0)
	_heading(column, "MULTIPLAYER / LAN OU IP DIRETO", "Entrar em partida", "Peça o IP do host. Fora da rede local, a conexão pode exigir configuração de rede.")
	column.add_child(_label("ENDEREÇO DO HOST", 13, MUTED))
	var address: LineEdit = LineEdit.new()
	address.placeholder_text = "Ex.: 192.168.1.25"
	address.text = "127.0.0.1"
	address.max_length = 253
	address.custom_minimum_size.y = 46.0
	column.add_child(address)
	var port: SpinBox = _port_field(column)
	_space(column, 8.0)
	_button("CONECTAR    →", func() -> void: join_requested.emit(address.text.strip_edges(), int(port.value)), column, true)
	_button("VOLTAR", show_menu, column)
	address.text_submitted.connect(func(_text: String) -> void: join_requested.emit(address.text.strip_edges(), int(port.value)))
	address.grab_focus()

func show_lobby(is_host: bool, count: int, status: String) -> void:
	online_session = true
	_last_lobby_host = is_host
	_last_lobby_count = count
	_last_lobby_status = status
	_clear("lobby")
	var column: VBoxContainer = _panel(540.0, 425.0)
	_heading(column, "SESSÃO LOCAL / IP DIRETO", "Equipe em formação", "Cada unidade tem uma habilidade. Com menos de três jogadores, TAB troca para um módulo disponível.")
	var participants: Label = _label("%d / 3  UNIDADES CONECTADAS" % clampi(count, 1, 3), 24, CYAN)
	column.add_child(participants)
	column.add_child(_label("BIPO  ·  GRAVI  ·  LIGA", 18, YELLOW))
	var info: Label = _label(status, 16, MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(info)
	_space(column, 12.0)
	if is_host:
		_button("INICIAR EXPERIMENTO    →", func() -> void: start_requested.emit(), column, true)
	else:
		column.add_child(_label("Aguardando o host iniciar o experimento…", 17, CYAN))
	_button("DESCONECTAR / VOLTAR", _request_menu, column)

func show_hud() -> void:
	_clear("hud", false)
	var top_left: PanelContainer = PanelContainer.new()
	top_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	top_left.offset_left = 24.0
	top_left.offset_top = 23.0
	top_left.offset_right = 324.0
	top_left.offset_bottom = 112.0
	_root.add_child(top_left)
	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 3)
	top_left.add_child(left_column)
	_robot_label = _label("●  BIPO", 24, YELLOW)
	left_column.add_child(_robot_label)
	_skill_label = _label("MAGNETISMO", 12, MUTED)
	left_column.add_child(_skill_label)
	var top_right: PanelContainer = PanelContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -438.0
	top_right.offset_right = -24.0
	top_right.offset_top = 23.0
	top_right.offset_bottom = 122.0
	_root.add_child(top_right)
	var right_column: VBoxContainer = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 4)
	top_right.add_child(right_column)
	_stage_label = _label("01  /  O DESPERTAR", 13, CYAN)
	right_column.add_child(_stage_label)
	_objective_label = _label("Encontre a saída do laboratório.", 16)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_column.add_child(_objective_label)
	_progress_label = _label("", 13, MUTED)
	right_column.add_child(_progress_label)
	var crosshair: Label = _label("+", 23, Color(0.93,0.97,1.0,0.7))
	crosshair.add_theme_color_override("font_outline_color", Color(0.02,0.035,0.06,0.9))
	crosshair.add_theme_constant_override("outline_size", 4)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -12.0
	crosshair.offset_right = 12.0
	crosshair.offset_top = -18.0
	crosshair.offset_bottom = 18.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(crosshair)
	_prompt_label = _label("", 18, WHITE)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = -480.0
	_prompt_label.offset_right = 480.0
	_prompt_label.offset_top = -182.0
	_prompt_label.offset_bottom = -146.0
	_root.add_child(_prompt_label)
	var ability_panel: PanelContainer = PanelContainer.new()
	ability_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ability_panel.offset_left = -205.0
	ability_panel.offset_right = 205.0
	ability_panel.offset_top = -128.0
	ability_panel.offset_bottom = -58.0
	_root.add_child(ability_panel)
	var ability_column: VBoxContainer = VBoxContainer.new()
	ability_column.add_theme_constant_override("separation", 5)
	ability_panel.add_child(ability_column)
	_cooldown_label = _label("CLIQUE  •  USAR HABILIDADE", 14, CYAN)
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_column.add_child(_cooldown_label)
	_cooldown_bar = ProgressBar.new()
	_cooldown_bar.min_value = 0.0
	_cooldown_bar.max_value = 1.0
	_cooldown_bar.value = 1.0
	_cooldown_bar.show_percentage = false
	_cooldown_bar.custom_minimum_size.y = 5.0
	ability_column.add_child(_cooldown_bar)
	var controls: Label = _label("WASD  mover     MOUSE  câmera     ESPAÇO  pular     SHIFT  correr     E  interagir     TAB  trocar     R  checkpoint     ESC  pausa", 12, MUTED)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_top = -35.0
	controls.offset_bottom = -11.0
	controls.offset_left = 20.0
	controls.offset_right = -20.0
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(controls)
	_session_label = _label("SOLO", 12, MUTED)
	_session_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_session_label.offset_left = 27.0
	_session_label.offset_top = -78.0
	_session_label.offset_right = 250.0
	_session_label.offset_bottom = -51.0
	_root.add_child(_session_label)
	_status.offset_top = -230.0
	_status.offset_bottom = -202.0

func update_hud(robot_index: int, stage: int, objective: String, prompt: String, cooldown: float, progress: String, players_count: int) -> void:
	if screen != "hud" or not is_instance_valid(_robot_label):
		return
	var index: int = clampi(robot_index, 0, 2)
	_robot_label.text = "●  " + ROBOT_NAMES[index]
	_robot_label.add_theme_color_override("font_color", ROBOT_COLORS[index])
	_skill_label.text = SKILL_NAMES[index]
	var stages: Array[String] = ["O DESPERTAR", "GRAVIDADE QUEBRADA", "O NÚCLEO CENTRAL", "SAÍDA LIBERADA"]
	var stage_index: int = clampi(stage, 0, 3)
	_stage_label.text = "%02d  /  %s" % [stage_index + 1, stages[stage_index]]
	_objective_label.text = objective
	_prompt_label.text = prompt
	_progress_label.text = progress
	_session_label.text = "SOLO  /  TAB TROCA DE ROBÔ" if players_count <= 1 else "%d / 3  UNIDADES CONECTADAS" % players_count
	_cooldown_label.text = "RECARREGANDO  %.1f s" % cooldown if cooldown > 0.05 else "CLIQUE  •  " + SKILL_NAMES[index]
	_cooldown_label.add_theme_color_override("font_color", MUTED if cooldown > 0.05 else ROBOT_COLORS[index])
	_cooldown_bar.value = clampf(1.0 - cooldown / 7.0, 0.0, 1.0)

func show_pause() -> void:
	_clear("pause")
	var column: VBoxContainer = _panel(480.0, 467.0)
	_heading(column, "EXPERIMENTO EM ESPERA", "Uma pequena pane.", "Os outros jogadores continuam em ação." if online_session else "Seu experimento está pausado. Respire, a física pode esperar.")
	_button("CONTINUAR    →", func() -> void: resume_requested.emit(), column, true)
	_button("VOLTAR AO CHECKPOINT", func() -> void: regroup_requested.emit(), column)
	_button("CONFIGURAÇÕES", _show_settings, column)
	_button("VOLTAR AO MENU", _request_menu, column)

func show_victory(seconds: float) -> void:
	_clear("victory")
	var column: VBoxContainer = _panel(650.0, 440.0)
	_heading(column, "LABORATÓRIO ZERO / ESCAPE CONFIRMADO", "EXPERIMENTO CONCLUÍDO", "…OU QUASE.")
	column.add_child(_label("Três habilidades. Uma equipe. Nenhum manual.", 21, CYAN))
	var minutes: int = int(maxf(seconds, 0.0)) / 60
	var remaining: int = int(maxf(seconds, 0.0)) % 60
	column.add_child(_label("TEMPO DE FUGA     %02d:%02d" % [minutes, remaining], 17, YELLOW))
	_space(column, 17.0)
	_button("JOGAR NOVAMENTE    →", func() -> void: restart_requested.emit(), column, true)
	_button("VOLTAR AO MENU", _request_menu, column)

func set_online(value: bool) -> void:
	online_session = value

func _request_menu() -> void:
	if not online_session:
		menu_requested.emit()
		return
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Sair da sessão?"
	dialog.dialog_text = "Você será desconectado da partida.\nSe você hospeda, a sessão será encerrada para todos."
	dialog.ok_button_text = "Sair da sessão"
	dialog.cancel_button_text = "Continuar jogando"
	dialog.confirmed.connect(func() -> void: menu_requested.emit())
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	_root.add_child(dialog)
	dialog.popup_centered(Vector2i(520, 180))

func _settings_row(column: VBoxContainer, text: String, control: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var label: Label = _label(text, 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	control.custom_minimum_size.x = 205.0
	row.add_child(control)
	column.add_child(row)

func _setting_changed(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit(settings.duplicate())

func _show_settings() -> void:
	_return_from_settings = screen
	_clear("settings")
	var column: VBoxContainer = _panel(620.0, 530.0)
	_heading(column, "AJUSTES / BETA", "Configurações", "Ajustes são aplicados imediatamente.")
	var resolution: OptionButton = OptionButton.new()
	resolution.add_item("1280 × 720")
	resolution.add_item("1920 × 1080")
	resolution.select(1 if settings["resolution"] == Vector2i(1920,1080) else 0)
	resolution.item_selected.connect(func(index: int) -> void: _setting_changed("resolution", Vector2i(1920,1080) if index == 1 else Vector2i(1280,720)))
	_settings_row(column, "Resolução da janela", resolution)
	var fullscreen: CheckButton = CheckButton.new()
	fullscreen.button_pressed = bool(settings["fullscreen"])
	fullscreen.text = "Ativada" if fullscreen.button_pressed else "Desativada"
	fullscreen.toggled.connect(func(value: bool) -> void:
		fullscreen.text = "Ativada" if value else "Desativada"
		_setting_changed("fullscreen", value)
	)
	_settings_row(column, "Tela cheia", fullscreen)
	var vsync: CheckButton = CheckButton.new()
	vsync.button_pressed = bool(settings["vsync"])
	vsync.text = "Ativado" if vsync.button_pressed else "Desativado"
	vsync.toggled.connect(func(value: bool) -> void:
		vsync.text = "Ativado" if value else "Desativado"
		_setting_changed("vsync", value)
	)
	_settings_row(column, "VSync", vsync)
	var low_graphics: CheckButton = CheckButton.new()
	low_graphics.button_pressed = bool(settings["low_graphics"])
	low_graphics.text = "Ativado" if low_graphics.button_pressed else "Desativado"
	low_graphics.toggled.connect(func(value: bool) -> void:
		low_graphics.text = "Ativado" if value else "Desativado"
		_setting_changed("low_graphics", value)
	)
	_settings_row(column, "Modo gráfico leve", low_graphics)
	var sensitivity: HSlider = HSlider.new()
	sensitivity.min_value = 0.1
	sensitivity.max_value = 2.0
	sensitivity.step = 0.05
	sensitivity.value = float(settings["sensitivity"])
	sensitivity.value_changed.connect(func(value: float) -> void: _setting_changed("sensitivity", value))
	_settings_row(column, "Sensibilidade do mouse", sensitivity)
	var volume: HSlider = HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(settings["volume"])
	volume.value_changed.connect(func(value: float) -> void: _setting_changed("volume", value))
	_settings_row(column, "Volume geral", volume)
	_space(column, 10.0)
	_button("VOLTAR    →", _close_settings, column, true)

func _close_settings() -> void:
	if _return_from_settings == "pause":
		show_pause()
	elif _return_from_settings == "lobby":
		show_lobby(_last_lobby_host, _last_lobby_count, _last_lobby_status)
	else:
		show_menu()

func set_status(text: String) -> void:
	if is_instance_valid(_status):
		_status.text = text

func toast(message: String) -> void:
	if is_instance_valid(_toast):
		_toast.text = message
		_toast.modulate.a = 1.0
		_toast_time = 4.5
