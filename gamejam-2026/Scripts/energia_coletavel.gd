extends Area2D
## Energia coletável: ao encostar, a nave recarrega toda a energia.
## De tempos em tempos ela solta um brilho azul (como o LED dos terminais), pra
## dar pra achar no escuro mesmo sem a lanterna apontada pra ela.

@export var intervalo_brilho: float = 3.0 ## Segundos entre um brilho e outro
@export var energia_brilho: float = 1.6 ## Intensidade do pico do brilho

const TEMPO_ACENDER := 0.25
const TEMPO_APAGAR := 0.6

@onready var _brilho: PointLight2D = $Brilho

func _ready() -> void:
	add_to_group("energia_coletavel")
	body_entered.connect(_on_body_entered)
	_brilho.energy = 0.0
	# Começa num ponto aleatório do ciclo: as esferas não piscam todas juntas
	var tween := create_tween()
	tween.tween_interval(randf() * intervalo_brilho)
	tween.tween_callback(_pulsar_em_loop)

func _pulsar_em_loop() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_brilho, "energy", energia_brilho, TEMPO_ACENDER).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_brilho, "energy", 0.0, TEMPO_APAGAR).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(maxf(intervalo_brilho - TEMPO_ACENDER - TEMPO_APAGAR, 0.0))

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("recarregar_energia"):
		body.recarregar_energia()
		queue_free()
