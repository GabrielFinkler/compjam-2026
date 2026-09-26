extends CanvasLayer
## Tutorial da primeira fase: mostra um passo por vez no topo da tela e só avança
## quando o jogador faz a ação pedida (andar, mirar, focar, recarregar).

enum Passo { ANDAR, MIRAR, FOCAR, RECARREGAR, FIM }

const TEXTOS := {
	Passo.ANDAR: "Use W A S D para andar.",
	Passo.MIRAR: "Mova o mouse para apontar a lanterna.",
	Passo.FOCAR: "Segure o BOTÃO ESQUERDO do mouse para focar a luz: ela vai mais longe e congela os aliens, mas gasta energia bem mais rápido.",
	Passo.RECARREGAR: "A lanterna gasta energia (barra no canto de cima) e, se ela acabar, você morre! Ache uma esfera azul e passe por cima para recarregar. Elas só aparecem quando a luz bate nelas!",
	Passo.FIM: "Pronto! Cuidado com os aliens: se eles te virem, vêm atrás de você.",
}

const DISTANCIA_ANDAR := 125.0 # px andados para concluir o passo
const ROTACAO_MIRAR := PI # radianos girados com o mouse (meia volta)
const TEMPO_FOCO := 1.0 # segundos com o foco totalmente ligado
const TEMPO_MENSAGEM_FINAL := 4.0
const CHAVE_CONCLUIDO := &"tutorial_fase1_concluido" # Guardada no root: sobrevive ao reload da cena ao morrer

var jogador: Node2D
var passo_atual: Passo = Passo.ANDAR
var progresso: float = 0.0
var _concluidos: Dictionary = {} # Passo -> true
var _ultima_posicao: Vector2
var _ultima_rotacao: float
var painel: PanelContainer
var texto: Label

func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	if jogador == null or get_tree().root.get_meta(CHAVE_CONCLUIDO, false):
		set_process(false)
		queue_free()
		return
	jogador.energia_recarregada.connect(_on_energia_recarregada)
	_criar_interface()
	_mostrar_passo(Passo.ANDAR)

func _process(delta: float) -> void:
	match passo_atual:
		Passo.ANDAR:
			progresso += jogador.global_position.distance_to(_ultima_posicao)
			_ultima_posicao = jogador.global_position
			if progresso >= DISTANCIA_ANDAR:
				_avancar(Passo.ANDAR)
		Passo.MIRAR:
			progresso += absf(angle_difference(_ultima_rotacao, jogador.global_rotation))
			_ultima_rotacao = jogador.global_rotation
			if progresso >= ROTACAO_MIRAR:
				_avancar(Passo.MIRAR)
		Passo.FOCAR:
			if jogador.fator_foco >= 1.0:
				progresso += delta
			if progresso >= TEMPO_FOCO:
				_avancar(Passo.FOCAR)
		Passo.RECARREGAR:
			# Se o jogador já pegou todas as esferas antes deste passo, não trava aqui
			if get_tree().get_nodes_in_group("energia_coletavel").is_empty():
				_avancar(Passo.RECARREGAR)
		Passo.FIM:
			progresso += delta
			if progresso >= TEMPO_MENSAGEM_FINAL:
				_concluir()

func _on_energia_recarregada() -> void:
	if passo_atual == Passo.RECARREGAR:
		_avancar(Passo.RECARREGAR)

# Marca o passo como feito e mostra o primeiro que ainda falta
func _avancar(feito: Passo) -> void:
	_concluidos[feito] = true
	for passo in [Passo.ANDAR, Passo.MIRAR, Passo.FOCAR, Passo.RECARREGAR]:
		if not _concluidos.has(passo):
			_mostrar_passo(passo)
			return
	# Já conta como concluído aqui: morrer durante a mensagem final não refaz o tutorial
	get_tree().root.set_meta(CHAVE_CONCLUIDO, true)
	_mostrar_passo(Passo.FIM)

func _mostrar_passo(passo: Passo) -> void:
	passo_atual = passo
	progresso = 0.0
	_ultima_posicao = jogador.global_position
	_ultima_rotacao = jogador.global_rotation
	texto.text = TEXTOS[passo]
	painel.modulate.a = 0.0
	create_tween().tween_property(painel, "modulate:a", 1.0, 0.35)

func _concluir() -> void:
	set_process(false)
	var tween := create_tween()
	tween.tween_property(painel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _criar_interface() -> void:
	painel = PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# Meia-largura 130 numa tela de 480: não encosta no HUD do canto superior esquerdo (termina em x=105)
	painel.offset_left = -130
	painel.offset_right = 130
	painel.offset_top = 6
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.7)
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(6)
	painel.add_theme_stylebox_override("panel", estilo)
	add_child(painel)

	texto = Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 8)
	painel.add_child(texto)
