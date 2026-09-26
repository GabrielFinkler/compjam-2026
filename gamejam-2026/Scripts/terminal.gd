extends Area2D
## Computador interativo: com o jogador perto, mostra "[E] ACESSAR". Ao apertar E,
## abre a porta ligada a ele (uma vez só) e mostra um aviso embaixo da tela.
## Coloque o nó em cima de um computador do cenário e escolha a Porta no Inspector.

@export var porta: Node ## Porta que este computador libera
@export var mensagem: String = "PORTA LIBERADA!"
@export var mensagem_parcial: String = "TRAVA LIBERADA! FALTAM %d." ## Usada quando a porta tem mais travas; %d = quantas faltam
@export var texto_prompt: String = "[E] ACESSAR"

const Aviso := preload("res://Scripts/aviso.gd")
const COR_LED_ATIVO := Color(0.15, 0.68, 0.88)
const COR_LED_USADO := Color(0.23, 1.0, 0.43)

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
	var texto := mensagem
	if porta and porta.has_method("abrir"):
		porta.abrir()
		# Porta com várias travas (ex.: precisa de dois terminais): avisa quantas faltam
		if "travas_restantes" in porta and porta.travas_restantes > 0:
			texto = mensagem_parcial % porta.travas_restantes
	Aviso.mostrar(self, texto, COR_LED_ATIVO)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = true
		_prompt.visible = not _usado

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = false
		_prompt.visible = false
