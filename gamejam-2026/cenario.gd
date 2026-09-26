extends Node2D

## Gerenciador da Fase Introdutória da Nave Espacial
## O mapa é editado MANUALMENTE no editor de tiles do Godot.
## Este script cuida apenas da lógica de progressão da fase:
## - Abrir/fechar portas trocando tiles em runtime
## - Conectar interativos (PC, botão, saída)
## - Atualizar HUD

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var hud: CanvasLayer = $HUD

const SOURCE_ID: int = 0

# Atlas Coords usados na lógica de portas
const FLOOR_PIPE_H := Vector2i(2, 3)
const FLOOR_PIPE_V := Vector2i(3, 3)
const LOCKED_DOOR := Vector2i(2, 5)

# Estado das portas
var porta_esquerda_aberta: bool = false
var passagem_norte_aberta: bool = false
var fase_concluida: bool = false


func _ready() -> void:
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

