extends Area2D

## Script genérico para elementos interativos (Terminais, Botões, Saída)

signal interagiu

@export var prompt_mensagem: String = "Interagir"
@export var habilitado: bool = true

var player_dentro: bool = false
var hud: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	# Busca o HUD na cena
	await get_tree().process_frame
	hud = get_tree().root.find_child("HUD", true, false)


func _unhandled_input(event: InputEvent) -> void:
	if not habilitado or not player_dentro:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		acionar_interacao()
		get_viewport().set_input_as_handled()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Suporta clique com mouse se o player estiver perto
	if not habilitado or not player_dentro:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		acionar_interacao()


func acionar_interacao() -> void:
	if not habilitado:
		return
	interagiu.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Astronauta":
		player_dentro = true
		if habilitado and hud and hud.has_method("show_prompt"):
			hud.show_prompt(prompt_mensagem)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Astronauta":
		player_dentro = false
		if hud and hud.has_method("hide_prompt"):
			hud.hide_prompt()
