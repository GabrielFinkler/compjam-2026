extends Control
## Menu inicial do jogo: novo jogo, continuar (se houver save), opções e fechar.

var _painel_opcoes: CenterContainer

func _ready() -> void:
	# "and_offsets": sem isso o Control raiz fica com tamanho 0x0 e tudo vai pro canto
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://Scripts/tema_pixel.gd").criar()
	get_tree().paused = false
	_criar_interface()

func _criar_interface() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.03, 0.05)
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Título e botões na mesma coluna: ficam centralizados juntos
	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size = Vector2(260, 0)
	caixa.add_theme_constant_override("separation", 14)
	centro.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "GAMEJAM 2026"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	caixa.add_child(titulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 30)
	caixa.add_child(espaco)

	if Persistencia.tem_save():
		var botao_continuar := _criar_botao("CONTINUAR")
		botao_continuar.pressed.connect(_continuar)
		caixa.add_child(botao_continuar)

	var botao_novo := _criar_botao("NOVO JOGO")
	botao_novo.pressed.connect(_novo_jogo)
	caixa.add_child(botao_novo)

	var botao_opcoes := _criar_botao("OPÇÕES")
	botao_opcoes.pressed.connect(func(): _painel_opcoes.visible = true)
	caixa.add_child(botao_opcoes)

	var botao_fechar := _criar_botao("FECHAR")
	botao_fechar.pressed.connect(func(): get_tree().quit())
	caixa.add_child(botao_fechar)

	_painel_opcoes = _criar_painel_opcoes()
	add_child(_painel_opcoes)
	_painel_opcoes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _criar_botao(texto: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(260, 44)
	botao.add_theme_font_size_override("font_size", 16)
	return botao

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

func _criar_painel_opcoes() -> CenterContainer:
	var centro := CenterContainer.new()
	centro.visible = false

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.9)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(24)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size = Vector2(300, 0)
	caixa.add_theme_constant_override("separation", 12)
	painel.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "OPÇÕES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	caixa.add_child(titulo)

	var rotulo_volume := Label.new()
	rotulo_volume.text = "Volume"
	caixa.add_child(rotulo_volume)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = Persistencia.volume_master
	slider.value_changed.connect(Persistencia.definir_volume)
	slider.drag_ended.connect(func(_mudou: bool): Persistencia.salvar_config())
	caixa.add_child(slider)

	var botao_voltar := _criar_botao("VOLTAR")
	botao_voltar.pressed.connect(func():
		Persistencia.salvar_config()
		centro.visible = false
	)
	caixa.add_child(botao_voltar)

	return centro
