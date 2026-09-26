extends CanvasLayer
## HUD de energia no canto superior esquerdo: ícone do astronauta + barra.
## A barra muda de cor (ciano > amarelo > vermelho) e, com pouca energia,
## a moldura pisca em alerta e o astronauta fica com a cara "fraca".

const ESCALA := 3 # Pixel art em escala inteira pra não distorcer
const MARGEM := Vector2(16, 16)
const LIMITE_AMARELO := 0.5
const LIMITE_VERMELHO := 0.2

const TEX_FUNDO := preload("res://Imagens/hud/barra_fundo.png")
const TEX_MOLDURA := preload("res://Imagens/hud/barra_moldura.png")
const TEX_MOLDURA_ALERTA := preload("res://Imagens/hud/barra_moldura_alerta.png")
const TEX_CIANO := preload("res://Imagens/hud/barra_preenchimento_ciano.png")
const TEX_AMARELO := preload("res://Imagens/hud/barra_preenchimento_amarelo.png")
const TEX_VERMELHO := preload("res://Imagens/hud/barra_preenchimento_vermelho.png")
const TEX_ICONE := preload("res://Imagens/hud/icone_traco.png")
const TEX_ICONE_FRACO := preload("res://Imagens/hud/icone_traco_fraco.png")

var _barra: TextureProgressBar
var _icone: TextureRect
var _tempo_alerta := 0.0

func _ready() -> void:
	var linha := HBoxContainer.new()
	linha.position = MARGEM
	linha.scale = Vector2(ESCALA, ESCALA)
	linha.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_theme_constant_override("separation", 3)
	add_child(linha)

	_icone = TextureRect.new()
	_icone.texture = TEX_ICONE
	linha.add_child(_icone)

	_barra = TextureProgressBar.new()
	_barra.texture_under = TEX_FUNDO
	_barra.texture_over = TEX_MOLDURA
	_barra.texture_progress = TEX_CIANO
	_barra.texture_progress_offset = Vector2(4, 3)
	_barra.min_value = 0.0
	_barra.max_value = 100.0
	_barra.value = 100.0
	_barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(_barra)

func atualizar(valor: float, maximo: float) -> void:
	_barra.max_value = maximo
	_barra.value = valor

func _process(delta: float) -> void:
	var proporcao := _barra.ratio
	if proporcao <= LIMITE_VERMELHO:
		_barra.texture_progress = TEX_VERMELHO
		_icone.texture = TEX_ICONE_FRACO
		_tempo_alerta += delta
		_barra.texture_over = TEX_MOLDURA_ALERTA if int(_tempo_alerta * 4.0) % 2 == 0 else TEX_MOLDURA
	else:
		_barra.texture_progress = TEX_AMARELO if proporcao <= LIMITE_AMARELO else TEX_CIANO
		_icone.texture = TEX_ICONE
		_barra.texture_over = TEX_MOLDURA
		_tempo_alerta = 0.0
