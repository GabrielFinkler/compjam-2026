extends CanvasLayer

## Interface de Usuário (HUD e Diálogos)
## Gerencia o objetivo atual, a dica de interação e as caixas de diálogo dos terminais.

@onready var objective_label: Label = $ObjectiveLabel
@onready var prompt_label: Label = $PromptLabel
@onready var dialog_panel: Panel = $DialogPanel
@onready var dialog_title: Label = $DialogPanel/VBox/TitleLabel
@onready var dialog_text: Label = $DialogPanel/VBox/TextLabel

var is_dialog_open: bool = false
var on_dialog_closed_callback: Callable


func _ready() -> void:
	prompt_label.visible = false
	dialog_panel.visible = false
	set_objective("1. Explore a Sala da Direita e acesse o PC Central.")


func _unhandled_input(event: InputEvent) -> void:
	if is_dialog_open:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			close_dialog()
			get_viewport().set_input_as_handled()


func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "📌 " + text


func show_prompt(text: String) -> void:
	if prompt_label and not is_dialog_open:
		prompt_label.text = "[E] " + text
		prompt_label.visible = true


func hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false


func show_dialog(title: String, text: String, callback: Callable = Callable()) -> void:
	is_dialog_open = true
	hide_prompt()
	on_dialog_closed_callback = callback
	if dialog_title:
		dialog_title.text = title
	if dialog_text:
		dialog_text.text = text
	if dialog_panel:
		dialog_panel.visible = true


func close_dialog() -> void:
	is_dialog_open = false
	if dialog_panel:
		dialog_panel.visible = false
	if on_dialog_closed_callback.is_valid():
		var cb := on_dialog_closed_callback
		on_dialog_closed_callback = Callable()
		cb.call()
