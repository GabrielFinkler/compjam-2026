extends CanvasLayer
## Objetivo atual da fase, no canto superior direito. Quando a porta N da lista abre,
## passa pro objetivo N+1 (então "textos" tem uma linha a mais que "portas").
## No texto, {restantes} vira o número de travas que ainda faltam na porta atual.

@export var portas: Array[Node] = []
## Opcional: nome do sinal de cada item de "portas" que avança o objetivo (vazio = "aberta").
## Ex.: a mesma porta duas vezes, com "emperrada_vista" e depois "aberta" (fase 4).
@export var sinais: PackedStringArray = []
## Um objetivo por linha. (Texto simples de propósito: a lista PackedStringArray
## sumia quando o editor re-salvava a cena.)
@export_multiline var textos: String = ""
## Opcional: o painel só aparece depois que esse nó sai da cena (ex.: o Tutorial, que
## ocupa o topo da tela e ficaria por cima do painel)
@export var esperar: Node

const COR_BORDA := Color(0.15, 0.68, 0.88)

var _indice: int = 0
var _linhas: PackedStringArray
var _painel: PanelContainer
var _texto: Label
var _esperando: bool = false


func _ready() -> void:
	_linhas = textos.strip_edges().split("\n", false)
	_criar_interface()
	# O tutorial se apaga no _ready quando já foi concluído (ex.: recarregou ao morrer)
	if is_instance_valid(esperar) and esperar.is_inside_tree() and not esperar.is_queued_for_deletion():
		_esperando = true
		esperar.tree_exited.connect(_on_esperar_saiu, CONNECT_ONE_SHOT)
	for i in portas.size():
		var porta := portas[i]
		var sinal := sinais[i] if i < sinais.size() and sinais[i] != "" else "aberta"
		porta.connect(sinal, _on_porta_aberta.bind(i))
		if porta.has_signal("trava_liberada"):
			porta.trava_liberada.connect(func(_restantes: int): _mostrar())
	_mostrar()


func _on_esperar_saiu() -> void:
	_esperando = false
	# Também dispara quando a fase inteira é descarregada: aí não há o que mostrar
	if is_inside_tree():
		_mostrar()


func _on_porta_aberta(indice: int) -> void:
	# Portas podem abrir fora de ordem: nunca volta pra um objetivo anterior
	_indice = maxi(_indice, indice + 1)
	_mostrar()


func _mostrar() -> void:
	if _esperando:
		_painel.visible = false
		return
	_painel.visible = true
	if _indice >= _linhas.size():
		_painel.visible = false
		return
	var texto := _linhas[_indice].strip_edges()
	if _indice < portas.size() and "travas_restantes" in portas[_indice]:
		texto = texto.replace("{restantes}", str(portas[_indice].travas_restantes))
	_texto.text = texto
	_painel.modulate.a = 0.0
	create_tween().tween_property(_painel, "modulate:a", 1.0, 0.35)


func _criar_interface() -> void:
	_painel = PanelContainer.new()
	_painel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Não encosta no HUD do canto superior esquerdo (vai até x=105). Com a fonte de 6 px cabem
	# ~26 letras por linha: escreva objetivos curtos, de no máximo 2 linhas
	_painel.offset_left = -176
	_painel.offset_right = -6
	_painel.offset_top = 6
	_painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.7)
	estilo.border_color = COR_BORDA
	estilo.border_width_left = 2
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(4)
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.theme = preload("res://Scripts/tema_pixel.gd").criar()
	add_child(_painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	_painel.add_child(coluna)
	var titulo := Label.new()
	titulo.text = "OBJETIVO"
	titulo.add_theme_font_size_override("font_size", 6)
	titulo.add_theme_color_override("font_color", COR_BORDA)
	coluna.add_child(titulo)
	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(160, 0)
	# 6 e não 8: a tela de 480x270 é esticada 4x (1080p), então a fonte sai com 24 px reais,
	# múltiplo de 8, e continua nítida (também em 720p e 1440p)
	_texto.add_theme_font_size_override("font_size", 6)
	coluna.add_child(_texto)
