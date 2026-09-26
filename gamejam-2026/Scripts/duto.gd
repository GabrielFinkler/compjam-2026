extends Area2D
## Duto de ventilação: com o jogador perto, [E] entra e ele sai no duto de destino.
## Monstros não usam os dutos: é um atalho e também uma rota de fuga (quem te persegue
## perde você de vista e vai procurar onde te viu por último).
## Ligue dois dutos apontando um para o outro no Inspector (ou só ida, se quiser).

@export var destino: Node2D ## Duto (ou qualquer ponto) onde o jogador sai
@export var texto_prompt: String = "[E] DUTO"
@export var tempo_escuro: float = 0.35 ## Duração do escurecimento na ida e na volta

const COR_LED := Color(0.4, 0.85, 1.0)
const ESPERA_REUSO := 0.8 # Evita que o jogador volte sem querer ao chegar

@onready var _prompt: Label = $Prompt
@onready var _led: ColorRect = $Led

var _jogador: Node2D
var _jogador_perto: bool = false
var _em_uso: bool = false
var _bloqueado_ate: float = 0.0


func _ready() -> void:
	_prompt.theme = preload("res://Scripts/tema_pixel.gd").criar()
	_prompt.text = texto_prompt
	_prompt.visible = false
	_led.color = COR_LED
	var pisca := create_tween().set_loops()
	pisca.tween_property(_led, "modulate:a", 0.25, 0.9)
	pisca.tween_property(_led, "modulate:a", 1.0, 0.9)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _jogador_perto and not _em_uso and destino and event.is_action_pressed("interagir"):
		if Time.get_ticks_msec() / 1000.0 < _bloqueado_ate or _jogador.controle_bloqueado:
			return
		get_viewport().set_input_as_handled()
		_atravessar()


func _atravessar() -> void:
	_em_uso = true
	var jogador := _jogador
	jogador.controle_bloqueado = true
	var camada := CanvasLayer.new()
	camada.layer = 50
	add_child(camada)
	var tela := ColorRect.new()
	tela.color = Color(0, 0, 0, 0)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(tela, "color:a", 1.0, tempo_escuro)
	tween.tween_callback(func():
		jogador.global_position = destino.global_position
		if destino.has_method("bloquear_reuso"):
			destino.bloquear_reuso()
		var camera := jogador.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.reset_smoothing()
	)
	tween.tween_property(tela, "color:a", 0.0, tempo_escuro)
	tween.tween_callback(func():
		jogador.controle_bloqueado = false
		camada.queue_free()
		_em_uso = false
	)


## Chamado pelo duto de origem quando o jogador chega aqui.
func bloquear_reuso() -> void:
	_bloqueado_ate = Time.get_ticks_msec() / 1000.0 + ESPERA_REUSO


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador = body
		_jogador_perto = true
		_prompt.visible = destino != null


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = false
		_prompt.visible = false
