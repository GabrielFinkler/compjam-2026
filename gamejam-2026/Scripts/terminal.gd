extends Area2D
## Computador interativo: com o jogador perto, mostra "[E] ACESSAR". Ao apertar E,
## abre a porta ligada a ele (uma vez só) e mostra um aviso embaixo da tela.
## Coloque o nó em cima de um computador do cenário e escolha a Porta no Inspector.

@export var porta: Node ## Porta que este computador libera
@export var mensagem: String = "PORTA LIBERADA!"
@export var texto_prompt: String = "[E] ACESSAR"

const COR_LED_ATIVO := Color(0.15, 0.68, 0.88)
const COR_LED_USADO := Color(0.23, 1.0, 0.43)
const TEMPO_AVISO := 3.0

@onready var _prompt: Label = $Prompt
@onready var _led: ColorRect = $Led

var _jogador_perto: bool = false
var _usado: bool = false
var _pisca: Tween

func _ready() -> void:
	_prompt.theme = preload("res://Scripts/tema_pixel.gd").criar()
	_prompt.text = texto_prompt
	_prompt.visible = false
	_led.color = COR_LED_ATIVO
	# LED piscando pra dar pra achar o computador no escuro
	_pisca = create_tween().set_loops()
	_pisca.tween_property(_led, "modulate:a", 0.2, 0.5)
	_pisca.tween_property(_led, "modulate:a", 1.0, 0.5)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _jogador_perto and not _usado and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		usar()

func usar() -> void:
	_usado = true
	_prompt.visible = false
	_pisca.kill()
	_led.modulate.a = 1.0
	_led.color = COR_LED_USADO
	if porta and porta.has_method("abrir"):
		porta.abrir()
	_mostrar_aviso()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = true
		_prompt.visible = not _usado

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = false
		_prompt.visible = false

func _mostrar_aviso() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var centro := CenterContainer.new()
	camada.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	centro.offset_top = -40
	centro.offset_bottom = -12
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.75)
	estilo.border_color = COR_LED_ATIVO
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(6)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.theme = preload("res://Scripts/tema_pixel.gd").criar()
	centro.add_child(painel)
	var texto := Label.new()
	texto.text = mensagem
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel.add_child(texto)
	var tween := create_tween()
	tween.tween_interval(TEMPO_AVISO)
	tween.tween_property(painel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(camada.queue_free)
