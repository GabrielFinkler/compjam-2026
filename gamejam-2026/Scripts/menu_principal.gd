extends Control
## Menu inicial do jogo: novo jogo, continuar (se houver save), opções e fechar.
## No fundo roda uma cena viva no estilo das fases: a nave no escuro, o espaço passando pela
## janela e o Traco patrulhando com a lanterna. Os aliens só aparecem quando a luz bate neles
## (e congelam, como no jogo). Tudo montado por código: a cena .tscn é só o nó raiz.

const TITULO := "NIGHTFALL"
const SUBTITULO := "PATROL"
const RODAPE := "COMPJAM 2026"

const COR_TITULO := Color(1.0, 0.84, 0.45) # Amarelo da lanterna
const COR_DESTAQUE := Color(0.15, 0.68, 0.88) # Mesmo ciano do HUD e dos terminais
const COR_TEXTO := Color(0.74, 0.79, 0.88)
const COR_ALERTA := Color(1.0, 0.22, 0.15)
const COR_CONGELADO := Color(0.5, 0.8, 1.0) # Mesmo tom do monstro congelado (monstro.gd)

const TEX_PISOS := preload("res://Imagens/pisos_paredes_16px.png")
const TEX_ESPACO := preload("res://Imagens/Space003.png")
const TEX_TRACO := preload("res://Imagens/personagem_spritesheet.png")
const TEX_ESPECIME := preload("res://Imagens/especime_spritesheet.png")
const TEX_MUX := preload("res://Imagens/monstro_mux_spritesheet.png")
const TEX_GLOB := preload("res://Imagens/orbe_energia_spritesheet.png")

const ALTURA_JANELA := 96 # Faixa de cima: espaço visto pela janela
const ALTURA_PAREDE := 16
const ALCANCE_LANTERNA := 130.0
const ABERTURA_LANTERNA := 90.0 # Graus, igual à lanterna do jogador
const VELOCIDADE_PATRULHA := 24.0
const PAUSA_NA_QUINA := 1.4 # Segundos olhando em volta em cada ponto da ronda
# Ronda do Traco: fica à direita, longe do título e dos botões
const RONDA := [Vector2(250, 176), Vector2(440, 176), Vector2(440, 236), Vector2(250, 236)]

var _painel_opcoes: CenterContainer
var _tempo: float = 0.0
var _espaco: Sprite2D
var _traco: Sprite2D
var _lanterna: PointLight2D
var _alarme: PointLight2D
var _titulo: Label
var _indice_ronda: int = 0
var _pausa: float = 0.0
var _direcao: float = 0.0 # Para onde o Traco está virado (radianos)
var _aliens: Array[Sprite2D] = []
var _globs: Array[Sprite2D] = []

func _ready() -> void:
	# "and_offsets": sem isso o Control raiz fica com tamanho 0x0 e tudo vai pro canto
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://Scripts/tema_pixel.gd").criar()
	get_tree().paused = false
	_criar_cenario()
	_criar_interface()

func _process(delta: float) -> void:
	_tempo += delta
	_espaco.region_rect.position.x += delta * 6.0 # Nave "andando": o espaço passa devagar
	_alarme.energy = 0.25 + 0.55 * maxf(sin(_tempo * 3.0), 0.0)
	_patrulhar(delta)
	_atualizar_aliens()
	for i in _globs.size():
		var glob := _globs[i]
		glob.frame = int(_tempo * 10.0 + i * 3) % glob.hframes
		glob.position.y += sin(_tempo * 2.0 + i) * 0.05
	# Letreiro "falhando" de vez em quando, como a lanterna com pouca energia
	_titulo.modulate.a = 0.35 if fmod(_tempo, 5.3) > 5.15 else 1.0

# ──────────────────────────────────────────────
#  Cena do fundo
# ──────────────────────────────────────────────

func _criar_cenario() -> void:
	var cenario := Node2D.new()
	cenario.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Filhos herdam: pixel art nítida
	add_child(cenario)
	var tamanho := Vector2(480, 270)

	# Espaço pela janela: brilha sozinho (as estrelas não dependem da lanterna)
	_espaco = Sprite2D.new()
	_espaco.texture = TEX_ESPACO
	_espaco.centered = false
	_espaco.region_enabled = true
	_espaco.region_rect = Rect2(0, 400, tamanho.x, ALTURA_JANELA)
	_espaco.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_espaco.material = _material_sem_sombra()
	_espaco.modulate = Color(0.8, 0.8, 0.9)
	cenario.add_child(_espaco)

	var moldura := Node2D.new()
	moldura.draw.connect(func(): _desenhar_moldura(moldura, tamanho.x))
	cenario.add_child(moldura)

	var parede := _faixa_de_tile(Vector2i(6, 34), Rect2(0, ALTURA_JANELA, tamanho.x, ALTURA_PAREDE))
	cenario.add_child(parede)
	var piso := _faixa_de_tile(Vector2i(14, 17), Rect2(0, ALTURA_JANELA + ALTURA_PAREDE, tamanho.x, tamanho.y))
	cenario.add_child(piso)

	# Escuro da nave: só a lanterna, os Globs e o alarme iluminam
	var escuro := CanvasModulate.new()
	escuro.color = Color(0.09, 0.09, 0.14)
	cenario.add_child(escuro)

	_alarme = _criar_luz(_textura_redonda(), COR_ALERTA, 3.0)
	_alarme.position = Vector2(360, ALTURA_JANELA + 8)
	cenario.add_child(_alarme)

	for dados in [[Vector2(305, 132), 0], [Vector2(405, 256), 4]]:
		var glob := _sprite(TEX_GLOB, 8, dados[0])
		glob.frame = dados[1]
		glob.material = _material_sem_sombra()
		cenario.add_child(glob)
		var brilho := _criar_luz(_textura_redonda(), Color(0.4, 0.85, 1.0), 0.6)
		glob.add_child(brilho)
		_globs.append(glob)

	# Aliens escondidos nos cantos escuros: só aparecem quando a lanterna passa
	for dados in [[TEX_ESPECIME, 4, Vector2(462, 132), PI], [TEX_MUX, 5, Vector2(214, 254), 0.0]]:
		var alien := _sprite(dados[0], dados[1], dados[2])
		alien.rotation = dados[3]
		cenario.add_child(alien)
		_aliens.append(alien)

	_traco = _sprite(TEX_TRACO, 4, RONDA[0])
	_traco.material = _material_sem_sombra()
	_traco.modulate = Color(0.85, 0.85, 0.85)
	cenario.add_child(_traco)
	_lanterna = _criar_luz(_textura_cone(), Color(1.0, 1.0, 0.92), ALCANCE_LANTERNA / 64.0)
	_lanterna.energy = 1.1
	cenario.add_child(_lanterna)

# Janela: barras verticais escuras dividindo o espaço em painéis, com borda em cima e embaixo
func _desenhar_moldura(no: Node2D, largura: float) -> void:
	var cor := Color(0.16, 0.17, 0.22)
	no.draw_rect(Rect2(0, 0, largura, 4), cor)
	no.draw_rect(Rect2(0, ALTURA_JANELA - 3, largura, 3), cor)
	var x := 0.0
	while x <= largura:
		no.draw_rect(Rect2(x - 3, 0, 6, ALTURA_JANELA), cor)
		x += 120.0

# Um tile do tileset das fases repetido numa faixa (TextureRect em modo lado a lado)
func _faixa_de_tile(tile: Vector2i, area: Rect2) -> TextureRect:
	var imagem := TEX_PISOS.get_image().get_region(Rect2i(tile * 16, Vector2i(16, 16)))
	var faixa := TextureRect.new()
	faixa.texture = ImageTexture.create_from_image(imagem)
	faixa.stretch_mode = TextureRect.STRETCH_TILE
	faixa.position = area.position
	faixa.size = area.size
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return faixa

func _sprite(textura: Texture2D, quadros: int, posicao: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.hframes = quadros
	sprite.position = posicao
	return sprite

# ──────────────────────────────────────────────
#  Animação: ronda do Traco e aliens
# ──────────────────────────────────────────────

func _patrulhar(delta: float) -> void:
	var alvo: Vector2 = RONDA[_indice_ronda]
	var varredura := 0.0
	if _pausa > 0.0:
		# Parado na quina: olha pros lados antes de seguir
		_pausa -= delta
		varredura = sin((PAUSA_NA_QUINA - _pausa) / PAUSA_NA_QUINA * TAU) * 0.8
		_traco.frame = 0
	elif _traco.position.distance_to(alvo) < 1.0:
		_indice_ronda = (_indice_ronda + 1) % RONDA.size()
		_pausa = PAUSA_NA_QUINA
	else:
		_direcao = lerp_angle(_direcao, _traco.position.angle_to_point(alvo), minf(delta * 6.0, 1.0))
		_traco.position = _traco.position.move_toward(alvo, VELOCIDADE_PATRULHA * delta)
		_traco.frame = int(_tempo * 6.0) % _traco.hframes
		varredura = sin(_tempo * 1.7) * 0.25
	# O sprite foi desenhado olhando pra cima: +90° pra olhar na direção da ronda
	_traco.rotation = _direcao + PI / 2.0
	_lanterna.position = _traco.position
	_lanterna.rotation = _direcao + varredura

func _atualizar_aliens() -> void:
	var meia_abertura := deg_to_rad(ABERTURA_LANTERNA / 2.0)
	for i in _aliens.size():
		var alien := _aliens[i]
		var para_alien := alien.position - _lanterna.position
		var na_luz := para_alien.length() < ALCANCE_LANTERNA * 0.9 \
			and absf(angle_difference(_lanterna.rotation, para_alien.angle())) < meia_abertura
		# Na luz congela, igual no jogo; no escuro fica mexendo
		alien.modulate = COR_CONGELADO if na_luz else Color.WHITE
		if not na_luz:
			alien.frame = int(_tempo * 5.0 + i * 2) % alien.hframes

# ──────────────────────────────────────────────
#  Luzes e texturas
# ──────────────────────────────────────────────

func _criar_luz(textura: Texture2D, cor: Color, escala: float) -> PointLight2D:
	var luz := PointLight2D.new()
	luz.texture = textura
	luz.color = cor
	luz.texture_scale = escala
	return luz

func _material_sem_sombra() -> CanvasItemMaterial:
	var material_luz := CanvasItemMaterial.new()
	material_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material_luz

func _textura_redonda() -> GradientTexture2D:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	return textura

# Cone da lanterna (mesma ideia do cone_light_2d.gd, numa resolução menor pra gerar rápido)
func _textura_cone() -> ImageTexture:
	const TAMANHO := 128
	var centro := TAMANHO / 2.0
	var meio := deg_to_rad(ABERTURA_LANTERNA / 2.0)
	var borda := deg_to_rad(10.0)
	var imagem := Image.create(TAMANHO, TAMANHO, false, Image.FORMAT_RGBA8)
	for y in TAMANHO:
		for x in TAMANHO:
			var d := Vector2(x - centro, y - centro)
			var distancia := d.length() / centro
			var angulo := absf(d.angle())
			var fator_angular := 1.0 - smoothstep(meio, meio + borda, angulo)
			var fator_distancia := maxf(1.0 - pow(distancia, 1.5), 0.0)
			imagem.set_pixel(x, y, Color(1, 1, 1, fator_angular * fator_distancia))
	return ImageTexture.create_from_image(imagem)

# ──────────────────────────────────────────────
#  Interface
# ──────────────────────────────────────────────

func _criar_interface() -> void:
	# Numa CanvasLayer à parte: o escuro da cena (CanvasModulate) não apaga os botões
	var camada := CanvasLayer.new()
	add_child(camada)
	var ui := Control.new()
	ui.theme = theme
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Bordas escurecidas: puxa o olho pro centro e pros botões
	var vinheta := TextureRect.new()
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0, 0, 0, 0))
	gradiente.add_point(0.6, Color(0, 0, 0, 0.1))
	gradiente.set_color(gradiente.get_point_count() - 1, Color(0, 0, 0, 0.75))
	var textura_vinheta := GradientTexture2D.new()
	textura_vinheta.gradient = gradiente
	textura_vinheta.fill = GradientTexture2D.FILL_RADIAL
	textura_vinheta.fill_from = Vector2(0.5, 0.5)
	textura_vinheta.fill_to = Vector2(1.05, 0.5)
	vinheta.texture = textura_vinheta
	vinheta.stretch_mode = TextureRect.STRETCH_SCALE
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(vinheta)
	vinheta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var coluna := VBoxContainer.new()
	coluna.position = Vector2(24, 18)
	coluna.add_theme_constant_override("separation", 0)
	ui.add_child(coluna)

	_titulo = _rotulo(TITULO, 24, COR_TITULO)
	coluna.add_child(_titulo)
	var subtitulo := _rotulo(SUBTITULO, 16, COR_DESTAQUE)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coluna.add_child(subtitulo)

	var botoes := VBoxContainer.new()
	botoes.position = Vector2(24, 126)
	botoes.custom_minimum_size = Vector2(150, 0)
	botoes.add_theme_constant_override("separation", 5)
	ui.add_child(botoes)

	if Persistencia.tem_save():
		var botao_continuar := _criar_botao("CONTINUAR")
		botao_continuar.pressed.connect(_continuar)
		botoes.add_child(botao_continuar)

	var botao_novo := _criar_botao("NOVO JOGO")
	botao_novo.pressed.connect(_novo_jogo)
	botoes.add_child(botao_novo)

	var botao_opcoes := _criar_botao("OPÇÕES")
	botao_opcoes.pressed.connect(_abrir_opcoes)
	botoes.add_child(botao_opcoes)

	var botao_fechar := _criar_botao("FECHAR")
	botao_fechar.pressed.connect(func(): get_tree().quit())
	botoes.add_child(botao_fechar)

	# Teclado/controle também navegam: já começa com o primeiro botão selecionado
	(botoes.get_child(0) as Button).grab_focus.call_deferred()

	# Preso no canto de baixo à direita, crescendo pra dentro da tela
	var rodape := _rotulo(RODAPE, 8, Color(COR_TEXTO, 0.45))
	rodape.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	rodape.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rodape.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rodape.offset_left = -8
	rodape.offset_right = -8
	rodape.offset_top = -8
	rodape.offset_bottom = -8
	ui.add_child(rodape)

	_painel_opcoes = _criar_painel_opcoes()
	ui.add_child(_painel_opcoes)
	_painel_opcoes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo.add_theme_constant_override("outline_size", 4)
	return rotulo

# Botão escuro com a borda esquerda ciano; selecionado, a borda engrossa e aparece a setinha
func _criar_botao(texto: String) -> Button:
	var botao := Button.new()
	botao.text = "  " + texto
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.custom_minimum_size = Vector2(150, 20)
	botao.add_theme_font_size_override("font_size", 8)
	botao.add_theme_color_override("font_color", COR_TEXTO)
	botao.add_theme_color_override("font_hover_color", Color.WHITE)
	botao.add_theme_color_override("font_focus_color", Color.WHITE)
	botao.add_theme_color_override("font_pressed_color", COR_TITULO)
	botao.add_theme_stylebox_override("normal", _estilo_botao(Color(0.02, 0.04, 0.07, 0.72), COR_DESTAQUE.darkened(0.45), 2))
	var selecionado := _estilo_botao(Color(0.04, 0.12, 0.18, 0.9), COR_DESTAQUE, 4)
	botao.add_theme_stylebox_override("hover", selecionado)
	botao.add_theme_stylebox_override("focus", selecionado)
	botao.add_theme_stylebox_override("pressed", _estilo_botao(Color(0.08, 0.2, 0.28, 0.95), COR_TITULO, 4))
	# O mouse passando por cima também seleciona: setinha e foco ficam num botão só
	botao.mouse_entered.connect(botao.grab_focus)
	botao.focus_entered.connect(func(): botao.text = "> " + texto)
	botao.focus_exited.connect(func(): botao.text = "  " + texto)
	return botao

# Botão de escolha (tela cheia/janela): mesmo visual dos outros, marcado em amarelo quando ativo
func _criar_opcao(texto: String, grupo: ButtonGroup) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.toggle_mode = true
	botao.button_group = grupo
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.custom_minimum_size = Vector2(0, 20)
	botao.add_theme_font_size_override("font_size", 8)
	botao.add_theme_color_override("font_color", COR_TEXTO)
	botao.add_theme_color_override("font_hover_color", Color.WHITE)
	botao.add_theme_color_override("font_focus_color", Color.WHITE)
	botao.add_theme_color_override("font_pressed_color", COR_TITULO)
	botao.add_theme_color_override("font_hover_pressed_color", COR_TITULO)
	botao.add_theme_stylebox_override("normal", _estilo_botao(Color(0.02, 0.04, 0.07, 0.72), COR_DESTAQUE.darkened(0.45), 2))
	var selecionado := _estilo_botao(Color(0.04, 0.12, 0.18, 0.9), COR_DESTAQUE, 4)
	botao.add_theme_stylebox_override("hover", selecionado)
	botao.add_theme_stylebox_override("focus", selecionado)
	var marcado := _estilo_botao(Color(0.08, 0.2, 0.28, 0.95), COR_TITULO, 4)
	botao.add_theme_stylebox_override("pressed", marcado)
	botao.add_theme_stylebox_override("hover_pressed", marcado)
	for estilo in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		var caixa_estilo := botao.get_theme_stylebox(estilo) as StyleBoxFlat
		caixa_estilo.content_margin_left = 4
		caixa_estilo.content_margin_right = 4
	return botao

func _estilo_botao(fundo: Color, borda: Color, largura_borda: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = borda
	estilo.border_width_left = largura_borda
	estilo.set_corner_radius_all(2)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	return estilo

# ──────────────────────────────────────────────
#  Ações
# ──────────────────────────────────────────────

# Com save existente, pede confirmação antes de apagar o progresso
func _novo_jogo() -> void:
	if not Persistencia.tem_save():
		_comecar_novo_jogo()
		return
	var dialogo := ConfirmationDialog.new()
	dialogo.title = "Novo jogo"
	dialogo.dialog_text = "Isso vai apagar seu progresso salvo. Continuar?"
	dialogo.ok_button_text = "Apagar e começar"
	dialogo.cancel_button_text = "Cancelar"
	dialogo.confirmed.connect(_comecar_novo_jogo)
	dialogo.canceled.connect(dialogo.queue_free)
	dialogo.theme = theme
	add_child(dialogo)
	dialogo.popup_centered()

func _comecar_novo_jogo() -> void:
	Persistencia.iniciar_novo_jogo()
	get_tree().change_scene_to_file(Persistencia.PRIMEIRA_FASE)

func _continuar() -> void:
	get_tree().change_scene_to_file(Persistencia.obter_fase_salva())

func _abrir_opcoes() -> void:
	_painel_opcoes.visible = true
	(_painel_opcoes.find_child("Volume", true, false) as Control).grab_focus()

func _criar_painel_opcoes() -> CenterContainer:
	var centro := CenterContainer.new()
	centro.visible = false

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.03, 0.06, 0.95)
	estilo.border_color = COR_DESTAQUE
	estilo.set_border_width_all(1)
	estilo.border_width_left = 3
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(12)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size = Vector2(200, 0)
	caixa.add_theme_constant_override("separation", 8)
	painel.add_child(caixa)

	var titulo := _rotulo("OPÇÕES", 16, COR_TITULO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(titulo)

	caixa.add_child(_rotulo("VOLUME", 8, COR_TEXTO))

	var slider := HSlider.new()
	slider.name = "Volume"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = Persistencia.volume_master
	slider.value_changed.connect(Persistencia.definir_volume)
	slider.drag_ended.connect(func(_mudou: bool): Persistencia.salvar_config())
	caixa.add_child(slider)

	# Tela: dois botões lado a lado, o da opção atual fica marcado
	caixa.add_child(_rotulo("TELA", 8, COR_TEXTO))
	var linha_tela := HBoxContainer.new()
	linha_tela.add_theme_constant_override("separation", 4)
	caixa.add_child(linha_tela)
	var grupo := ButtonGroup.new()
	for dados in [["TELA CHEIA", true], ["JANELA", false]]:
		var opcao := _criar_opcao(dados[0], grupo)
		opcao.button_pressed = Persistencia.tela_cheia == dados[1]
		opcao.pressed.connect(Persistencia.definir_tela_cheia.bind(dados[1]))
		linha_tela.add_child(opcao)

	var botao_voltar := _criar_botao("VOLTAR")
	botao_voltar.pressed.connect(func():
		Persistencia.salvar_config()
		centro.visible = false
	)
	caixa.add_child(botao_voltar)

	return centro
