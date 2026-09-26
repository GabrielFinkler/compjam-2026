extends CharacterBody2D
## Monstro/alien: patrulha um caminho, persegue o jogador ao vê-lo (o escuro não
## atrapalha a visão dele), mata no contato e congela sob o feixe do modo foco.

@export var caminho: Path2D ## Desenhe um Path2D na cena e selecione ele aqui
@export var velocidade_patrulha: float = 20.0
@export var velocidade_perseguicao: float = 60.0
@export var raio_visao: float = 156.0 ## Distância em que ele passa a te ver
@export var raio_perseguicao: float = 250.0 ## Distância em que ele desiste de te seguir
@export var perseguir_para_sempre: bool = false ## Depois que te vê, nunca mais desiste (ignora distância e visão)
@export var raio: float = 8.0 ## Metade do tamanho do corpo: margem pro feixe do foco pegar nele

const COR_CONGELADO := Color(0.5, 0.8, 1.0)

var jogador: Node2D
var perseguindo: bool = false
var _pontos: PackedVector2Array = []
var _indice_ponto: int = 0

func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	if caminho:
		for i in caminho.curve.point_count:
			_pontos.append(caminho.to_global(caminho.curve.get_point_position(i)))

func _physics_process(_delta: float) -> void:
	if jogador and jogador.esta_no_feixe_foco(global_position, raio):
		modulate = COR_CONGELADO
		velocity = Vector2.ZERO
		return
	modulate = Color.WHITE

	var raio_atual := raio_perseguicao if perseguindo else raio_visao
	if jogador and ((perseguindo and perseguir_para_sempre) or _consegue_ver(jogador, raio_atual)):
		perseguindo = true
		_mover_para(jogador.global_position, velocidade_perseguicao)
		return

	if perseguindo:
		perseguindo = false
		_indice_ponto = _ponto_mais_proximo()

	if _pontos.is_empty():
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(_pontos[_indice_ponto]) < 4.0:
		_indice_ponto = (_indice_ponto + 1) % _pontos.size()
	_mover_para(_pontos[_indice_ponto], velocidade_patrulha)

func _mover_para(alvo: Vector2, vel: float) -> void:
	velocity = global_position.direction_to(alvo) * vel
	move_and_slide()

# Vê pela distância + linha de visão (paredes bloqueiam), sem depender de luz
func _consegue_ver(alvo: Node2D, alcance: float) -> bool:
	if global_position.distance_to(alvo.global_position) > alcance:
		return false
	var consulta := PhysicsRayQueryParameters2D.create(global_position, alvo.global_position)
	consulta.exclude = [get_rid(), alvo.get_rid()]
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
