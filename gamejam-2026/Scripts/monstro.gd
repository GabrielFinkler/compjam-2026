extends CharacterBody2D
## Monstro/alien: patrulha um caminho, persegue o jogador ao vê-lo (o escuro não
## atrapalha a visão dele), mata no contato e congela sob o feixe do modo foco.
## Uma isca luminosa que ele enxergue o atrai (ver atrair()). Com tempo_investigacao > 0,
## ao perder o jogador de vista ele vai até onde o viu por último e procura um pouco.
## Com usar_navegacao, desvia de paredes e móveis (precisa de um NavigationRegion2D na fase).
## Com comeca_adormecido, fica escondido até despertar() (ex.: ligado ao sinal de uma porta).

@export var caminho: Path2D ## Desenhe um Path2D na cena e selecione ele aqui
@export var velocidade_patrulha: float = 20.0
@export var velocidade_perseguicao: float = 60.0
@export var raio_visao: float = 156.0 ## Distância em que ele passa a te ver
@export var raio_perseguicao: float = 250.0 ## Distância em que ele desiste de te seguir
@export var perseguir_para_sempre: bool = false ## Depois que te vê, nunca mais desiste (ignora distância e visão)
@export var raio: float = 8.0 ## Metade do tamanho do corpo: margem pro feixe do foco pegar nele
@export var tempo_investigacao: float = 0.0 ## Segundos procurando onde te viu por último antes de voltar à patrulha (0 = volta na hora)
@export var velocidade_busca: float = 0.0 ## Velocidade indo checar onde te viu ou um barulho (0 = dobro da patrulha)
@export var usar_navegacao: bool = false ## Contorna paredes e móveis em vez de andar em linha reta
@export var voltar_pelo_rastro: bool = false ## Ao voltar pra ronda, refaz o trajeto que fez ao sair dela (bom pra fase sem navegação)
@export_flags_2d_physics var mascara_visao: int = 0xFFFFFFFF ## Camadas que bloqueiam a visão (ex.: só paredes, pra enxergar por cima dos móveis)
@export var comeca_adormecido: bool = false ## Fica invisível e parado até despertar() ser chamado
@export var mensagem_despertar: String = "" ## Aviso mostrado quando desperta (vazio = nenhum)
@export var tempo_congelado_extra: float = 0.4 ## Segundos que continua parado depois que a luz sai dele

const COR_CONGELADO := Color(0.5, 0.8, 1.0)
const VELOCIDADE_GIRO := 10.0 # Quão rápido o sprite vira pra direção em que anda
const Aviso := preload("res://Scripts/aviso.gd")

var jogador: Node2D
var perseguindo: bool = false
var _pontos: PackedVector2Array = []
var _indice_ponto: int = 0
var _ultima_posicao_vista: Vector2
var _tempo_busca: float = 0.0
var _alvo_isca: Vector2
var _tempo_isca: float = 0.0
var _agente: NavigationAgent2D
var _tempo_congelado: float = 0.0
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
var _rastro: PackedVector2Array = [] ## Pontos por onde passou fora da ronda, pra refazer na volta

func _ready() -> void:
	add_to_group("monstro")
	jogador = get_tree().get_first_node_in_group("jogador")
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	if caminho:
		for i in caminho.curve.point_count:
			_pontos.append(caminho.to_global(caminho.curve.get_point_position(i)))
	if usar_navegacao:
		_agente = NavigationAgent2D.new()
		_agente.radius = raio
		_agente.path_desired_distance = 4.0
		_agente.target_desired_distance = 4.0
		add_child(_agente)
	if comeca_adormecido:
		_ativar(false)

## Acorda um monstro que começou adormecido: aparece e já vem atrás do jogador.
func despertar() -> void:
	if not comeca_adormecido:
		return
	comeca_adormecido = false
	_ativar(true)
	perseguindo = true
	if mensagem_despertar != "":
		Aviso.mostrar(get_tree().current_scene, mensagem_despertar, Color(1.0, 0.25, 0.2), 4.0)

func _ativar(ligado: bool) -> void:
	visible = ligado
	set_physics_process(ligado)
	$CollisionShape2D.set_deferred("disabled", not ligado)
	$Hitbox.set_deferred("monitoring", ligado)

func _physics_process(delta: float) -> void:
	# Sob o feixe fica congelado; ao sair dele ainda leva tempo_congelado_extra pra voltar
	if jogador and jogador.esta_no_feixe_foco(global_position, raio):
		_tempo_congelado = tempo_congelado_extra
	elif _tempo_congelado > 0.0:
		_tempo_congelado -= delta
	if _tempo_congelado > 0.0:
		modulate = COR_CONGELADO
		velocity = Vector2.ZERO
		return
	modulate = Color.WHITE

	# Enquanto a isca brilha, ele só tem olhos pra ela
	if _tempo_isca > 0.0:
		_tempo_isca -= delta
		perseguindo = false
		_registrar_rastro()
		_ir_ate_e_esperar(_alvo_isca, velocidade_perseguicao)
		if _tempo_isca <= 0.0:
			_indice_ponto = _ponto_mais_proximo()
		return

	var raio_atual := raio_perseguicao if perseguindo else raio_visao
	if jogador and ((perseguindo and perseguir_para_sempre) or _consegue_ver(jogador, raio_atual)):
		perseguindo = true
		_ultima_posicao_vista = jogador.global_position
		_registrar_rastro()
		_mover_para(jogador.global_position, velocidade_perseguicao)
		return

	if perseguindo:
		perseguindo = false
		_tempo_busca = tempo_investigacao
		_indice_ponto = _ponto_mais_proximo()

	if _tempo_busca > 0.0:
		_tempo_busca -= delta
		_registrar_rastro()
		_ir_ate_e_esperar(_ultima_posicao_vista, velocidade_busca if velocidade_busca > 0.0 else velocidade_patrulha * 2.0)
		if _tempo_busca <= 0.0:
			_indice_ponto = _ponto_mais_proximo()
		return

	# Volta pra ronda pelo mesmo trajeto que fez, do fim pro começo
	if not _rastro.is_empty():
		var alvo := _rastro[_rastro.size() - 1]
		if global_position.distance_to(alvo) < 4.0:
			_rastro.remove_at(_rastro.size() - 1)
			if _rastro.is_empty():
				_indice_ponto = _ponto_mais_proximo()
		else:
			_mover_para(alvo, velocidade_patrulha)
		return

	if _pontos.is_empty():
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(_pontos[_indice_ponto]) < 4.0:
		_indice_ponto = (_indice_ponto + 1) % _pontos.size()
	_mover_para(_pontos[_indice_ponto], velocidade_patrulha)

## Chamado pela isca luminosa: larga o que estiver fazendo e vai até ela.
func atrair(alvo: Vector2, duracao: float) -> void:
	_alvo_isca = alvo
	_tempo_isca = maxf(_tempo_isca, duracao)

## Chamado por barulhos (ex.: alarme): vai checar o local, mas persegue se te vir no caminho.
func investigar(ponto: Vector2, duracao: float) -> void:
	if perseguindo:
		return
	_ultima_posicao_vista = ponto
	_tempo_busca = maxf(_tempo_busca, duracao)

func _registrar_rastro() -> void:
	if not voltar_pelo_rastro:
		return
	if _rastro.is_empty() or global_position.distance_to(_rastro[_rastro.size() - 1]) > 8.0:
		_rastro.append(global_position)

func _mover_para(alvo: Vector2, vel: float) -> void:
	var proximo := alvo
	if _agente:
		_agente.target_position = alvo
		proximo = _agente.get_next_path_position()
		# Sem malha de navegação (ainda não assada ou fora dela): vai reto mesmo
		if _agente.get_current_navigation_path().is_empty():
			proximo = alvo
	velocity = global_position.direction_to(proximo) * vel
	move_and_slide()
	# Gira no próprio eixo pra olhar pra onde anda (o desenho olha pra cima: +90°).
	# Só o sprite gira: colisão e hitbox continuam iguais
	if velocity.length() > 1.0:
		var peso := minf(VELOCIDADE_GIRO * get_physics_process_delta_time(), 1.0)
		_sprite.rotation = lerp_angle(_sprite.rotation, velocity.angle() + PI / 2.0, peso)

func _ir_ate_e_esperar(alvo: Vector2, vel: float) -> void:
	if global_position.distance_to(alvo) > 6.0:
		_mover_para(alvo, vel)
	else:
		velocity = Vector2.ZERO

# Vê pela distância + linha de visão (paredes bloqueiam), sem depender de luz
func _consegue_ver(alvo: Node2D, alcance: float) -> bool:
	return consegue_ver_ponto(alvo.global_position, alcance, [alvo.get_rid()])

func consegue_ver_ponto(ponto: Vector2, alcance: float, excluir: Array[RID] = []) -> bool:
	if global_position.distance_to(ponto) > alcance:
		return false
	var consulta := PhysicsRayQueryParameters2D.create(global_position, ponto, mascara_visao)
	var excluidos: Array[RID] = [get_rid()]
	excluidos.append_array(excluir)
	consulta.exclude = excluidos
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

func _ponto_mais_proximo() -> int:
	var melhor := 0
	for i in _pontos.size():
		if global_position.distance_to(_pontos[i]) < global_position.distance_to(_pontos[melhor]):
			melhor = i
	return melhor

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("morrer"):
		body.morrer()
