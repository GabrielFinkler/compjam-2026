extends CharacterBody2D

signal energia_recarregada

# ──────────────────────────────────────────────
# Parâmetros de Movimento
# ──────────────────────────────────────────────
@export var velocidade: float = 60.0

# ──────────────────────────────────────────────
# Parâmetros de Energia e Luz
# ──────────────────────────────────────────────
@export var energia_maxima: float = 100.0
@export var consumo_por_segundo: float = 2.0
@export var consumo_foco_por_seg: float = 8.0 # Gasta 4x mais no modo foco!
@export var alcance_luz_maximo: float = 120.0
@export var alcance_luz_minimo: float = 32.0
@export var largura_feixe_foco: float = 14.0 # Largura (px) do feixe do modo foco, no fim do alcance
@export_range(0.0, 1.0) var proporcao_base_feixe: float = 0.35 # Largura perto do personagem, em proporção da largura final

const TAMANHO_TEXTURA_FEIXE := Vector2i(256, 32)
const LIMIAR_FOCO_CONGELA := 0.9 # A partir de quanto do foco o feixe já congela monstros

var energia_atual: float
var fator_foco: float = 0.0 # 0.0 = cone espalhado, 1.0 = feixe retangular focado
var _alcance_atual: float = 0.0
var _morto: bool = false

@onready var luz: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var feixe: PointLight2D
var hud: CanvasLayer

func _ready() -> void:
	energia_atual = energia_maxima
	_criar_feixe_foco()
	hud = preload("res://Scripts/hud_energia.gd").new()
	add_child(hud)
	Persistencia.registrar_fase(get_tree().current_scene.scene_file_path)

func _process(delta: float) -> void:
	# 1. Verifica entrada do Modo Foco
	var modo_foco = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# Anima a transição do foco (demora cerca de 0.2s para ir de 0 a 1)
	if modo_foco and energia_atual > 0:
		fator_foco = move_toward(fator_foco, 1.0, delta * 5.0)
	else:
		fator_foco = move_toward(fator_foco, 0.0, delta * 5.0)
	
	# 2. Drena Energia
	var taxa_consumo = lerp(consumo_por_segundo, consumo_foco_por_seg, fator_foco)
	if energia_atual > 0:
		energia_atual -= taxa_consumo * delta
		energia_atual = maxf(energia_atual, 0.0)
	if energia_atual <= 0.0:
		morrer()
	
	# 3. Aplica os Efeitos Visuais na Luz
	if luz:
		var porcentagem_energia = energia_atual / energia_maxima
		
		# Distância base afetada pela energia
		var distancia_base = lerp(alcance_luz_minimo, alcance_luz_maximo, porcentagem_energia)
		# No modo foco total, a distância ignora a energia e vai pro máximo
		var distancia_final = lerp(distancia_base, alcance_luz_maximo, fator_foco)
		luz.set_alcance(distancia_final)
		_alcance_atual = distancia_final
		
		# O cone se fecha (achata no eixo Y) e apaga enquanto o feixe do foco acende
		luz.energy = lerp(1.0, 0.0, fator_foco)
		luz.scale.y = lerp(1.0, 0.15, fator_foco)

		# Feixe do foco: nasce na nave, comprimento = alcance atual, mais forte
		feixe.enabled = fator_foco > 0.0
		feixe.energy = lerp(0.0, 3.5, fator_foco)
		feixe.scale = Vector2(
			distancia_final / TAMANHO_TEXTURA_FEIXE.x,
			largura_feixe_foco / TAMANHO_TEXTURA_FEIXE.y
		)
	
	hud.atualizar(energia_atual, energia_maxima)

func _physics_process(delta: float) -> void:
	var direcao: Vector2 = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = direcao * velocidade
	look_at(get_global_mouse_position())
	move_and_slide()

	# Animação de caminhada só enquanto anda; parado volta ao primeiro quadro
	if direcao != Vector2.ZERO:
		sprite.play("andar")
	else:
		sprite.stop()

func recarregar_energia() -> void:
	energia_atual = energia_maxima
	energia_recarregada.emit()

# O feixe é um trapézio à frente da nave: estreito na base, largura cheia no fim do alcance
func esta_no_feixe_foco(ponto_global: Vector2, margem: float = 0.0) -> bool:
	if fator_foco < LIMIAR_FOCO_CONGELA:
		return false
	var p := to_local(ponto_global)
	if p.x < 0.0 or p.x > _alcance_atual + margem:
		return false
	var t := clampf(p.x / _alcance_atual, 0.0, 1.0)
	var meia_largura := largura_feixe_foco / 2.0 * lerpf(proporcao_base_feixe, 1.0, t)
	return absf(p.y) <= meia_largura + margem

func morrer() -> void:
	# Dois monstros encostando no mesmo frame não podem abrir duas telas de morte
	if _morto:
		return
	_morto = true
	get_tree().root.add_child(preload("res://Scripts/tela_morte.gd").new())

# Cria (uma única vez) a luz do modo foco, irmã do cone: um feixe que alarga
# levemente da base (perto do personagem) até o fim do alcance.
func _criar_feixe_foco() -> void:
	var imagem := Image.create(TAMANHO_TEXTURA_FEIXE.x, TAMANHO_TEXTURA_FEIXE.y, false, Image.FORMAT_RGBA8)
	for x in TAMANHO_TEXTURA_FEIXE.x:
		var u: float = float(x) / TAMANHO_TEXTURA_FEIXE.x
		var fator_distancia: float = 1.0 - pow(u, luz.atenuacao_distancia)
		var meia_largura: float = lerpf(proporcao_base_feixe, 1.0, u)
		for y in TAMANHO_TEXTURA_FEIXE.y:
			var v: float = absf((y + 0.5) / TAMANHO_TEXTURA_FEIXE.y * 2.0 - 1.0)
			var fator_lateral: float = 1.0 - smoothstep(meia_largura * 0.6, meia_largura, v)
			imagem.set_pixel(x, y, Color(1, 1, 1, fator_lateral * fator_distancia))

	feixe = PointLight2D.new()
	feixe.texture = ImageTexture.create_from_image(imagem)
	# Empurra a textura pra frente: a borda de trás do retângulo fica exatamente na nave
	feixe.offset = Vector2(TAMANHO_TEXTURA_FEIXE.x / 2.0, 0.0)
	feixe.position = luz.position
	feixe.color = luz.color
	feixe.shadow_enabled = luz.shadow_enabled
	feixe.enabled = false
	luz.add_sibling(feixe)
