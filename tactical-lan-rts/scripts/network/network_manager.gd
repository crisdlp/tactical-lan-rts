extends Node3D

const PORT := 7000
const SOLDIER_SCENE := preload("res://scenes/units/soldier.tscn")

@onready var units_container: Node3D = $Units
@onready var lan_menu: CanvasLayer = $LANMenu
@onready var host_button: Button = $LANMenu/VBoxContainer/HostButton
@onready var join_button: Button = $LANMenu/VBoxContainer/JoinButton
@onready var ip_input: LineEdit = $LANMenu/VBoxContainer/IPInput

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 2) # Máximo 2 jugadores
	if err != OK:
		push_error("Error al crear servidor: ", err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	lan_menu.visible = false
	# Generar el escuadrón del Host (ID 1) en el lado sur del mapa
	_spawn_squad(1, Vector3(-4, 0, 10))

func _on_join_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var ip := ip_input.text.strip_edges()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Error al conectar a ", ip)
		return
	multiplayer.multiplayer_peer = peer
	lan_menu.visible = false

func _on_peer_connected(peer_id: int) -> void:
	# Cuando entra el Cliente, el Host genera su escuadrón en el lado norte
	if multiplayer.is_server():
		_spawn_squad(peer_id, Vector3(-4, 0, -10))

func _spawn_squad(player_id: int, start_pos: Vector3) -> void:
	for i in range(5):
		var soldier := SOLDIER_SCENE.instantiate()
		soldier.name = "Soldier_%d_%d" % [player_id, i]
		soldier.owner_id = player_id
		soldier.position = start_pos + Vector3(i * 2.0, 0, 0)
		units_container.add_child(soldier, true)
