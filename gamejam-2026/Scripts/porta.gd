extends StaticBody2D
## Porta deslizante: trancada, bloqueia a passagem e a luz. Ao chamar abrir(),
## o LED fica verde e as duas metades deslizam pra dentro do batente.
## Para porta vertical, gire o nó 90° na cena.
## Com "travas" > 1, cada abrir() solta uma trava (LED fica amarelo) e ela só abre na última.

signal aberta
signal trava_liberada(restantes: int) ## Uma trava saiu, mas ainda faltam outras

@export var comeca_aberta: bool = false
@export_range(1, 5) var travas: int = 1 ## Quantos terminais/máquinas precisam ser ativados até abrir

const COR_TRANCADA := Color(1.0, 0.23, 0.23)
const COR_LIBERADA := Color(0.23, 1.0, 0.43)
const COR_PARCIAL := Color(1.0, 0.75, 0.2)
const ESPERA_LED := 0.3
const TEMPO_ABRIR := 0.5

@onready var _metade_a: Sprite2D = $MetadeA
@onready var _metade_b: Sprite2D = $MetadeB
@onready var _colisao: CollisionShape2D = $CollisionShape2D
@onready var _oclusor: LightOccluder2D = $LightOccluder2D
@onready var _led: ColorRect = $Led

var esta_aberta: bool = false
var travas_restantes: int

func _ready() -> void:
	travas_restantes = travas
	_led.color = COR_TRANCADA
	if comeca_aberta:
		_liberar_passagem()
		_metade_a.scale.x = 0.0
		_metade_b.scale.x = 0.0
		_led.visible = false

func abrir() -> void:
	if esta_aberta:
		return
	travas_restantes -= 1
	if travas_restantes > 0:
		_led.color = COR_PARCIAL
		trava_liberada.emit(travas_restantes)
		return
	_liberar_passagem()
	_led.color = COR_LIBERADA
	var tween := create_tween()
	tween.tween_interval(ESPERA_LED)
	tween.tween_callback(func(): _led.visible = false)
	tween.tween_property(_metade_a, "scale:x", 0.0, TEMPO_ABRIR)
	tween.parallel().tween_property(_metade_b, "scale:x", 0.0, TEMPO_ABRIR)

func _liberar_passagem() -> void:
	esta_aberta = true
	_colisao.set_deferred("disabled", true)
	_oclusor.visible = false
	aberta.emit()
