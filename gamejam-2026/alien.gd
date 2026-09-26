extends CharacterBody2D

# ==============================================================================
# ALIEN - IA DE PATRULHA E PERSEGUIÇÃO (SCI-FI HORROR)
# ==============================================================================

enum Estado { PATRULHA, PERSEGUIR, ESPERAR }

@export var velocidade_patrulha: float = 65.0
@export var velocidade_perseguir: float = 135.0
@export var raio_visao: float = 160.0
@export var raio_audicao: float = 90.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var luz_olhos: PointLight2D = $LuzOlhos

var estado_atual: Estado = Estado.PATRULHA
var alvo_jogador: Node2D = null
var pontos_patrulha: Array[Vector2] = []
var indice_ponto: int = 0
var tempo_espera: float = 0.0
var anim_timer: float = 0.0

func _ready():
	# Pontos de patrulha pelas salas da nave (em coordenadas de mundo)
	# Hub Central, Laboratório Aberto, Corredores e Vents
	pontos_patrulha = [
		Vector2(480, 184), # Lobby Central
		Vector2(480, 88),  # Cômodo Aberto (Laboratório)
		Vector2(304, 184), # Corredor 1
		Vector2(650, 184), # Corredor 2
		Vector2(480, 184)  # Retorno ao Lobby
	]
	
	# Busca o Player na árvore de cena
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		alvo_jogador = players[0]

func _physics_process(delta: float):
	if alvo_jogador == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			alvo_jogador = players[0]
	
	# Checagem de distância até o jogador
	var dist_jogador = INF
	if alvo_jogador != null:
		dist_jogador = global_position.distance_to(alvo_jogador.global_position)
	
	# Transições de Estado
	if dist_jogador < raio_visao:
		estado_atual = Estado.PERSEGUIR
	elif estado_atual == Estado.PERSEGUIR and dist_jogador > raio_visao * 1.5:
		estado_atual = Estado.PATRULHA
	
	var dir = Vector2.ZERO
	
	match estado_atual:
		Estado.PERSEGUIR:
			if alvo_jogador != null:
				dir = (alvo_jogador.global_position - global_position).normalized()
				velocity = dir * velocidade_perseguir
				luz_olhos.color = Color(1.0, 0.1, 0.1, 1.0)
				luz_olhos.energy = 1.4
		
		Estado.PATRULHA:
			luz_olhos.color = Color(0.8, 0.2, 0.2, 1.0)
			luz_olhos.energy = 0.8
			if pontos_patrulha.size() > 0:
				var destino = pontos_patrulha[indice_ponto]
				if global_position.distance_to(destino) < 16.0:
					estado_atual = Estado.ESPERAR
					tempo_espera = randf_range(1.5, 3.0)
				else:
					dir = (destino - global_position).normalized()
					velocity = dir * velocidade_patrulha
		
		Estado.ESPERAR:
			velocity = Vector2.ZERO
			tempo_espera -= delta
			if tempo_espera <= 0.0:
				indice_ponto = (indice_ponto + 1) % pontos_patrulha.size()
				estado_atual = Estado.PATRULHA
	
	move_and_slide()
	
	# Animação do Sprite
	if velocity.length_squared() > 10.0:
		anim_timer += delta * 7.0
		if sprite.hframes > 1:
			sprite.frame = int(anim_timer) % sprite.hframes
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
	else:
		if sprite.hframes > 1:
			sprite.frame = 0
