extends Node
## Autoload: progresso salvo (save) e configurações (volume), gravados em user://.
## Save e configurações ficam em arquivos separados: mudar o volume no menu, sem
## nunca ter jogado, não pode fazer aparecer um "Continuar" que não existe.

const CAMINHO_SAVE := "user://save.json"
const CAMINHO_CONFIG := "user://config.json"
const PRIMEIRA_FASE := "res://Scenes/movimentação_TRACO.tscn"

var volume_master: float = 1.0 # 0.0 (mudo) a 1.0 (máximo)
var _save: Dictionary = {}

func _ready() -> void:
	volume_master = _ler(CAMINHO_CONFIG).get("volume", 1.0)
	_save = _ler(CAMINHO_SAVE)
	_aplicar_volume()

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
	_gravar(CAMINHO_SAVE, _save)

## Chamado ao entrar numa fase, pra "Continuar" saber de onde retomar.
func registrar_fase(caminho_cena: String) -> void:
	_save["fase_atual"] = caminho_cena
	_gravar(CAMINHO_SAVE, _save)

## Muda o volume na hora (chamado a cada movimento do slider), sem gravar em disco.
func definir_volume(valor: float) -> void:
	volume_master = clampf(valor, 0.0, 1.0)
	_aplicar_volume()

## Grava o volume atual (chamado quando o jogador solta o slider).
func salvar_config() -> void:
	_gravar(CAMINHO_CONFIG, {"volume": volume_master})

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
