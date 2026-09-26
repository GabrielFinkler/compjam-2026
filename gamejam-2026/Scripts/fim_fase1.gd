extends Control
## Tela de fim (de fase ou do jogo). Os textos ficam no Inspector de cada cena (ex.: fim_jogo.tscn)
## usam este mesmo script.

const CAMINHO_MENU := "res://Scenes/menu_principal.tscn"

@export var titulo: String = "FASE 1 CONCLUÍDA!"
@export_multiline var subtitulo: String = "Você escapou pela porta... por enquanto."

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

	var rotulo_titulo := Label.new()
	rotulo_titulo.text = titulo
	rotulo_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_titulo.add_theme_font_size_override("font_size", 24)
	rotulo_titulo.add_theme_color_override("font_color", Color(0.15, 0.68, 0.88))
	rotulo_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	rotulo_titulo.add_theme_constant_override("outline_size", 4)
	caixa.add_child(rotulo_titulo)

	var rotulo_subtitulo := Label.new()
	rotulo_subtitulo.text = subtitulo
	rotulo_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(rotulo_subtitulo)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 8)
	caixa.add_child(espaco)

	var botao := Button.new()
	botao.text = "VOLTAR AO MENU"
	botao.custom_minimum_size = Vector2(140, 20)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.pressed.connect(func(): get_tree().change_scene_to_file(CAMINHO_MENU))
	caixa.add_child(botao)
