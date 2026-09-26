extends StaticBody2D
## Porta deslizante: trancada, bloqueia a passagem e a luz. Ao chamar abrir(),
## o LED fica verde e as duas metades deslizam pra dentro do batente.
## Para porta vertical, gire o nó 90° na cena.
## Com "travas" > 1, cada abrir() solta uma trava (LED fica amarelo) e ela só abre na última.
## emperrar(segundos, atraso): a porta bate fechando (mesmo se estava aberta), fica esse tempo
## tentando abrir com o LED piscando e depois abre de novo sozinha. Dá pra ligar num sinal da
## cena com "binds" (ex.: fase 5, quando o terminal do laboratório libera a saída).

signal aberta
signal trava_liberada(restantes: int) ## Uma trava saiu, mas ainda faltam outras
signal emperrou(segundos: float) ## Bateu fechando e emperrou: abre sozinha depois

@export var comeca_aberta: bool = false
@export_range(1, 5) var travas: int = 1 ## Quantos terminais/máquinas precisam ser ativados até abrir
@export var mensagem_emperrada: String = "" ## Aviso na tela quando ela emperra (vazio = nenhum)

const COR_TRANCADA := Color(1.0, 0.23, 0.23)
const COR_LIBERADA := Color(0.23, 1.0, 0.43)
const COR_PARCIAL := Color(1.0, 0.75, 0.2)
const ESPERA_LED := 0.3
const TEMPO_ABRIR := 0.5
const ABERTURA_TENTATIVA := 0.8 # Emperrada: as metades só chegam a abrir 20% antes de voltar
const TEMPO_BATER := 0.12 # Fechando de supetão
const Aviso := preload("res://Scripts/aviso.gd")

@onready var _metade_a: Sprite2D = $MetadeA
@onready var _metade_b: Sprite2D = $MetadeB
@onready var _colisao: CollisionShape2D = $CollisionShape2D
@onready var _oclusor: LightOccluder2D = $LightOccluder2D
@onready var _led: ColorRect = $Led

var esta_aberta: bool = false
var travas_restantes: int
var _emperrada: bool = false
var _tentativas: Tween
var _escala_a: float # Escala de cada metade fechada: a B é espelhada (-1), então não é 1 pras duas
var _escala_b: float

func _ready() -> void:
	travas_restantes = travas
	_escala_a = _metade_a.scale.x
	_escala_b = _metade_b.scale.x
	_led.color = COR_TRANCADA
	if comeca_aberta:
		_liberar_passagem()
		_metade_a.scale.x = 0.0
		_metade_b.scale.x = 0.0
		_led.visible = false

func abrir() -> void:
	if esta_aberta or _emperrada:
		return
	travas_restantes -= 1
	if travas_restantes > 0:
		_led.color = COR_PARCIAL
		trava_liberada.emit(travas_restantes)
		return
	_abrir_de_vez()

## Bate fechando depois de "atraso" segundos, fica "segundos" emperrada e abre de novo sozinha.
func emperrar(segundos: float, atraso: float = 0.0) -> void:
	if _emperrada:
		return
	_emperrada = true
	# Timer (e não await): se a fase recarregar no meio da espera, a ligação some com a porta.
	# false = o tempo para no pause
	get_tree().create_timer(atraso, false).timeout.connect(_bater_emperrada.bind(segundos))

func _bater_emperrada(segundos: float) -> void:
	_fechar_passagem()
	emperrou.emit(segundos)
	if mensagem_emperrada != "":
		Aviso.mostrar(get_tree().current_scene, mensagem_emperrada, COR_TRANCADA, 3.0)
	_led.visible = true
	_led.color = COR_TRANCADA
	var bater := create_tween()
	bater.tween_property(_metade_a, "scale:x", _escala_a, TEMPO_BATER)
	bater.parallel().tween_property(_metade_b, "scale:x", _escala_b, TEMPO_BATER)
	bater.tween_callback(_tentar_abrir)
	get_tree().create_timer(segundos, false).timeout.connect(_desemperrar)

# Emperrada: as metades tentam abrir e voltam num tranco, com o LED piscando amarelo/vermelho
func _tentar_abrir() -> void:
	_tentativas = create_tween().set_loops()
	_tentativas.tween_callback(func(): _led.color = COR_PARCIAL)
	_tentativas.tween_property(_metade_a, "scale:x", _escala_a * ABERTURA_TENTATIVA, 0.15)
	_tentativas.parallel().tween_property(_metade_b, "scale:x", _escala_b * ABERTURA_TENTATIVA, 0.15)
	_tentativas.tween_callback(func(): _led.color = COR_TRANCADA)
	_tentativas.tween_property(_metade_a, "scale:x", _escala_a, 0.06)
	_tentativas.parallel().tween_property(_metade_b, "scale:x", _escala_b, 0.06)
	_tentativas.tween_interval(0.5)

func _desemperrar() -> void:
	if _tentativas:
		_tentativas.kill()
	_emperrada = false
	_abrir_de_vez()

func _abrir_de_vez() -> void:
	_liberar_passagem()
	_led.color = COR_LIBERADA
	var tween := create_tween()
	tween.tween_interval(ESPERA_LED)
	tween.tween_callback(func(): _led.visible = false)
	tween.tween_property(_metade_a, "scale:x", 0.0, TEMPO_ABRIR)
	tween.parallel().tween_property(_metade_b, "scale:x", 0.0, TEMPO_ABRIR)

func _fechar_passagem() -> void:
	esta_aberta = false
	_colisao.set_deferred("disabled", false)
	_oclusor.visible = true

func _liberar_passagem() -> void:
	esta_aberta = true
	_colisao.set_deferred("disabled", true)
	_oclusor.visible = false
	aberta.emit()
