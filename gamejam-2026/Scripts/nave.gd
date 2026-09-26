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
@export_range(0.0, 2.0) var brilho_personagem: float = 0.6 # Luz fraca própria do personagem, pra ele não sumir no escuro (a lanterna não clareia ele)
@export_range(0.0, 1.0) var forca_sombra_personagem: float = 0.45 # Quão escura é a sombra dele no chão (0 = nenhuma)
@export_range(0.0, 1.0) var limiar_energia_baixa: float = 0.3 # Abaixo dessa fração da energia, o personagem vai apagando e a lanterna falha

const TAMANHO_TEXTURA_FEIXE := Vector2i(256, 32)
const LIMIAR_FOCO_CONGELA := 0.9 # A partir de quanto do foco o feixe já congela monstros
const DURACAO_PISCADA := 0.07 # Segundos que dura cada falha da lanterna com energia baixa
# O sprite só é iluminado por luzes com esse bit, ou seja, só pela luz do corpo. A lanterna
# e o feixe do foco ficam de fora: iluminam o chão "por baixo" do boneco, sem clarear ele.
const CAMADA_LUZ_PERSONAGEM := 2
const DESLOCAMENTO_SOMBRA := Vector2(1, 3) # Igual à sombra dos objetos (sombra_suave_tiles.gd)
const RAIO_SOMBRA := 5.0

var energia_atual: float
var fator_foco: float = 0.0 # 0.0 = cone espalhado, 1.0 = feixe retangular focado
var _alcance_atual: float = 0.0
var _morto: bool = false
var _proxima_piscada: float = 0.0
var _piscando: float = 0.0
var controle_bloqueado: bool = false ## Ligado por minigames (ex.: máquina de reparo): o personagem fica parado
var em_cena: bool = false ## Ligado em cenas de história (historia.gd): não anda, não mira, não foca e não gasta energia

@onready var luz: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var feixe: PointLight2D
var _luz_corpo: PointLight2D
var _sombra: Node2D
var hud: CanvasLayer

func _ready() -> void:
	energia_atual = energia_maxima
	_criar_feixe_foco()
	_criar_luz_corpo()
	_criar_sombra()
	hud = preload("res://Scripts/hud_energia.gd").new()
	add_child(hud)
	Persistencia.registrar_fase(get_tree().current_scene.scene_file_path)

func _process(delta: float) -> void:
	# 1. Verifica entrada do Modo Foco
	# Na história o clique passa as falas: não pode acender o foco junto
	var modo_foco = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not em_cena
	
	# Anima a transição do foco (demora cerca de 0.2s para ir de 0 a 1)
	if modo_foco and energia_atual > 0:
		fator_foco = move_toward(fator_foco, 1.0, delta * 5.0)
	else:
		fator_foco = move_toward(fator_foco, 0.0, delta * 5.0)
	
	# 2. Drena Energia
	var taxa_consumo = lerp(consumo_por_segundo, consumo_foco_por_seg, fator_foco)
	if energia_atual > 0 and not em_cena:
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
		
		var falha := _atualizar_falha(delta, porcentagem_energia)

		# O cone se fecha (achata no eixo Y) e apaga enquanto o feixe do foco acende
		luz.energy = lerp(1.0, 0.0, fator_foco) * falha
		luz.scale.y = lerp(1.0, 0.15, fator_foco)

		# Feixe do foco: nasce na nave, comprimento = alcance atual, mais forte
		feixe.enabled = fator_foco > 0.0
		feixe.energy = lerp(0.0, 3.5, fator_foco) * falha
		feixe.scale = Vector2(
			distancia_final / TAMANHO_TEXTURA_FEIXE.x,
			largura_feixe_foco / TAMANHO_TEXTURA_FEIXE.y
		)
	
	hud.atualizar(energia_atual, energia_maxima)

# Com energia baixa o personagem vai escurecendo e a lanterna dá falhas rápidas, cada vez
# mais seguidas. Devolve o multiplicador da luz neste frame (1 = normal, menor = falhando).
func _atualizar_falha(delta: float, porcentagem_energia: float) -> float:
	var brilho := brilho_personagem
	var falha := 1.0
	if porcentagem_energia < limiar_energia_baixa:
		var t := 1.0 - porcentagem_energia / limiar_energia_baixa # 0 no limiar, 1 sem energia
		brilho *= lerpf(1.0, 0.55, t)
		_proxima_piscada -= delta
		if _proxima_piscada <= 0.0:
			_piscando = DURACAO_PISCADA
			_proxima_piscada = randf_range(lerpf(1.2, 0.15, t), lerpf(2.5, 0.5, t))
	if _piscando > 0.0:
		_piscando -= delta
		brilho *= 0.4
		falha = 0.35
	_luz_corpo.energy = brilho
	return falha

func _physics_process(_delta: float) -> void:
	if controle_bloqueado or em_cena:
		velocity = Vector2.ZERO
		sprite.stop()
		return
	var direcao: Vector2 = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = direcao * velocidade
	look_at(get_global_mouse_position())
	move_and_slide()
	# A sombra é filha do personagem mas não gira com a mira: sempre cai pro mesmo lado
	_sombra.global_rotation = 0.0
	_sombra.global_position = global_position + DESLOCAMENTO_SOMBRA

	# Animação de caminhada só enquanto anda; parado volta ao primeiro quadro
	if direcao != Vector2.ZERO:
		sprite.play("andar")
	else:
		sprite.stop()

## Chamado pelo pod de fuga: o personagem entra nele e some, para de gastar energia e
## os monstros não conseguem mais pegá-lo.
func embarcar() -> void:
	controle_bloqueado = true
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.visible = false
	_sombra.visible = false
	_luz_corpo.enabled = false

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
	feixe.range_item_cull_mask = 1 # Não ilumina o próprio personagem (ver CAMADA_LUZ_PERSONAGEM)
	feixe.enabled = false
	luz.add_sibling(feixe)

# Luz fraca e redonda que só pega no sprite do personagem: o centro fica mais claro que as
# bordas, o que dá volume ao boneco
func _criar_luz_corpo() -> void:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 32
	textura.height = 32
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	_luz_corpo = PointLight2D.new()
	_luz_corpo.texture = textura
	_luz_corpo.texture_scale = 0.75 # ~12 px de raio: cobre o boneco, some nas bordas
	_luz_corpo.color = luz.color
	_luz_corpo.energy = brilho_personagem
	_luz_corpo.range_item_cull_mask = CAMADA_LUZ_PERSONAGEM
	add_child(_luz_corpo)

# Sombra redonda no chão, embaixo do personagem, no mesmo estilo da sombra dos objetos
func _criar_sombra() -> void:
	_sombra = Node2D.new()
	_sombra.z_index = -1 # Por baixo do sprite, por cima do chão
	_sombra.draw.connect(_desenhar_sombra)
	add_child(_sombra)
	_sombra.position = DESLOCAMENTO_SOMBRA

# Miolo escuro com uma borda de 1 px mais clara, pra não ficar recortada
func _desenhar_sombra() -> void:
	_sombra.draw_circle(Vector2.ZERO, RAIO_SOMBRA + 1.0, Color(0, 0, 0, forca_sombra_personagem * 0.5))
	_sombra.draw_circle(Vector2.ZERO, RAIO_SOMBRA, Color(0, 0, 0, forca_sombra_personagem))
