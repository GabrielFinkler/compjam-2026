extends Node
## Aviso temporário embaixo da tela (ex.: "PORTA LIBERADA!"). Usado pelos terminais, pela
## máquina de reparo, pelos monstros, pelas portas e pelos itens coletáveis.
## Os avisos entram numa fila e aparecem um de cada vez, na ordem em que chegaram: nunca um
## em cima do outro. A fila é um nó deste script pendurado no root (sobrevive à troca de
## fase), e avisos pedidos numa fase que já saiu de cena são descartados.

const COR_PADRAO := Color(0.15, 0.68, 0.88)
const TEMPO_PADRAO := 3.0
const TEMPO_COM_FILA := 2.5 # Com outros avisos esperando, cada um fica um pouco menos na tela
const LARGURA_MAXIMA := 240.0 # Textos maiores quebram linha em vez de sair da tela (480px)
const TAMANHO_FONTE := 6 # Nítida: a tela é esticada 4x (1080p), então sai com 24 px reais
const META_FILA := &"fila_avisos"

var _pedidos: Array[Dictionary] = []
var _atual: CanvasLayer

## Põe o aviso na fila. "dono" só serve pra achar a árvore: o aviso aparece na fase atual.
static func mostrar(dono: Node, mensagem: String, cor: Color = COR_PADRAO, tempo: float = TEMPO_PADRAO) -> void:
	var raiz := dono.get_tree().root
	var fila: Variant = raiz.get_meta(META_FILA, null) # Variant: aceita até instância já liberada
	if not is_instance_valid(fila):
		fila = load("res://Scripts/aviso.gd").new()
		fila.name = "FilaAvisos"
		raiz.set_meta(META_FILA, fila) # Na hora: dois avisos no mesmo frame usam a mesma fila
		raiz.add_child.call_deferred(fila) # Adiado: o root pode estar montando a fase agora
	fila._pedidos.append({
		"fase": dono.get_tree().current_scene,
		"mensagem": mensagem,
		"cor": cor,
		"tempo": tempo,
	})

func _process(_delta: float) -> void:
	if is_instance_valid(_atual) or _pedidos.is_empty():
		return
	var pedido: Dictionary = _pedidos.pop_front()
	var fase: Variant = pedido["fase"]
	# Pedido de uma fase que já foi trocada (morreu, passou de fase): descarta
	if not is_instance_valid(fase) or fase != get_tree().current_scene:
		return
	var tempo: float = pedido["tempo"]
	if not _pedidos.is_empty():
		tempo = minf(tempo, TEMPO_COM_FILA)
	_atual = _exibir(fase, pedido["mensagem"], pedido["cor"], tempo)

func _exibir(fase: Node, mensagem: String, cor: Color, tempo: float) -> CanvasLayer:
	var camada := CanvasLayer.new()
	fase.add_child(camada)
	var centro := CenterContainer.new()
	camada.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	centro.offset_top = -30
	centro.offset_bottom = -8
	centro.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.75)
	estilo.border_color = cor
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(4)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.theme = preload("res://Scripts/tema_pixel.gd").criar()
	centro.add_child(painel)
	var texto := Label.new()
	texto.text = mensagem
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	if mensagem.length() * TAMANHO_FONTE > LARGURA_MAXIMA:
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.custom_minimum_size = Vector2(LARGURA_MAXIMA, 0)
	painel.add_child(texto)
	var tween := camada.create_tween()
	tween.tween_interval(tempo)
	tween.tween_property(painel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(camada.queue_free)
	return camada
