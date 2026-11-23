extends Control

@onready var camera: Camera3D = $"../CameraRig/Camera3D"

var selected_units: Array[CharacterBody3D] = []
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Clic izquierdo: iniciar selección
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start = event.position
				drag_end = event.position
			else:
				is_dragging = false
				if drag_start.distance_to(drag_end) < 10.0:
					_select_single_unit(event.position)
				else:
					_select_units_in_box()
				queue_redraw()
				
		# Clic derecho: dar orden de movimiento
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_command_move(event.position)

	elif event is InputEventMouseMotion and is_dragging:
		drag_end = event.position
		queue_redraw()

func _draw() -> void:
	if is_dragging:
		var rect := Rect2(drag_start, drag_end - drag_start).abs()
		draw_rect(rect, Color(0.2, 0.8, 0.2, 0.2), true)
		draw_rect(rect, Color(0.2, 0.8, 0.2, 0.8), false, 2.0)

func _deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.set_selected(false)
	selected_units.clear()

func _select_single_unit(mouse_pos: Vector2) -> void:
	_deselect_all()
	var result := _raycast_from_mouse(mouse_pos)
	if result and result.collider.is_in_group("units"):
		if result.collider.owner_id == multiplayer.get_unique_id():
			result.collider.set_selected(true)
			selected_units.append(result.collider)

func _select_units_in_box() -> void:
	_deselect_all()
	var box := Rect2(drag_start, drag_end - drag_start).abs()
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.owner_id != multiplayer.get_unique_id():
			continue
		var screen_pos := camera.unproject_position(unit.global_position)
		if box.has_point(screen_pos):
			unit.set_selected(true)
			selected_units.append(unit)

func _command_move(mouse_pos: Vector2) -> void:
	if selected_units.is_empty():
		return
	var result := _raycast_from_mouse(mouse_pos)
	if result:
		var base_pos: Vector3 = result.position
		var spacing := 1.8
		for i in range(selected_units.size()):
			var offset := Vector3((i % 3) * spacing, 0, (i / 3) * spacing)
			# Enviar la orden al Host (ID 1) por red
			selected_units[i].request_move.rpc_id(1, base_pos + offset)

func _raycast_from_mouse(mouse_pos: Vector2) -> Dictionary:
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
