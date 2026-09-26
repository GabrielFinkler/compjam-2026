extends RefCounted
## Aviso temporário embaixo da tela (ex.: "PORTA LIBERADA!"). Usado pelos terminais,
## pela máquina de reparo e pelos itens coletáveis.

const COR_PADRAO := Color(0.15, 0.68, 0.88)
const TEMPO_PADRAO := 3.0
const LARGURA_MAXIMA := 300.0 # Textos maiores quebram linha em vez de sair da tela (480px)
const ALTURA_PILHA := 26.0 # Avisos ao mesmo tempo sobem um em cima do outro em vez de se cobrir
const GRUPO := &"aviso_tela"

## Mostra o aviso preso em `dono`: se o dono sumir (ex.: item coletado), o aviso some junto.
static func mostrar(dono: Node, mensagem: String, cor: Color = COR_PADRAO, tempo: float = TEMPO_PADRAO) -> void:
	var camada := CanvasLayer.new()
	var na_tela := dono.get_tree().get_nodes_in_group(GRUPO).size()
	camada.add_to_group(GRUPO)
	dono.add_child(camada)
	var centro := CenterContainer.new()
	camada.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	centro.offset_top = -40 - na_tela * ALTURA_PILHA
	centro.offset_bottom = -12 - na_tela * ALTURA_PILHA
	centro.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.75)
	estilo.border_color = cor
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(6)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.theme = preload("res://Scripts/tema_pixel.gd").criar()
	centro.add_child(painel)
	var texto := Label.new()
	texto.text = mensagem
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if mensagem.length() * 8 > LARGURA_MAXIMA:
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.custom_minimum_size = Vector2(LARGURA_MAXIMA, 0)
	painel.add_child(texto)
	var tween := camada.create_tween()
	tween.tween_interval(tempo)
	tween.tween_property(painel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(camada.queue_free)
