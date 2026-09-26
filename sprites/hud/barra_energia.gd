extends TextureProgressBar
## Barra de energia do astronauta.
## Configure no Inspector: Under = barra_fundo.png, Over = barra_moldura.png,
## Progress = barra_preenchimento_ciano.png, Fill Mode = Left to Right,
## Progress Offset = (4, 3), Min 0, Max 100.

@export var tex_ciano: Texture2D = preload("res://sprites/hud/barra_preenchimento_ciano.png")
@export var tex_amarelo: Texture2D = preload("res://sprites/hud/barra_preenchimento_amarelo.png")
@export var tex_vermelho: Texture2D = preload("res://sprites/hud/barra_preenchimento_vermelho.png")
@export var moldura_normal: Texture2D = preload("res://sprites/hud/barra_moldura.png")
@export var moldura_alerta: Texture2D = preload("res://sprites/hud/barra_moldura_alerta.png")
@export var limite_amarelo := 50.0
@export var limite_vermelho := 20.0
@export var dreno_por_segundo := 2.0

var _t := 0.0

func _process(delta: float) -> void:
	value = max(value - dreno_por_segundo * delta, min_value)
	var pct := ratio * 100.0
	if pct <= limite_vermelho:
		texture_progress = tex_vermelho
		_t += delta
		texture_over = moldura_alerta if int(_t * 4.0) % 2 == 0 else moldura_normal
	else:
		texture_progress = tex_amarelo if pct <= limite_amarelo else tex_ciano
		texture_over = moldura_normal
		_t = 0.0

## Chame ao coletar um espírito de energia.
func recarregar(qtd: float) -> void:
	value = min(value + qtd, max_value)
