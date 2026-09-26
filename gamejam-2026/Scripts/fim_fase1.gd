extends Control
## Tela de fim da fase 1 (provisória até existir a fase 2).

const CAMINHO_MENU := "res://Scenes/menu_principal.tscn"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://Scripts/tema_pixel.gd").criar()
	get_tree().paused = false

	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.03, 0.05)
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	centro.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "FASE 1 CONCLUÍDA!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color(0.15, 0.68, 0.88))
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	titulo.add_theme_constant_override("outline_size", 4)
	caixa.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Você escapou pelo teleporte... por enquanto."
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(subtitulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 8)
	caixa.add_child(espaco)

	var botao := Button.new()
	botao.text = "VOLTAR AO MENU"
	botao.custom_minimum_size = Vector2(140, 20)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.pressed.connect(func(): get_tree().change_scene_to_file(CAMINHO_MENU))
	caixa.add_child(botao)
