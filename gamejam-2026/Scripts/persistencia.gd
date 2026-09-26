extends Node
## Autoload: progresso salvo (save) e configurações (volume), gravados em user://.
## Save e configurações ficam em arquivos separados: mudar o volume no menu, sem
## nunca ter jogado, não pode fazer aparecer um "Continuar" que não existe.
## Rodando pelo editor, o progresso vai pra outro arquivo: o jogo exportado usa a mesma pasta
## user://, e sem isso testar pelo Godot fazia o compilado já abrir com "Continuar".

const CAMINHO_SAVE_JOGO := "user://save.json"
const CAMINHO_SAVE_EDITOR := "user://save_editor.json"
const CAMINHO_CONFIG := "user://config.json"
const PRIMEIRA_FASE := "res://Scenes/fase1.tscn"

var volume_master: float = 1.0 # 0.0 (mudo) a 1.0 (máximo)
var tela_cheia: bool = true # true = tela cheia sem borda; false = janela
var _save: Dictionary = {}
var _caminho_save: String = CAMINHO_SAVE_EDITOR if OS.has_feature("editor") else CAMINHO_SAVE_JOGO

func _ready() -> void:
	var config := _ler(CAMINHO_CONFIG)
	volume_master = config.get("volume", 1.0)
	tela_cheia = config.get("tela_cheia", true)
	_save = _ler(_caminho_save)
	_aplicar_volume()
	_aplicar_tela()

func tem_save() -> bool:
	return _save.has("fase_atual")

func obter_fase_salva() -> String:
	var fase: String = _save.get("fase_atual", PRIMEIRA_FASE)
	# Save de uma versão antiga pode apontar pra uma cena que foi movida/renomeada
	if not ResourceLoader.exists(fase):
		return PRIMEIRA_FASE
	return fase

## Chamado pelo botão "Novo Jogo": zera o progresso e volta pra primeira fase.
func iniciar_novo_jogo() -> void:
	_save = {"fase_atual": PRIMEIRA_FASE}
	# História e tutorial da fase 1 guardam no root que já foram vistos: jogo novo mostra de novo
	for chave in [&"historia_fase1_vista", &"tutorial_fase1_concluido"]:
		get_tree().root.remove_meta(chave)
	_gravar(_caminho_save, _save)

## Chamado ao entrar numa fase, pra "Continuar" saber de onde retomar.
func registrar_fase(caminho_cena: String) -> void:
	_save["fase_atual"] = caminho_cena
	_gravar(_caminho_save, _save)

## Muda o volume na hora (chamado a cada movimento do slider), sem gravar em disco.
func definir_volume(valor: float) -> void:
	volume_master = clampf(valor, 0.0, 1.0)
	_aplicar_volume()

## Troca entre tela cheia e janela na hora e já grava a escolha.
func definir_tela_cheia(valor: bool) -> void:
	tela_cheia = valor
	_aplicar_tela()
	salvar_config()

## Grava as configurações atuais (chamado quando o jogador solta o slider, por exemplo).
func salvar_config() -> void:
	_gravar(CAMINHO_CONFIG, {"volume": volume_master, "tela_cheia": tela_cheia})

func _aplicar_tela() -> void:
	if tela_cheia:
		# FULLSCREEN do Godot já é a tela cheia sem borda (a "exclusiva" é outro modo)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Janela no maior múltiplo inteiro de 480x270 que cabe no monitor (descontando a barra de
	# título): assim a pixel art e a fonte continuam nítidas
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var escala := maxi(1, mini(int(area.size.x / 480.0), int((area.size.y - 40) / 270.0)))
	var tamanho := Vector2i(480, 270) * escala
	DisplayServer.window_set_size(tamanho)
	@warning_ignore("integer_division") # Centraliza em pixels inteiros: descartar o 0,5 é de propósito
	DisplayServer.window_set_position(area.position + (area.size - tamanho) / 2)

func _aplicar_volume() -> void:
	var indice := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(indice, volume_master <= 0.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(volume_master, 0.0001)))

func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Persistencia: falha ao ler %s (erro %d)" % [caminho, FileAccess.get_open_error()])
		return {}
	var resultado: Variant = JSON.parse_string(arquivo.get_as_text())
	return resultado if resultado is Dictionary else {}

func _gravar(caminho: String, dados: Dictionary) -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		push_error("Persistencia: falha ao gravar %s (erro %d)" % [caminho, FileAccess.get_open_error()])
		return
	arquivo.store_string(JSON.stringify(dados))
