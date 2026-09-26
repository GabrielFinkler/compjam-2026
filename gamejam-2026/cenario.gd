@tool
extends Node2D

## Gerenciador da Fase Introdutória da Nave Espacial
## Constrói e gerencia a progressão da fase conforme o layout:
## 1. Sala de Comando (início do astronauta)
## 2. Sala da Direita (aberta, com 4 PCs e terminal central interativo)
## 3. Sala da Esquerda (inicialmente trancada, com monstro e botão de emergência)
## 4. Corredor Norte (fechado até pressionar o botão da sala esquerda)
## 5. Saída (escotilha de escape no topo)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var hud: CanvasLayer = $HUD

# Dimensões do mapa (100x60 tiles = 1600x960 px)
const MAP_WIDTH: int = 100
const MAP_HEIGHT: int = 60
const SOURCE_ID: int = 0

# Atlas Coords no tileset_nave_16x16.png
const WALL_TL := Vector2i(0, 0)
const WALL_TOP := Vector2i(1, 0)
const WALL_TR := Vector2i(2, 0)
const WALL_LEFT := Vector2i(3, 0)
const WALL_RIGHT := Vector2i(4, 0)
const WALL_BL := Vector2i(5, 0)
const WALL_BOTTOM := Vector2i(6, 0)
const WALL_BR := Vector2i(7, 0)

const CORR_TOP := Vector2i(0, 1)
const CORR_BOT := Vector2i(1, 1)
const CORR_LEFT := Vector2i(2, 1)
const CORR_RIGHT := Vector2i(3, 1)

const COCKPIT_CL := Vector2i(0, 2)
const WIN_1 := Vector2i(1, 2)
const WIN_2 := Vector2i(2, 2)
const WIN_3 := Vector2i(3, 2)
const WIN_4 := Vector2i(4, 2)
const COCKPIT_CR := Vector2i(5, 2)
const STAR := Vector2i(7, 2)

const FLOOR_PLAIN := Vector2i(0, 3)
const FLOOR_SEAM := Vector2i(1, 3)
const FLOOR_PIPE_H := Vector2i(2, 3)
const FLOOR_PIPE_V := Vector2i(3, 3)
const FLOOR_GRATE := Vector2i(4, 3)
const FLOOR_VENT := Vector2i(5, 3)
const FLOOR_HAZARD := Vector2i(6, 3)
const FLOOR_HATCH := Vector2i(7, 3)

const LADDER_TOP := Vector2i(0, 4)
const LADDER_BOT := Vector2i(1, 4)
const CONSOLE := Vector2i(2, 4)
const DISH := Vector2i(3, 4)
const REACTOR := Vector2i(4, 4)
const MONITOR := Vector2i(6, 4)

const LOCKED_DOOR := Vector2i(2, 5)
const BUTTON_TILE := Vector2i(3, 5)
const PC_DESK := Vector2i(4, 5)

# Estado das portas
var porta_esquerda_aberta: bool = false
var passagem_norte_aberta: bool = false
var fase_concluida: bool = false

@export var recriar_cenario: bool = false:
	set(val):
		if val:
			if not tile_map:
				tile_map = get_node_or_null("TileMapLayer")
			if tile_map:
				build_spaceship_map()


func _enter_tree() -> void:
	if not tile_map:
		tile_map = get_node_or_null("TileMapLayer")
	if tile_map:
		build_spaceship_map()


func _ready() -> void:
	if not tile_map:
		tile_map = get_node_or_null("TileMapLayer")
	if tile_map:
		build_spaceship_map()

	# Conecta gatilhos se estiver em tempo de execução
	if not Engine.is_editor_hint():
		conectar_interativos()


func _unhandled_input(event: InputEvent) -> void:
	# Reinicia a fase pressionando R
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func conectar_interativos() -> void:
	var pc_node := get_node_or_null("Interativos/PCCentral")
	if pc_node and pc_node.has_signal("interagiu"):
		pc_node.interagiu.connect(_on_pc_central_interagiu)

	var btn_node := get_node_or_null("Interativos/BotaoEmergencia")
	if btn_node and btn_node.has_signal("interagiu"):
		btn_node.interagiu.connect(_on_botao_emergencia_interagiu)

	var saida_node := get_node_or_null("Interativos/AreaSaida")
	if saida_node and saida_node.has_signal("body_entered"):
		saida_node.body_entered.connect(_on_saida_body_entered)


func build_spaceship_map() -> void:
	tile_map.clear()

	# 1. Campo de estrelas ao redor da nave
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if rng.randf() < 0.07:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, STAR)

	# 2. Sala de Comando (Início do Personagem - Sul): x: 38..62, y: 44..55
	build_room(38, 44, 24, 12, FLOOR_PLAIN)
	# Janela panorâmica ao sul
	for wx in range(46, 54):
		tile_map.set_cell(Vector2i(wx, 55), SOURCE_ID, FLOOR_PIPE_H)
	tile_map.set_cell(Vector2i(45, 48), SOURCE_ID, CONSOLE)
	tile_map.set_cell(Vector2i(54, 48), SOURCE_ID, CONSOLE)
	tile_map.set_cell(Vector2i(47, 51), SOURCE_ID, MONITOR)
	tile_map.set_cell(Vector2i(52, 51), SOURCE_ID, MONITOR)
	tile_map.set_cell(Vector2i(50, 53), SOURCE_ID, DISH)
	# Saída norte da Sala de Comando
	tile_map.set_cell(Vector2i(49, 44), SOURCE_ID, FLOOR_PIPE_V)
	tile_map.set_cell(Vector2i(50, 44), SOURCE_ID, FLOOR_PIPE_V)

	# 3. Corredor Sul: y: 38..44, x: 48..51
	build_v_corridor(38, 44, 48, 4)

	# 4. Junção Central: y: 22..38, x: 48..51
	build_v_corridor(22, 38, 48, 4)

	# 5. Sala da Direita (Primeira Sala - Aberta): x: 51..75, y: 22..38
	build_room(51, 22, 24, 16, FLOOR_SEAM)
	# Entrada aberta conectando ao corredor central
	tile_map.set_cell(Vector2i(51, 29), SOURCE_ID, FLOOR_PIPE_H)
	tile_map.set_cell(Vector2i(51, 30), SOURCE_ID, FLOOR_PIPE_H)
	# 4 Estações de Trabalho com PCs (conforme o esboço: 2 no topo, 2 embaixo)
	# Top-Left PC:
	tile_map.set_cell(Vector2i(56, 25), SOURCE_ID, PC_DESK)
	tile_map.set_cell(Vector2i(57, 25), SOURCE_ID, PC_DESK)
	# Top-Right PC:
	tile_map.set_cell(Vector2i(68, 25), SOURCE_ID, PC_DESK)
	tile_map.set_cell(Vector2i(69, 25), SOURCE_ID, PC_DESK)
	# Bottom-Left PC:
	tile_map.set_cell(Vector2i(56, 34), SOURCE_ID, PC_DESK)
	tile_map.set_cell(Vector2i(57, 34), SOURCE_ID, PC_DESK)
	# Bottom-Right PC:
	tile_map.set_cell(Vector2i(68, 34), SOURCE_ID, PC_DESK)
	tile_map.set_cell(Vector2i(69, 34), SOURCE_ID, PC_DESK)
	# PC Central interativo com destaque no piso
	tile_map.set_cell(Vector2i(62, 29), SOURCE_ID, CONSOLE)
	tile_map.set_cell(Vector2i(63, 29), SOURCE_ID, CONSOLE)
	tile_map.set_cell(Vector2i(62, 30), SOURCE_ID, FLOOR_HAZARD)
	tile_map.set_cell(Vector2i(63, 30), SOURCE_ID, FLOOR_HAZARD)

	# 6. Sala da Esquerda (Inicialmente Fechada, com Monstro): x: 24..48, y: 22..38
	build_room(24, 22, 24, 16, FLOOR_GRATE)
	# Porta trancada no acesso leste (inicialmente fechada)
	if porta_esquerda_aberta:
		tile_map.set_cell(Vector2i(48, 29), SOURCE_ID, FLOOR_PIPE_H)
		tile_map.set_cell(Vector2i(48, 30), SOURCE_ID, FLOOR_PIPE_H)
	else:
		tile_map.set_cell(Vector2i(48, 29), SOURCE_ID, LOCKED_DOOR)
		tile_map.set_cell(Vector2i(48, 30), SOURCE_ID, LOCKED_DOOR)

	# Botão de emergência na sala esquerda
	tile_map.set_cell(Vector2i(26, 25), SOURCE_ID, BUTTON_TILE)
	tile_map.set_cell(Vector2i(26, 26), SOURCE_ID, FLOOR_HAZARD)
	# Detalhes de laboratório / contenção
	tile_map.set_cell(Vector2i(28, 34), SOURCE_ID, REACTOR)
	tile_map.set_cell(Vector2i(43, 34), SOURCE_ID, REACTOR)
	tile_map.set_cell(Vector2i(42, 25), SOURCE_ID, MONITOR)

	# 7. Corredor Superior (Fechado até clicar na esquerda): x: 48..51, y: 10..22
	build_v_corridor(10, 22, 48, 4)
	# Porta trancada no corredor norte
	if passagem_norte_aberta:
		tile_map.set_cell(Vector2i(49, 22), SOURCE_ID, FLOOR_PIPE_V)
		tile_map.set_cell(Vector2i(50, 22), SOURCE_ID, FLOOR_PIPE_V)
	else:
		tile_map.set_cell(Vector2i(49, 22), SOURCE_ID, LOCKED_DOOR)
		tile_map.set_cell(Vector2i(50, 22), SOURCE_ID, LOCKED_DOOR)

	# 8. Saída (Topo): x: 44..56, y: 2..10
	build_room(44, 2, 12, 8, FLOOR_PLAIN)
	tile_map.set_cell(Vector2i(49, 10), SOURCE_ID, FLOOR_PIPE_V)
	tile_map.set_cell(Vector2i(50, 10), SOURCE_ID, FLOOR_PIPE_V)
	# Escotilha / escada de saída
	tile_map.set_cell(Vector2i(50, 4), SOURCE_ID, LADDER_TOP)
	tile_map.set_cell(Vector2i(50, 5), SOURCE_ID, LADDER_BOT)
	tile_map.set_cell(Vector2i(50, 6), SOURCE_ID, FLOOR_HAZARD)


func build_room(x0: int, y0: int, w: int, h: int, floor_tile: Vector2i) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if y == y0 and x == x0:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_TL)
			elif y == y0 and x == x0 + w - 1:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_TR)
			elif y == y0 + h - 1 and x == x0:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_BL)
			elif y == y0 + h - 1 and x == x0 + w - 1:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_BR)
			elif y == y0:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_TOP)
			elif y == y0 + h - 1:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_BOTTOM)
			elif x == x0:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_LEFT)
			elif x == x0 + w - 1:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, WALL_RIGHT)
			else:
				tile_map.set_cell(Vector2i(x, y), SOURCE_ID, floor_tile)


func build_v_corridor(y0: int, y1: int, x: int, width: int) -> void:
	var x_left := x
	var x_right := x + width - 1
	for y in range(y0, y1 + 1):
		tile_map.set_cell(Vector2i(x_left, y), SOURCE_ID, CORR_LEFT)
		tile_map.set_cell(Vector2i(x_right, y), SOURCE_ID, CORR_RIGHT)
		for cx in range(x_left + 1, x_right):
			tile_map.set_cell(Vector2i(cx, y), SOURCE_ID, FLOOR_PIPE_V)


# --- LÓGICA DE PROGRESSÃO DA FASE ---

func _on_pc_central_interagiu() -> void:
	if not porta_esquerda_aberta:
		porta_esquerda_aberta = true
		# Abre a porta da esquerda no tilemap (remove a colisão e coloca piso)
		tile_map.set_cell(Vector2i(48, 29), SOURCE_ID, FLOOR_PIPE_H)
		tile_map.set_cell(Vector2i(48, 30), SOURCE_ID, FLOOR_PIPE_H)

		if hud:
			hud.set_objective("2. Entre na Sala da Esquerda e encontre o botão (Cuidado com o monstro!).")
			hud.show_dialog(
				"💻 TERMINAL CENTRAL (SALA DE COMUNICAÇÕES)",
				"Registros de emergência acessados!\n\n" +
				"ALERTA: Espécime alienígena hostil confinado na Sala da Esquerda.\n" +
				"DICA: Pressione o botão no painel da sala esquerda para destravar a saída norte!\n\n" +
				"-> PORTA DA SALA DA ESQUERDA DESTRANCADA!"
			)
	else:
		if hud:
			hud.show_dialog(
				"💻 TERMINAL CENTRAL",
				"A porta da sala esquerda já foi destrancada. Encontre o botão de emergência lá dentro!"
			)


func _on_botao_emergencia_interagiu() -> void:
	if not passagem_norte_aberta:
		passagem_norte_aberta = true
		# Abre a porta do corredor norte
		tile_map.set_cell(Vector2i(49, 22), SOURCE_ID, FLOOR_PIPE_V)
		tile_map.set_cell(Vector2i(50, 22), SOURCE_ID, FLOOR_PIPE_V)

		if hud:
			hud.set_objective("3. Corra para a Saída ao norte!")
			hud.show_dialog(
				"🚨 PAINEL DE EMERGÊNCIA",
				"Botão acionado! Trava magnética desativada com sucesso.\n\n" +
				"-> PASSAGEM NORTE LIBERADA!\n" +
				"Corra até a escotilha de saída no topo da nave!"
			)
	else:
		if hud:
			hud.show_dialog(
				"🚨 PAINEL DE EMERGÊNCIA",
				"A passagem norte já está destrancada. Corra para a saída!"
			)


func _on_saida_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Astronauta":
		if not fase_concluida:
			fase_concluida = true
			if hud:
				hud.set_objective("✨ Fase Concluída com Sucesso!")
				hud.show_dialog(
					"🚀 FASE INTRODUTÓRIA CONCLUÍDA!",
					"Excelente! Você destrancou as passagens, sobreviveu à criatura e alcançou a escotilha de escape!\n\n" +
					"Pressione [R] a qualquer momento para reiniciar e jogar novamente."
				)
