extends RefCounted
## Tema compartilhado com a fonte pixel art (Press Start 2P, licença OFL em fonts/OFL.txt).
## Use tamanhos múltiplos de 8 (8, 16, 24, 32, 40, 48...): a fonte foi desenhada numa
## grade de 8px e fica borrada/torta em outros tamanhos.

const FONTE := preload("res://Resources/fonts/PressStart2P-Regular.ttf")

static func criar() -> Theme:
	var fonte: FontFile = FONTE
	# Sem suavização: bordas duras, cara de pixel art
	fonte.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	fonte.hinting = TextServer.HINTING_NONE
	fonte.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var tema := Theme.new()
	tema.default_font = fonte
	tema.default_font_size = 8
	return tema
