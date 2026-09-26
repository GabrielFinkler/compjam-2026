extends Area2D
## Power-up "Sinalizador de Isca": ao pegar, o jogador ganha o lançador de iscas
## luminosas ([Q] ou botão direito). A isca brilha onde cair e atrai os monstros que a
## enxergarem: serve pra tirar um monstro do caminho, iluminar um canto escuro atrás de
## esferas ou despistar uma perseguição. Uso único: cada item vale um lançamento, que
## gasta energia da lanterna.

@export var custo_energia: float = 15.0 ## Energia da lanterna gasta por isca
@export var alcance_lancamento: float = 110.0 ## Distância máxima do arremesso (px)
@export var duracao_isca: float = 5.0 ## Segundos que a isca fica acesa
@export var raio_atracao: float = 220.0 ## Distância em que os monstros enxergam a isca
@export var raio_alarme: float = 0.0 ## Ao pegar, os monstros nesse raio vêm checar o barulho (0 = silencioso)
@export var tempo_alarme: float = 6.0 ## Segundos que eles ficam procurando no local
@export_multiline var mensagem: String = "SINALIZADOR DE ISCA! [Q] OU BOTÃO DIREITO LANÇA UMA LUZ QUE ATRAI OS MONSTROS. SÓ DÁ PRA USAR UMA VEZ!"

const Aviso := preload("res://Scripts/aviso.gd")
const COR := Color(1.0, 0.35, 0.3)
const LancadorIsca := preload("res://Scripts/lancador_isca.gd")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Flutua devagar pra chamar atenção quando a luz bate nele
	var tween := create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("jogador"):
		return
	# Já tinha uma isca guardada: soma mais uma carga
	var lancador := body.get_node_or_null("LancadorIsca")
	if lancador == null or lancador.is_queued_for_deletion():
		lancador = LancadorIsca.new()
		lancador.name = "LancadorIsca"
		body.add_child(lancador)
	else:
		lancador.cargas += 1
	lancador.custo_energia = custo_energia
	lancador.alcance_lancamento = alcance_lancamento
	lancador.duracao_isca = duracao_isca
	lancador.raio_atracao = raio_atracao
	# O aviso fica na cena (o item some agora)
	Aviso.mostrar(get_tree().current_scene, mensagem, COR, 6.0)
	if raio_alarme > 0.0:
		for monstro in get_tree().get_nodes_in_group("monstro"):
			if monstro.has_method("investigar") and monstro.global_position.distance_to(global_position) <= raio_alarme:
				monstro.investigar(global_position, tempo_alarme)
	queue_free()
