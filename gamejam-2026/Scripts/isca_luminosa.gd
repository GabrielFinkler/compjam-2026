extends Node2D
## Isca luminosa lançada pelo Sinalizador: voa até o destino, acende e, enquanto brilha,
## chama pra si os monstros que conseguem enxergá-la. Perto do fim ela vai apagando e some.

@export var duracao: float = 8.0 ## Segundos acesa
@export var raio_atracao: float = 220.0 ## Distância máxima em que um monstro a enxerga

const TEMPO_VOO := 0.35
const INTERVALO_CHAMADO := 0.4 # Monstros que entrarem na visão depois também são atraídos
const TEMPO_APAGANDO := 1.5
const ENERGIA_LUZ := 1.3

@onready var _luz: PointLight2D = $PointLight2D
@onready var _sprite: Sprite2D = $Sprite2D

var _ativa: bool = false
var _tempo: float = 0.0
var _proximo_chamado: float = 0.0


func _ready() -> void:
	_luz.energy = 0.3


func lancar_para(destino: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", destino, TEMPO_VOO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_sprite, "rotation", TAU * 2.0, TEMPO_VOO)
	tween.tween_callback(func(): _ativa = true)


func _process(delta: float) -> void:
	if not _ativa:
		return
	_tempo += delta
	# Tremula como um sinalizador de verdade e vai apagando no final
	var apagando := clampf((duracao - _tempo) / TEMPO_APAGANDO, 0.0, 1.0)
	_luz.energy = ENERGIA_LUZ * (0.85 + 0.15 * sin(_tempo * 23.0) * sin(_tempo * 7.0)) * apagando
	_sprite.modulate.a = apagando
	_proximo_chamado -= delta
	if _proximo_chamado <= 0.0:
		_proximo_chamado = INTERVALO_CHAMADO
		_chamar_monstros()
	if _tempo >= duracao:
		queue_free()


func _chamar_monstros() -> void:
	var restante := duracao - _tempo
	for monstro in get_tree().get_nodes_in_group("monstro"):
		if monstro.has_method("atrair") and monstro.consegue_ver_ponto(global_position, raio_atracao):
			monstro.atrair(global_position, restante)
