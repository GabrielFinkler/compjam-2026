extends CanvasLayer
## Tela de "Você morreu": pausa o jogo e oferece reiniciar a fase ou voltar ao menu.
## Texto grande, vermelho, com contorno preto grosso — estilo provisório enquanto
## não temos uma fonte pixel art de verdade no projeto (dá pra trocar depois).

const CAMINHO_MENU := "res://Scenes/menu_principal.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_criar_interface()
	get_tree().paused = true

func _criar_interface() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.75)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.theme = preload("res://Scripts/tema_pixel.gd").criar()

	var caixa := VBoxContainer.new()
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", 10)
	centro.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "VOCÊ MORREU!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color(0.9, 0.05, 0.05))
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	titulo.add_theme_constant_override("outline_size", 4)
	caixa.add_child(titulo)

	# Pisca o texto pra dar um clima mais aflito
	var tween := create_tween().set_loops()
	tween.tween_property(titulo, "modulate:a", 0.4, 0.5)
	tween.tween_property(titulo, "modulate:a", 1.0, 0.5)

	var botao_reiniciar := _criar_botao("REINICIAR FASE")
	botao_reiniciar.pressed.connect(_reiniciar_fase)
	caixa.add_child(botao_reiniciar)

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

# A tela fica no root (fora da cena atual), então a troca de cena não a apaga sozinha
func _reiniciar_fase() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()

func _voltar_ao_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(CAMINHO_MENU)
	queue_free()
