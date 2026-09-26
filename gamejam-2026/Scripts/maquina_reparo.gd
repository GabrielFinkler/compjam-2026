extends Area2D
## Máquina de reparo com minigame de "skill check" (estilo Dead by Daylight).
## Com o jogador perto, [E] começa o reparo: o personagem fica parado, um ponteiro gira
## num círculo e é preciso apertar ESPAÇO quando ele passar pela zona clara.
## Acertando todas as checagens, a porta ligada é liberada. Errar (ou deixar o ponteiro
## passar) gasta energia da lanterna e zera o reparo. [E] de novo desiste sem penalidade.
## Coloque o nó em cima de uma máquina do cenário e escolha a Porta no Inspector.

signal concluida

@export var porta: Node ## Porta que esta máquina libera
@export var checagens: int = 3
@export var mensagem: String = "ENERGIA RESTAURADA! PORTA LIBERADA!"
@export var texto_prompt: String = "[E] REPARAR"
@export var penalidade_energia: float = 10.0 ## Energia da lanterna perdida a cada erro
@export var tempo_volta: float = 1.2 ## Segundos pro ponteiro dar uma volta na 1ª checagem
@export var aceleracao_por_checagem: float = 0.2 ## Cada checagem seguinte gira 20% mais rápido
@export var largura_zona_graus: float = 55.0 ## Tamanho da zona de acerto na 1ª checagem
@export var reducao_zona_graus: float = 10.0 ## Quanto a zona encolhe a cada checagem

enum Estado { PARADO, ESPERANDO, GIRANDO }

const Aviso := preload("res://Scripts/aviso.gd")
const COR_LED_ATIVO := Color(1.0, 0.75, 0.2)
const COR_LED_USADO := Color(0.23, 1.0, 0.43)
const COR_ERRO := Color(1.0, 0.25, 0.2)
const LARGURA_ZONA_MINIMA := 18.0
const MARGEM_PASSOU := 6.0 # Graus depois da zona até contar como "deixou passar"

@onready var _prompt: Label = $Prompt
@onready var _led: ColorRect = $Led

var _jogador: Node2D
var _jogador_perto: bool = false
var _usado: bool = false
var _estado: Estado = Estado.PARADO
var _acertos: int = 0
var _espera: float = 0.0
var _angulo: float = 0.0 # Graus, 0 = topo, sentido horário
var _zona_inicio: float = 0.0
var _zona_fim: float = 0.0
var _pisca: Tween
var _camada: CanvasLayer
var _mostrador: Mostrador


func _ready() -> void:
	_prompt.theme = preload("res://Scripts/tema_pixel.gd").criar()
	_prompt.text = texto_prompt
	_prompt.visible = false
	_led.color = COR_LED_ATIVO
	_pisca = create_tween().set_loops()
	_pisca.tween_property(_led, "modulate:a", 0.2, 0.4)
	_pisca.tween_property(_led, "modulate:a", 1.0, 0.4)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_criar_interface()


func _unhandled_input(event: InputEvent) -> void:
	if _usado:
		return
	if event.is_action_pressed("interagir") and (_jogador_perto or _estado != Estado.PARADO):
		get_viewport().set_input_as_handled()
		if _estado == Estado.PARADO:
			_iniciar()
		else:
			_encerrar() # Desistiu: perde o progresso, sem penalidade
	elif event.is_action_pressed("skill_check") and _estado != Estado.PARADO:
		get_viewport().set_input_as_handled()
		if _estado == Estado.GIRANDO:
			if _angulo >= _zona_inicio and _angulo <= _zona_fim:
				_acertar()
			else:
				_errar()


func _process(delta: float) -> void:
	match _estado:
		Estado.ESPERANDO:
			_espera -= delta
			if _espera <= 0.0:
				_estado = Estado.GIRANDO
		Estado.GIRANDO:
			var velocidade := 360.0 / tempo_volta * (1.0 + aceleracao_por_checagem * _acertos)
			_angulo += velocidade * delta
			if _angulo > _zona_fim + MARGEM_PASSOU:
				_errar()
	if _estado != Estado.PARADO:
		_mostrador.atualizar(_angulo, _zona_inicio, _zona_fim, _estado == Estado.GIRANDO, _acertos, checagens)


func _iniciar() -> void:
	_acertos = 0
	_prompt.visible = false
	_jogador.controle_bloqueado = true
	_camada.visible = true
	_mostrador.modulate = Color.WHITE
	_proxima_checagem()


func _proxima_checagem() -> void:
	_estado = Estado.ESPERANDO
	_espera = randf_range(0.5, 1.1) # Imprevisível, como no DbD
	_angulo = 0.0
	var largura := maxf(largura_zona_graus - reducao_zona_graus * _acertos, LARGURA_ZONA_MINIMA)
	_zona_inicio = randf_range(110.0, 320.0 - largura)
	_zona_fim = _zona_inicio + largura


func _acertar() -> void:
	_acertos += 1
	_piscar_mostrador(COR_LED_USADO)
	if _acertos >= checagens:
		_concluir()
	else:
		_proxima_checagem()


func _errar() -> void:
	_piscar_mostrador(COR_ERRO)
	if _jogador and "energia_atual" in _jogador:
		_jogador.energia_atual = maxf(_jogador.energia_atual - penalidade_energia, 0.0)
	Aviso.mostrar(self, "CURTO-CIRCUITO! -%d DE ENERGIA. TENTE DE NOVO." % int(penalidade_energia), COR_ERRO, 2.0)
	_encerrar()


func _concluir() -> void:
	_usado = true
	_encerrar()
	_pisca.kill()
	_led.modulate.a = 1.0
	_led.color = COR_LED_USADO
	if porta and porta.has_method("abrir"):
		porta.abrir()
	Aviso.mostrar(self, mensagem, COR_LED_USADO)
	concluida.emit()


func _encerrar() -> void:
	_estado = Estado.PARADO
	if _jogador:
		_jogador.controle_bloqueado = false
	# Some depois do flash de acerto/erro
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func(): _camada.visible = _estado != Estado.PARADO)
	_prompt.visible = _jogador_perto and not _usado


func _piscar_mostrador(cor: Color) -> void:
	_mostrador.modulate = cor
	create_tween().tween_property(_mostrador, "modulate", Color.WHITE, 0.3)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador = body
		_jogador_perto = true
		_prompt.visible = not _usado and _estado == Estado.PARADO


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		_jogador_perto = false
		_prompt.visible = false


func _criar_interface() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 20
	_camada.visible = false
	add_child(_camada)
	_mostrador = Mostrador.new()
	_mostrador.theme = preload("res://Scripts/tema_pixel.gd").criar()
	_camada.add_child(_mostrador)


## Círculo do skill check, desenhado na tela (fora da escuridão do cenário).
class Mostrador extends Control:
	const RAIO := 22.0
	var angulo: float = 0.0
	var zona_inicio: float = 0.0
	var zona_fim: float = 0.0
	var girando: bool = false
	var acertos: int = 0
	var total: int = 3
	var _texto: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_texto = Label.new()
		_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_texto.position = Vector2(-60, RAIO + 16)
		_texto.size = Vector2(120, 10)
		add_child(_texto)

	func atualizar(novo_angulo: float, inicio: float, fim: float, esta_girando: bool, novos_acertos: int, novo_total: int) -> void:
		position = get_viewport_rect().size * Vector2(0.5, 0.7)
		angulo = novo_angulo
		zona_inicio = inicio
		zona_fim = fim
		girando = esta_girando
		acertos = novos_acertos
		total = novo_total
		_texto.text = "ESPAÇO!" if girando else "ATENÇÃO..."
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, RAIO + 6.0, Color(0, 0, 0, 0.7))
		draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 48, Color(0.35, 0.4, 0.45), 2.0)
		draw_arc(Vector2.ZERO, RAIO, _rad(zona_inicio), _rad(zona_fim), 16, Color(0.9, 0.95, 1.0), 4.0)
		if girando:
			var direcao := Vector2.from_angle(_rad(angulo))
			draw_line(direcao * (RAIO - 9.0), direcao * (RAIO + 5.0), Color(1.0, 0.25, 0.2), 2.0)
		for i in total:
			var ponto := Vector2((i - (total - 1) / 2.0) * 9.0, RAIO + 10.0)
			draw_circle(ponto, 2.5, Color(0.23, 1.0, 0.43) if i < acertos else Color(0.3, 0.3, 0.35))

	# 0° no topo, sentido horário (o 0 do Godot fica à direita)
	func _rad(graus: float) -> float:
		return deg_to_rad(graus - 90.0)
