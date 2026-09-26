extends CanvasLayer
## Menu de pausa: Esc pausa tudo e mostra "Continuar" / "Voltar ao menu";
## Esc de novo (ou o botão) continua o jogo.

const CAMINHO_MENU := "res://Scenes/menu_principal.tscn"

var _raiz: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_criar_interface()
	_raiz.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _raiz.visible:
		_continuar()
	elif not get_tree().paused:
		_pausar()
	else:
		return # Jogo já pausado por outra tela (ex.: tela de morte): Esc não faz nada aqui
	get_viewport().set_input_as_handled()

func _pausar() -> void:
	_raiz.visible = true
	get_tree().paused = true

func _continuar() -> void:
	_raiz.visible = false
	get_tree().paused = false

func _voltar_ao_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(CAMINHO_MENU)

func _criar_interface() -> void:
	_raiz = Control.new()
	add_child(_raiz)
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = preload("res://Scripts/tema_pixel.gd").criar()

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	_raiz.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	centro.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "PAUSADO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	titulo.add_theme_constant_override("outline_size", 4)
	caixa.add_child(titulo)

	var botao_continuar := _criar_botao("CONTINUAR")
	botao_continuar.pressed.connect(_continuar)
	caixa.add_child(botao_continuar)

	var botao_menu := _criar_botao("VOLTAR AO MENU")
	botao_menu.pressed.connect(_voltar_ao_menu)
	caixa.add_child(botao_menu)

func _criar_botao(texto: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(140, 20)
	botao.add_theme_font_size_override("font_size", 8)
	botao.focus_mode = Control.FOCUS_NONE
	return botao
