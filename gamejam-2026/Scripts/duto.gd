extends Area2D
## Duto de ventilação: com o jogador perto, [E] entra e ele sai no duto de destino.
## Monstros não usam os dutos: é um atalho e também uma rota de fuga (quem te persegue
## perde você de vista e vai procurar onde te viu por último).
## Ligue dois dutos apontando um para o outro no Inspector (ou só ida, se quiser).

@export var destino: Node2D ## Duto (ou qualquer ponto) onde o jogador sai
@export var texto_prompt: String = "[E] DUTO"
@export var tempo_escuro: float = 0.35 ## Duração do escurecimento na ida e na volta
## Chama atenção pro duto (quando a fase depende dele): LED maior pulsando, brilho forte em
## volta e uma plaquinha "DUTO" boiando em cima. Apaga depois do primeiro uso.
@export var destaque: bool = false

const COR_LED := Color(0.4, 0.85, 1.0)
const ESPERA_REUSO := 0.8 # Evita que o jogador volte sem querer ao chegar
const ENERGIA_DESTAQUE := 1.8 # Pico do brilho em volta do duto em destaque

@onready var _prompt: Label = $Prompt
@onready var _led: ColorRect = $Led

var _jogador: Node2D
var _jogador_perto: bool = false
var _em_uso: bool = false
var _bloqueado_ate: float = 0.0
var _destaque_nos: Array[Node] = [] # Brilho e plaquinha: somem depois do 1º uso
var _pulso_destaque: Tween


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
	if destaque:
		_criar_destaque()


func _criar_destaque() -> void:
	# LED do tamanho do dos terminais, crescendo e encolhendo
	_led.offset_left = -2
	_led.offset_top = -2
	_led.offset_right = 2
	_led.offset_bottom = 2
	_led.pivot_offset = Vector2(2, 2)

	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	var brilho := PointLight2D.new()
	brilho.texture = textura
	brilho.texture_scale = 1.3 # ~40 px de raio: dá pra ver de longe no escuro
	brilho.color = COR_LED
	brilho.energy = 0.4
	add_child(brilho)

	var placa := Label.new()
	placa.text = "DUTO"
	placa.theme = _prompt.theme
	placa.material = _prompt.material # Brilha sozinha, igual ao prompt
	placa.z_index = 5
	placa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placa.add_theme_color_override("font_color", COR_LED)
	placa.add_theme_color_override("font_outline_color", Color.BLACK)
	placa.add_theme_constant_override("outline_size", 3)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.position = Vector2(-48, -30)
	placa.size = Vector2(96, 10)
	add_child(placa)

	_pulso_destaque = create_tween().set_loops()
	_pulso_destaque.tween_property(brilho, "energy", ENERGIA_DESTAQUE, 0.6).set_trans(Tween.TRANS_SINE)
	_pulso_destaque.parallel().tween_property(_led, "scale", Vector2(1.6, 1.6), 0.6).set_trans(Tween.TRANS_SINE)
	_pulso_destaque.parallel().tween_property(placa, "position:y", -34.0, 0.6).set_trans(Tween.TRANS_SINE)
	_pulso_destaque.tween_property(brilho, "energy", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
	_pulso_destaque.parallel().tween_property(_led, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	_pulso_destaque.parallel().tween_property(placa, "position:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE)
	_destaque_nos = [brilho, placa]


func _apagar_destaque() -> void:
	if _destaque_nos.is_empty():
		return
	_pulso_destaque.kill()
	for no in _destaque_nos:
		no.queue_free()
	_destaque_nos.clear()
	_led.scale = Vector2.ONE


func _unhandled_input(event: InputEvent) -> void:
	if _jogador_perto and not _em_uso and destino and event.is_action_pressed("interagir"):
		if Time.get_ticks_msec() / 1000.0 < _bloqueado_ate or _jogador.controle_bloqueado:
			return
		get_viewport().set_input_as_handled()
		_atravessar()


func _atravessar() -> void:
	_em_uso = true
	_apagar_destaque()
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
		_mostrar_placa(false) # O prompt "[E] DUTO" aparece no mesmo lugar da plaquinha


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = false
		_prompt.visible = false
		_mostrar_placa(true)


func _mostrar_placa(mostrar: bool) -> void:
	for no in _destaque_nos:
		if no is Label:
			no.visible = mostrar
