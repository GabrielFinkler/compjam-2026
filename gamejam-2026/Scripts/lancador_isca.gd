extends Node
## Lançador de iscas luminosas (power-up do Sinalizador). É criado pelo item e fica
## pendurado no jogador. [Q] ou botão direito do mouse: gasta energia da lanterna e
## arremessa uma isca na direção do mouse (ela para antes de atravessar paredes).
## Uso único: cada item dá uma carga; sem cargas, o lançador (e o ícone no HUD) some.
## Os valores vêm do item (item_isca.gd), editáveis no Inspector da fase.

const CENA_ISCA := preload("res://Scenes/isca_luminosa.tscn")
const TEX_ICONE := preload("res://Imagens/space_sprites_16px.png")
const REGIAO_ICONE := Rect2(80, 240, 16, 16) # luz_alerta
const MARGEM_PAREDE := 6.0

var custo_energia: float = 15.0
var cargas: int = 1
var alcance_lancamento: float = 110.0
var duracao_isca: float = 5.0
var raio_atracao: float = 220.0

var _jogador: CharacterBody2D
var _hud: HBoxContainer
var _texto: Label


func _ready() -> void:
	_jogador = get_parent()
	_criar_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lancar_isca"):
		get_viewport().set_input_as_handled()
		_lancar()


func _process(_delta: float) -> void:
	_hud.modulate.a = 1.0 if _pode_lancar() else 0.35
	_texto.text = "ISCA [Q]" if cargas == 1 else "ISCA x%d [Q]" % cargas


# Nunca deixa a isca matar o jogador: precisa sobrar energia depois do custo
func _pode_lancar() -> bool:
	return cargas > 0 and _jogador.energia_atual > custo_energia and not _jogador.controle_bloqueado


func _lancar() -> void:
	if not _pode_lancar():
		return
	_jogador.energia_atual -= custo_energia
	cargas -= 1

	var origem := _jogador.global_position
	var alvo := _jogador.get_global_mouse_position()
	var direcao := origem.direction_to(alvo)
	var destino := origem + direcao * minf(origem.distance_to(alvo), alcance_lancamento)
	var consulta := PhysicsRayQueryParameters2D.create(origem, destino)
	consulta.exclude = [_jogador.get_rid()]
	var batida := _jogador.get_world_2d().direct_space_state.intersect_ray(consulta)
	if not batida.is_empty():
		destino = batida.position - direcao * MARGEM_PAREDE

	var isca := CENA_ISCA.instantiate()
	isca.duracao = duracao_isca
	isca.raio_atracao = raio_atracao
	get_tree().current_scene.add_child(isca)
	isca.global_position = origem
	isca.lancar_para(destino)
	if cargas <= 0:
		queue_free()


# Ícone + texto logo abaixo da barra de energia (canto superior esquerdo)
func _criar_hud() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	_hud = HBoxContainer.new()
	_hud.position = Vector2(6, 26)
	_hud.add_theme_constant_override("separation", 3)
	_hud.theme = preload("res://Scripts/tema_pixel.gd").criar()
	camada.add_child(_hud)
	var icone := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = TEX_ICONE
	atlas.region = REGIAO_ICONE
	icone.texture = atlas
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud.add_child(icone)
	_texto = Label.new()
	_texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hud.add_child(_texto)
