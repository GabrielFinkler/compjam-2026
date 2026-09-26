@tool
extends TileMap

# ==============================================================================
# DESIGN DA NAVE ESPACIAL - TEMA SCI-FI / DARK HORROR (GODOT 4)
# ==============================================================================
# Layout da Nave:
# 1. Ponte de Controle (Bridge / Cockpit) - Início do Jogador (Spawn) com consoles,
#    telas de comando e iluminação ambiente azulada.
# 2. Corredor Principal Conector - Conecta a ponte às seções centrais da nave,
#    com grades de ventilação, fios expostos e luzes de emergência.
# 3. Sala Grande Central com 2 Cômodos:
#    - Cômodo Superior (ABERTO): Laboratório / Suporte de Vida com computadores e luz ativa.
#    - Cômodo Inferior (FECHADO): Quarentena / Contenção com porta blindada trancada e luz vermelha.
# 4. Continuação do Corredor com Porta Fechada no final (Blast Door bloqueada).
# ==============================================================================

const SOURCE_SHIP = 0

# --- COORDENADAS DOS TILES (ATLAS) ---
# Pisos
const TILE_FLOOR_TECH = Vector2i(9, 4)      # Piso azul/cinza tecnológico liso
const TILE_FLOOR_METAL = Vector2i(1, 1)     # Piso metálico reforçado
const TILE_FLOOR_GRATE = Vector2i(17, 1)    # Grade de passarela de corredor
const TILE_FLOOR_DARK = Vector2i(3, 4)      # Piso sombrio

# Paredes Externas e Cantos
const TILE_WALL_TOP = Vector2i(1, 0)
const TILE_WALL_BOT = Vector2i(1, 2)
const TILE_WALL_LEFT = Vector2i(0, 1)
const TILE_WALL_RIGHT = Vector2i(3, 1)
const TILE_CORNER_TL = Vector2i(0, 0)
const TILE_CORNER_TR = Vector2i(3, 0)
const TILE_CORNER_BL = Vector2i(0, 2)
const TILE_CORNER_BR = Vector2i(3, 2)

# Paredes Chanfradas / Cockpit
const TILE_SLOPE_TL = Vector2i(1, 5)
const TILE_SLOPE_TR = Vector2i(4, 5)
const TILE_SLOPE_BL = Vector2i(1, 6)
const TILE_SLOPE_BR = Vector2i(4, 6)

# Paredes Internas e Estruturas
const TILE_WALL_INNER = Vector2i(2, 7)
const TILE_WALL_TECH_TOP = Vector2i(9, 3)
const TILE_WALL_TECH_BOT = Vector2i(9, 7)

# Consoles, Telas e Decorações
const TILE_CONSOLE_RADAR_L = Vector2i(23, 2)
const TILE_CONSOLE_RADAR_R = Vector2i(24, 2)
const TILE_CONSOLE_SCREEN_L = Vector2i(23, 4)
const TILE_CONSOLE_SCREEN_R = Vector2i(24, 4)
const TILE_CONSOLE_PILOT_L = Vector2i(23, 6)
const TILE_CONSOLE_PILOT_R = Vector2i(24, 6)
const TILE_PANEL_RED_ALARM = Vector2i(23, 8)
const TILE_PANEL_FUSE = Vector2i(24, 8)
const TILE_WALL_LIGHT_GREEN = Vector2i(21, 4)
const TILE_WALL_LIGHT_WHITE = Vector2i(21, 0)
const TILE_VENT_FLOOR = Vector2i(9, 10)

# Portas
const TILE_DOOR_CLOSED = Vector2i(17, 1)    # Bloco de porta fechada blindada
const TILE_DOOR_FRAME_L = Vector2i(7, 2)
const TILE_DOOR_FRAME_R = Vector2i(9, 2)

# Dimensões e Posições do Layout
# Camadas do TileMap
const LAYER_FLOOR = 0
const LAYER_DECOR = 1
const LAYER_WALLS = 2

@export var auto_generate_on_ready: bool = true

var _paredes_posicoes: Dictionary = {}

func _ready():
	if auto_generate_on_ready:
		gerar_design_nave()

func gerar_design_nave():
	clear()
	_paredes_posicoes.clear()
	
	# Remove colisões anteriores se existirem
	var col_holder = get_node_or_null("ColisoesParedes")
	if col_holder:
		col_holder.queue_free()
	
	# 1. CONSTRUIR A PONTE DE CONTROLE (Cockpit / Bridge)
	_construir_ponte_controle()
	
	# 2. CONSTRUIR O CORREDOR PRINCIPAL 1 (Ponte -> Sala Grande)
	_construir_corredor_principal_1()
	
	# 3. CONSTRUIR A SALA GRANDE COM OS 2 CÔMODOS (1 Aberto e 1 Fechado)
	_construir_sala_grande_com_comodos()
	
	# 4. CONSTRUIR O CORREDOR 2 E A PORTA FECHADA NO FINAL
	_construir_corredor_2_e_porta_fechada()
	
	# 5. GERAR COLISÕES FÍSICAS NAS PAREDES
	_gerar_colisoes_fisicas()


func _set_parede(cell: Vector2i, tile_coord: Vector2i):
	set_cell(LAYER_WALLS, cell, SOURCE_SHIP, tile_coord)
	_paredes_posicoes[cell] = true


# ==============================================================================
# SEÇÃO 1: PONTE DE CONTROLE (BRIDGE)
# ==============================================================================
func _construir_ponte_controle():
	# Chão da Ponte de Controle
	for y in range(6, 17):
		for x in range(3, 13):
			if (x == 3 and (y < 8 or y > 14)) or (x == 4 and (y < 7 or y > 15)):
				continue
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, TILE_FLOOR_TECH)
	
	# Paredes Exteriores da Ponte
	for x in range(5, 13):
		_set_parede(Vector2i(x, 5), TILE_WALL_TOP)
	for x in range(5, 13):
		_set_parede(Vector2i(x, 17), TILE_WALL_BOT)
	
	# Chanfros frontais (Proa da nave)
	_set_parede(Vector2i(4, 6), TILE_SLOPE_TL)
	_set_parede(Vector2i(3, 7), TILE_SLOPE_TL)
	for y in range(8, 15):
		_set_parede(Vector2i(2, y), TILE_WALL_LEFT)
	_set_parede(Vector2i(3, 15), TILE_SLOPE_BL)
	_set_parede(Vector2i(4, 16), TILE_SLOPE_BL)
	
	# Parede traseira da ponte (com passagem para o corredor em y=10..12)
	for y in range(6, 10):
		_set_parede(Vector2i(13, y), TILE_WALL_RIGHT)
	for y in range(13, 17):
		_set_parede(Vector2i(13, y), TILE_WALL_RIGHT)
	
	# Consoles de comando e radar
	set_cell(LAYER_DECOR, Vector2i(4, 9), SOURCE_SHIP, TILE_CONSOLE_RADAR_L)
	set_cell(LAYER_DECOR, Vector2i(4, 10), SOURCE_SHIP, TILE_CONSOLE_RADAR_R)
	set_cell(LAYER_DECOR, Vector2i(4, 11), SOURCE_SHIP, TILE_CONSOLE_PILOT_L)
	set_cell(LAYER_DECOR, Vector2i(4, 12), SOURCE_SHIP, TILE_CONSOLE_PILOT_R)
	set_cell(LAYER_DECOR, Vector2i(4, 13), SOURCE_SHIP, TILE_CONSOLE_SCREEN_L)
	
	set_cell(LAYER_DECOR, Vector2i(7, 6), SOURCE_SHIP, TILE_CONSOLE_SCREEN_L)
	set_cell(LAYER_DECOR, Vector2i(8, 6), SOURCE_SHIP, TILE_CONSOLE_SCREEN_R)
	set_cell(LAYER_DECOR, Vector2i(9, 6), SOURCE_SHIP, TILE_WALL_LIGHT_GREEN)
	
	set_cell(LAYER_DECOR, Vector2i(7, 16), SOURCE_SHIP, TILE_CONSOLE_RADAR_L)
	set_cell(LAYER_DECOR, Vector2i(8, 16), SOURCE_SHIP, TILE_CONSOLE_RADAR_R)
	set_cell(LAYER_DECOR, Vector2i(9, 16), SOURCE_SHIP, TILE_WALL_LIGHT_GREEN)
	
	set_cell(LAYER_DECOR, Vector2i(6, 11), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(11, 8), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(11, 14), SOURCE_SHIP, TILE_VENT_FLOOR)


# ==============================================================================
# SEÇÃO 2: CORREDOR PRINCIPAL 1 (BRIDGE -> CENTRAL HUB)
# ==============================================================================
func _construir_corredor_principal_1():
	for x in range(13, 25):
		for y in range(10, 13):
			var tile = TILE_FLOOR_GRATE if (x % 3 == 0) else TILE_FLOOR_METAL
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, tile)
	
	for x in range(14, 25):
		_set_parede(Vector2i(x, 9), TILE_WALL_TOP)
		_set_parede(Vector2i(x, 13), TILE_WALL_BOT)
	
	set_cell(LAYER_DECOR, Vector2i(16, 9), SOURCE_SHIP, TILE_PANEL_RED_ALARM)
	set_cell(LAYER_DECOR, Vector2i(18, 11), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(21, 13), SOURCE_SHIP, TILE_PANEL_FUSE)
	set_cell(LAYER_DECOR, Vector2i(22, 9), SOURCE_SHIP, TILE_WALL_LIGHT_WHITE)


# ==============================================================================
# SEÇÃO 3: SALA GRANDE CENTRAL E OS 2 CÔMODOS
# ==============================================================================
func _construir_sala_grande_com_comodos():
	# Lobby Central
	for x in range(25, 36):
		for y in range(9, 14):
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, TILE_FLOOR_TECH)
	
	set_cell(LAYER_DECOR, Vector2i(30, 11), SOURCE_SHIP, TILE_VENT_FLOOR)
	
	# Cômodo Superior (ABERTO - Laboratório)
	for x in range(25, 36):
		for y in range(3, 9):
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, TILE_FLOOR_TECH)
	
	for x in range(25, 36):
		_set_parede(Vector2i(x, 2), TILE_WALL_TOP)
	for y in range(3, 9):
		_set_parede(Vector2i(24, y), TILE_WALL_LEFT)
		_set_parede(Vector2i(36, y), TILE_WALL_RIGHT)
	_set_parede(Vector2i(24, 2), TILE_CORNER_TL)
	_set_parede(Vector2i(36, 2), TILE_CORNER_TR)
	
	# Parede divisória com entrada ABERTA em X=29..31
	for x in range(25, 29):
		_set_parede(Vector2i(x, 8), TILE_WALL_INNER)
	for x in range(32, 36):
		_set_parede(Vector2i(x, 8), TILE_WALL_INNER)
	
	set_cell(LAYER_DECOR, Vector2i(28, 8), SOURCE_SHIP, TILE_WALL_LIGHT_GREEN)
	set_cell(LAYER_DECOR, Vector2i(32, 8), SOURCE_SHIP, TILE_WALL_LIGHT_GREEN)
	
	set_cell(LAYER_DECOR, Vector2i(26, 3), SOURCE_SHIP, TILE_CONSOLE_SCREEN_L)
	set_cell(LAYER_DECOR, Vector2i(27, 3), SOURCE_SHIP, TILE_CONSOLE_SCREEN_R)
	set_cell(LAYER_DECOR, Vector2i(29, 3), SOURCE_SHIP, TILE_CONSOLE_RADAR_L)
	set_cell(LAYER_DECOR, Vector2i(30, 3), SOURCE_SHIP, TILE_CONSOLE_RADAR_R)
	set_cell(LAYER_DECOR, Vector2i(33, 3), SOURCE_SHIP, TILE_CONSOLE_SCREEN_L)
	set_cell(LAYER_DECOR, Vector2i(34, 3), SOURCE_SHIP, TILE_CONSOLE_SCREEN_R)
	set_cell(LAYER_DECOR, Vector2i(26, 6), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(34, 6), SOURCE_SHIP, TILE_PANEL_FUSE)

	# Cômodo Inferior (FECHADO - Quarentena)
	for x in range(25, 36):
		for y in range(14, 21):
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, TILE_FLOOR_DARK)
	
	for x in range(25, 36):
		_set_parede(Vector2i(x, 21), TILE_WALL_BOT)
	for y in range(14, 21):
		_set_parede(Vector2i(24, y), TILE_WALL_LEFT)
		_set_parede(Vector2i(36, y), TILE_WALL_RIGHT)
	_set_parede(Vector2i(24, 21), TILE_CORNER_BL)
	_set_parede(Vector2i(36, 21), TILE_CORNER_BR)
	
	# Parede divisória com PORTA FECHADA (X=29..31, Y=14)
	for x in range(25, 29):
		_set_parede(Vector2i(x, 14), TILE_WALL_INNER)
	for x in range(32, 36):
		_set_parede(Vector2i(x, 14), TILE_WALL_INNER)
	
	_set_parede(Vector2i(29, 14), TILE_DOOR_CLOSED)
	_set_parede(Vector2i(30, 14), TILE_DOOR_CLOSED)
	_set_parede(Vector2i(31, 14), TILE_DOOR_CLOSED)
	set_cell(LAYER_DECOR, Vector2i(28, 14), SOURCE_SHIP, TILE_PANEL_RED_ALARM)
	set_cell(LAYER_DECOR, Vector2i(32, 14), SOURCE_SHIP, TILE_PANEL_RED_ALARM)
	
	set_cell(LAYER_DECOR, Vector2i(30, 17), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(26, 19), SOURCE_SHIP, TILE_PANEL_FUSE)
	set_cell(LAYER_DECOR, Vector2i(34, 19), SOURCE_SHIP, TILE_CONSOLE_SCREEN_L)


# ==============================================================================
# SEÇÃO 4: CORREDOR 2 E PORTA FINAL FECHADA
# ==============================================================================
func _construir_corredor_2_e_porta_fechada():
	for x in range(36, 48):
		for y in range(10, 13):
			var tile = TILE_FLOOR_GRATE if (x % 3 == 0) else TILE_FLOOR_METAL
			set_cell(LAYER_FLOOR, Vector2i(x, y), SOURCE_SHIP, tile)
	
	for x in range(36, 48):
		_set_parede(Vector2i(x, 9), TILE_WALL_TOP)
		_set_parede(Vector2i(x, 13), TILE_WALL_BOT)
	
	# PORTA FINAL FECHADA
	_set_parede(Vector2i(47, 10), TILE_DOOR_CLOSED)
	_set_parede(Vector2i(47, 11), TILE_DOOR_CLOSED)
	_set_parede(Vector2i(47, 12), TILE_DOOR_CLOSED)
	
	_set_parede(Vector2i(48, 9), TILE_CORNER_TR)
	_set_parede(Vector2i(48, 10), TILE_WALL_RIGHT)
	_set_parede(Vector2i(48, 11), TILE_WALL_RIGHT)
	_set_parede(Vector2i(48, 12), TILE_WALL_RIGHT)
	_set_parede(Vector2i(48, 13), TILE_CORNER_BR)
	
	set_cell(LAYER_DECOR, Vector2i(46, 9), SOURCE_SHIP, TILE_PANEL_RED_ALARM)
	set_cell(LAYER_DECOR, Vector2i(46, 13), SOURCE_SHIP, TILE_PANEL_RED_ALARM)
	set_cell(LAYER_DECOR, Vector2i(41, 11), SOURCE_SHIP, TILE_VENT_FLOOR)
	set_cell(LAYER_DECOR, Vector2i(44, 9), SOURCE_SHIP, TILE_WALL_LIGHT_WHITE)


# ==============================================================================
# SEÇÃO 5: GERAÇÃO DE COLISÕES FÍSICAS REAIS
# ==============================================================================
func _gerar_colisoes_fisicas():
	var static_body = StaticBody2D.new()
	static_body.name = "ColisoesParedes"
	add_child(static_body)
	
	var tile_size = 16.0
	for cell in _paredes_posicoes.keys():
		var col_shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(tile_size, tile_size)
		col_shape.shape = rect
		col_shape.position = Vector2(cell.x * tile_size + tile_size / 2.0, cell.y * tile_size + tile_size / 2.0)
		static_body.add_child(col_shape)
