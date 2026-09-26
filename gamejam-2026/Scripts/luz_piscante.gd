extends PointLight2D
## Luz com mau contato: de tempos em tempos dá umas piscadas rápidas e volta ao normal.

@export var intervalo_minimo: float = 2.0 ## Segundos mínimos entre uma crise de piscadas e outra
@export var intervalo_maximo: float = 7.0
@export_range(0.0, 1.0) var chance_apagar: float = 0.15 ## Chance de ficar apagada por um tempo em vez de só piscar

var _energia_base: float


func _ready() -> void:
	_energia_base = energy
	_agendar(randf_range(0.0, intervalo_maximo))


func _agendar(espera: float) -> void:
	var tween := create_tween()
	tween.tween_interval(espera)
	tween.tween_callback(_piscar)


func _piscar() -> void:
	var tween := create_tween()
	for i in randi_range(2, 5):
		tween.tween_property(self, "energy", _energia_base * randf_range(0.0, 0.3), randf_range(0.03, 0.08))
		tween.tween_property(self, "energy", _energia_base, randf_range(0.04, 0.1))
	if randf() < chance_apagar:
		tween.tween_property(self, "energy", 0.0, 0.05)
		tween.tween_interval(randf_range(1.0, 2.5))
		tween.tween_property(self, "energy", _energia_base, 0.1)
	tween.tween_callback(func(): _agendar(randf_range(intervalo_minimo, intervalo_maximo)))
