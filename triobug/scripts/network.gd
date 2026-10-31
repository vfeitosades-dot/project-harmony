extends Node
class_name TrioNetwork

## ENet transport. Game simulation and every shared puzzle stay on peer 1.
## Commands: x/y (-1..1), yaw (radians), optional pitch, jump/run/ability/
## interact/regroup (booleans), switch (-1 for no request, otherwise 0..2).
## A host may call try_switch() after receiving a validated command.
signal roster_changed(roster: Dictionary)
signal session_started()
signal disconnected(reason: String)
signal status_changed(message: String)
signal command_received(peer_id: int, command: Dictionary)
signal snapshot_received(state: Dictionary)
signal restart_requested(peer_id: int)

const DEFAULT_PORT: int = 24569
const CONNECTION_TIMEOUT_MS: int = 8000
const MAX_COMMANDS_PER_SECOND: int = 120

var roster: Dictionary = {}
var local_robot: int = 0
var is_host: bool = false
var online: bool = false
var started: bool = false
var round_id: int = 0
var _connecting: bool = false
var _connect_started_ms: int = 0
var _rates: Dictionary = {}
var _signals_connected: bool = false
var _restart_requests: Dictionary = {}


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta: float) -> void:
	if _connecting and Time.get_ticks_msec() - _connect_started_ms >= CONNECTION_TIMEOUT_MS:
		_fail("O host não respondeu em 8 segundos. A sala pode estar cheia; confira o IP e a porta UDP.")


func host_game(port: int = DEFAULT_PORT) -> Error:
	leave_game()
	_connect_signals()
	if port < 1024 or port > 65535:
		status_changed.emit("Use uma porta entre 1024 e 65535.")
		return ERR_INVALID_PARAMETER
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_server(port, 2)
	if result != OK:
		peer.close()
		status_changed.emit("Não foi possível hospedar. A porta UDP pode estar ocupada.")
		return result
	multiplayer.multiplayer_peer = peer
	is_host = true
	online = true
	roster = {1: 0}
	local_robot = 0
	roster_changed.emit(roster.duplicate())
	status_changed.emit("Sala aberta • UDP %d • aguardando até 2 amigos." % port)
	return OK


func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	leave_game()
	_connect_signals()
	var host_address: String = address.strip_edges()
	if not _valid_address(host_address) or port < 1024 or port > 65535:
		status_changed.emit("Endereço ou porta inválidos. Exemplo: 192.168.1.10 / 24569.")
		return ERR_INVALID_PARAMETER
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_client(host_address, port)
	if result != OK:
		peer.close()
		status_changed.emit("Não foi possível conectar ao endereço informado.")
		return result
	multiplayer.multiplayer_peer = peer
	is_host = false
	online = true
	_connecting = true
	_connect_started_ms = Time.get_ticks_msec()
	status_changed.emit("Conectando a %s:%d…" % [host_address, port])
	return OK


func _valid_address(address: String) -> bool:
	if address.is_empty() or address.length() > 253:
		return false
	if address.is_valid_ip_address():
		return true
	# Ordinary DNS hostnames only; no URLs, paths, whitespace or command text.
	var hostname: RegEx = RegEx.new()
	hostname.compile("^(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$")
	if hostname.search(address) == null:
		return false
	# Do not treat a malformed dotted IPv4 address as a hostname.
	var numeric: RegEx = RegEx.new()
	numeric.compile("^[0-9.]+$")
	return numeric.search(address) == null


func start_game() -> void:
	if not online or not is_host or started:
		return
	started = true
	round_id += 1
	_start_session.rpc(round_id)
	session_started.emit()


func restart_game() -> void:
	if not online or not started:
		return
	if is_host:
		round_id += 1
		_restart_session.rpc(round_id)
		session_started.emit()
	elif not _connecting and multiplayer.get_peers().has(1):
		_request_restart.rpc_id(1)


func send_command(command: Dictionary) -> void:
	if not online:
		return
	var clean: Dictionary = _validated_command(command)
	if clean.is_empty():
		return
	if is_host:
		command_received.emit(1, clean)
	elif not _connecting and multiplayer.get_peers().has(1):
		if bool(clean.jump) or bool(clean.ability) or bool(clean.interact) or bool(clean.regroup) or int(clean.switch) >= 0:
			_receive_action.rpc_id(1, clean)
		else:
			_receive_command.rpc_id(1, clean)


func send_snapshot(state: Dictionary) -> void:
	if online and is_host and not roster.is_empty() and multiplayer.get_peers().size() > 0:
		var envelope: Dictionary = state.duplicate()
		envelope["_round"] = round_id
		_receive_snapshot.rpc(envelope)


func try_switch(peer_id: int, preferred: int = -1) -> int:
	if not is_host or not roster.has(peer_id):
		return -1
	var current: int = int(roster[peer_id])
	var desired: int = preferred
	if desired < 0:
		for offset: int in range(1, 4):
			var candidate: int = (current + offset) % 3
			if not roster.values().has(candidate):
				desired = candidate
				break
	if desired < 0 or desired > 2:
		return current
	for other: Variant in roster:
		if int(other) != peer_id and int(roster[other]) == desired:
			return current
	roster[peer_id] = desired
	_publish_roster()
	return desired


func leave_game() -> void:
	_connecting = false
	online = false
	is_host = false
	started = false
	round_id = 0
	roster.clear()
	_rates.clear()
	_restart_requests.clear()
	local_robot = 0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _validated_command(command: Dictionary) -> Dictionary:
	if command.size() > 14:
		return {}
	var allowed: Array[String] = ["x", "y", "yaw", "pitch", "jump", "run", "ability", "interact", "switch", "regroup"]
	for key: Variant in command:
		if not key is String or not allowed.has(str(key)):
			return {}
	var clean: Dictionary = {}
	for key: String in ["x", "y", "yaw", "pitch"]:
		var value: Variant = command.get(key, 0.0)
		if not (value is float or value is int):
			return {}
		var number: float = float(value)
		if not is_finite(number):
			return {}
		if key == "x" or key == "y":
			if absf(number) > 1.001:
				return {}
			clean[key] = clampf(number, -1.0, 1.0)
		elif key == "yaw":
			if absf(number) > 10000.0:
				return {}
			clean[key] = wrapf(number, -PI, PI)
		else:
			clean[key] = clampf(number, -1.45, 1.45)
	for key: String in ["jump", "run", "ability", "interact", "regroup"]:
		var value: Variant = command.get(key, false)
		if not value is bool:
			return {}
		clean[key] = bool(value)
	var requested: Variant = command.get("switch", -1)
	if not requested is int or int(requested) < -1 or int(requested) > 2:
		return {}
	clean["switch"] = int(requested)
	return clean


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _receive_command(command: Dictionary) -> void:
	_accept_command(multiplayer.get_remote_sender_id(), command)


@rpc("any_peer", "call_remote", "reliable", 1)
func _receive_action(command: Dictionary) -> void:
	_accept_command(multiplayer.get_remote_sender_id(), command)


func _accept_command(sender: int, command: Dictionary) -> void:
	if not online or not is_host:
		return
	if not roster.has(sender):
		return
	var now: int = Time.get_ticks_msec()
	var rate: Vector2i = _rates.get(sender, Vector2i(now, 0))
	if now - rate.x >= 1000:
		rate = Vector2i(now, 0)
	rate.y += 1
	_rates[sender] = rate
	if rate.y > MAX_COMMANDS_PER_SECOND:
		return
	var clean: Dictionary = _validated_command(command)
	if not clean.is_empty():
		command_received.emit(sender, clean)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receive_snapshot(state: Dictionary) -> void:
	if online and not is_host and int(state.get("_round", -1)) == round_id:
		snapshot_received.emit(state)


@rpc("authority", "call_remote", "reliable", 0)
func _sync_roster(updated: Dictionary) -> void:
	if not online or is_host:
		return
	if updated.size() < 1 or updated.size() > 3:
		return
	var robots: Array[int] = []
	for peer: Variant in updated:
		if not peer is int or int(peer) < 1:
			return
		var robot: Variant = updated[peer]
		if not robot is int or int(robot) < 0 or int(robot) > 2 or robots.has(int(robot)):
			return
		robots.append(int(robot))
	roster = updated.duplicate()
	local_robot = int(roster.get(multiplayer.get_unique_id(), 0))
	roster_changed.emit(roster.duplicate())


@rpc("authority", "call_remote", "reliable", 0)
func _start_session(new_round: int) -> void:
	if not online or is_host or started:
		return
	started = true
	round_id = new_round
	_connecting = false
	session_started.emit()


@rpc("authority", "call_remote", "reliable", 0)
func _restart_session(new_round: int) -> void:
	if not online or is_host or new_round <= round_id:
		return
	started = true
	round_id = new_round
	_connecting = false
	session_started.emit()


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_restart() -> void:
	if not online or not is_host or not started:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if not roster.has(sender):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_restart_requests.get(sender, -2000)) < 1000:
		return
	_restart_requests[sender] = now
	# The game validates that this request is appropriate (for example, victory).
	restart_requested.emit(sender)


func _publish_roster() -> void:
	local_robot = int(roster.get(1, 0))
	if multiplayer.get_peers().size() > 0:
		_sync_roster.rpc(roster)
	roster_changed.emit(roster.duplicate())


func _on_peer_connected(peer_id: int) -> void:
	if not online or not is_host:
		return
	if roster.size() >= 3:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	var assigned: int = -1
	for candidate: int in range(3):
		if not roster.values().has(candidate):
			assigned = candidate
			break
	if assigned < 0:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	roster[peer_id] = assigned
	_publish_roster()
	status_changed.emit("Amigo conectado • %d/3 robôs." % roster.size())
	if started:
		_start_session.rpc_id(peer_id, round_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if not online or not is_host or not roster.has(peer_id):
		return
	roster.erase(peer_id)
	_rates.erase(peer_id)
	_restart_requests.erase(peer_id)
	_publish_roster()
	status_changed.emit("Um amigo desconectou. Seu robô pode ser assumido com TAB.")


func _on_connected() -> void:
	if not online or is_host:
		return
	_connecting = false
	status_changed.emit("Conectado. Aguardando o host iniciar a experiência.")


func _on_connection_failed() -> void:
	if online and not is_host:
		_fail("Falha na conexão: IP indisponível, sala cheia ou porta UDP bloqueada.")


func _on_server_disconnected() -> void:
	if online and not is_host:
		_fail("O host encerrou a partida ou a conexão foi perdida.")


func _fail(reason: String) -> void:
	leave_game()
	status_changed.emit(reason)
	disconnected.emit(reason)
