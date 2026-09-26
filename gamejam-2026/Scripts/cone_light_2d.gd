@tool
extends PointLight2D
## Luz 2D em formato de cone (lanterna/holofote) com textura gerada proceduralmente.
##
## Permite alterar dinamicamente o ângulo de abertura, o alcance (comprimento)
## e a suavidade das bordas do cone em tempo de execução ou pelo Inspector.

# ──────────────────────────────────────────────
#  Parâmetros exportados (visíveis no Inspector)
# ──────────────────────────────────────────────

## Ângulo de abertura do cone em graus (metade para cada lado).
@export_range(5.0, 180.0, 0.5) var angulo_cone: float = 150.0:
	set(valor):
		angulo_cone = valor
		_gerar_textura()

## Alcance (comprimento) do cone de luz em pixels.
@export_range(32.0, 2048.0, 1.0) var alcance: float = 350.0:
	set(valor):
		alcance = valor
		texture_scale = alcance / (resolucao_textura / 2.0)

## Suavidade da borda angular do cone em graus (gradiente de fade-out).
@export_range(0.0, 45.0, 0.5) var suavidade_borda: float = 8.0:
	set(valor):
		suavidade_borda = valor
		_gerar_textura()

## Suavidade da atenuação de distância (1.0 = linear, 2.0 = quadrática).
@export_range(0.5, 4.0, 0.1) var atenuacao_distancia: float = 1.5:
	set(valor):
		atenuacao_distancia = valor
		_gerar_textura()

## Resolução da textura gerada (largura e altura em pixels).
@export_range(64, 1024, 64) var resolucao_textura: int = 512:
	set(valor):
		resolucao_textura = valor
		_gerar_textura()

## Cor da luz do cone.
@export var cor_luz: Color = Color(1.0, 1.0, 0.95, 1.0):
	set(valor):
		cor_luz = valor
		color = cor_luz

# ──────────────────────────────────────────────
#  Variáveis internas
# ──────────────────────────────────────────────

var _textura_gerada: ImageTexture = null


# ──────────────────────────────────────────────
#  Lifecycle
# ──────────────────────────────────────────────

func _ready() -> void:
	color = cor_luz
	_gerar_textura()


# ──────────────────────────────────────────────
#  Métodos públicos para uso em runtime
# ──────────────────────────────────────────────

## Altera o ângulo de abertura do cone (em graus).
func set_angulo(graus: float) -> void:
	angulo_cone = clampf(graus, 5.0, 180.0)


## Altera o alcance (comprimento) do cone de luz (em pixels).
func set_alcance(pixels: float) -> void:
	alcance = clampf(pixels, 32.0, 2048.0)


## Altera a cor da luz.
func set_cor(cor: Color) -> void:
	cor_luz = cor


## Altera a suavidade da borda angular.
func set_suavidade(graus: float) -> void:
	suavidade_borda = clampf(graus, 0.0, 45.0)


# ──────────────────────────────────────────────
#  Geração procedural da textura do cone
# ──────────────────────────────────────────────

func _gerar_textura() -> void:
	var tamanho: int = resolucao_textura
	var centro: float = tamanho / 2.0
	var raio_max: float = centro  # raio máximo no espaço da textura

	# Converter ângulos para radianos (metade do ângulo total do cone)
	var meio_angulo: float = deg_to_rad(angulo_cone / 2.0)
	var suavidade_rad: float = deg_to_rad(suavidade_borda)

	var imagem: Image = Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)

	for y in range(tamanho):
		for x in range(tamanho):
			# Vetor do centro até o pixel atual
			var dx: float = x - centro
			var dy: float = y - centro

			# Distância normalizada (0 = centro, 1 = borda da textura)
			var dist: float = sqrt(dx * dx + dy * dy) / raio_max

			# Se está fora do raio, pixel totalmente transparente
			if dist > 1.0:
				imagem.set_pixel(x, y, Color(1, 1, 1, 0))
				continue

			# Ângulo do pixel em relação à direção do cone (para a DIREITA = 0 rad)
			# O PointLight2D já rotaciona com o nó pai, então o cone aponta para +X
			var angulo_pixel: float = abs(atan2(dy, dx))

			# Fator angular: 1.0 dentro do cone, fade na borda, 0.0 fora
			var fator_angular: float = 0.0
			if angulo_pixel <= meio_angulo:
				fator_angular = 1.0
			elif angulo_pixel <= meio_angulo + suavidade_rad and suavidade_rad > 0.0:
				# Suavização com curva smoothstep na transição
				var t: float = (angulo_pixel - meio_angulo) / suavidade_rad
				fator_angular = 1.0 - _smoothstep(t)
			else:
				fator_angular = 0.0

			# Fator de distância: atenuação gradual do centro para as bordas
			var fator_distancia: float = 1.0 - pow(dist, atenuacao_distancia)
			fator_distancia = maxf(fator_distancia, 0.0)

			# Alpha final = produto dos dois fatores
			var alpha: float = fator_angular * fator_distancia

			imagem.set_pixel(x, y, Color(1, 1, 1, alpha))

	# Criar ou atualizar a ImageTexture
	if _textura_gerada == null:
		_textura_gerada = ImageTexture.create_from_image(imagem)
	else:
		_textura_gerada.update(imagem)

	texture = _textura_gerada

	# Ajustar o texture_scale para que o alcance desejado corresponda ao raio visual
	# texture_scale = (alcance desejado em pixels) / (metade da resolução da textura)
	texture_scale = alcance / centro


## Interpolação suave (Hermite) para transições sem serrilhado.
func _smoothstep(t: float) -> float:
	var tc: float = clampf(t, 0.0, 1.0)
	return tc * tc * (3.0 - 2.0 * tc)
