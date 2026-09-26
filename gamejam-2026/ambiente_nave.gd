extends Node2D

# ==============================================================================
# CONTROLE DE ATMOSFERA E ILUMINAÇÃO DARK / SCI-FI HORROR
# ==============================================================================
# Este script cria o efeito de oscilação e pulso das luzes de emergência e
# painéis de energia da nave para reforçar a tensão e perigo do Alien.
# ==============================================================================

@export var luzes_emergencia: Array[PointLight2D] = []
@export var velocidade_pulso: float = 2.5
@export var chance_piscar: float = 0.03

var _tempo: float = 0.0

func _ready():
	# Encontra automaticamente PointLight2D no grupo "luzes_alerta" se houver
	for node in get_tree().get_nodes_in_group("luzes_alerta"):
		if node is PointLight2D and not luzes_emergencia.has(node):
			luzes_emergencia.append(node)

func _process(delta: float):
	_tempo += delta * velocidade_pulso
	
	# Pulso senoidal suave para luzes de alerta/emergência
	var fator_brilho = (sin(_tempo) * 0.25) + 0.85
	
	for luz in luzes_emergencia:
		if is_instance_valid(luz):
			# Micro piscares aleatórios de queda de energia na nave
			if randf() < chance_piscar:
				luz.energy = randf_range(0.3, 0.7)
			else:
				luz.energy = lerp(luz.energy, fator_brilho, delta * 8.0)
