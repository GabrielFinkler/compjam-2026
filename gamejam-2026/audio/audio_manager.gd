extends Node
## Autoload "Audio": toca SFX, música e ambiente, e liga sons às cenas do jogo em tempo
## de execução (via get_tree().node_added), sem precisar editar as cenas dos colegas.
## Os nomes de arquivo podem vir com ou sem extensão (sem ela, tenta .wav, .ogg e .mp3).
## Arquivo inexistente gera só um push_warning: o jogo continua, sem aquele som.
##
## Música e ambiente usam LoopContinuo: crossfade entre duas cópias do som, cortando
## os fades embutidos no começo/fim do arquivo, pra o loop não ter "buraco".

const PASTA := "res://audio/"
const EXTENSOES := ["wav", "ogg", "mp3"]

# Nós reconhecidos pelo caminho do script (não precisa mexer nas cenas deles)
const SCRIPT_JOGADOR := "res://Scripts/nave.gd"
const SCRIPT_MONSTRO := "res://Scripts/monstro.gd"
const SCRIPT_PORTA := "res://Scripts/porta.gd"
const SCRIPT_TERMINAL := "res://Scripts/terminal.gd"
const SCRIPT_MAQUINA := "res://Scripts/maquina_reparo.gd"
const SCRIPT_ISCA := "res://Scripts/isca_luminosa.gd"
const SCRIPT_TELA_MORTE := "res://Scripts/tela_morte.gd"
const SCRIPT_DUTO := "res://Scripts/duto.gd"
const SCRIPT_HISTORIA := "res://Scripts/historia.gd"
const SCRIPT_POD := "res://Scripts/pod_fuga.gd"
const PREFIXO_ITEM := "res://Scripts/item_" ## Todo script item_*.gd conta como item coletável
const CENA_MENU := "res://Scenes/menu_principal.tscn"
const TERMINAIS_ALAVANCA := ["Dorm"] ## Terminais com isso no nome são alavancas (dormitórios da fase 5)

# Sons (sfx/, ambiente/ e musica/)
const SOM_PASSOS := "Som de Passos 2.mp3" # versão em teste
const SOM_PASSOS_ORIGINAL := "Som de Passos.wav" ## Usado se a versão em teste faltar
const SOM_COLETAR_ENERGIA := "Som Coletar Energia.ogg"
const SOM_PEGAR_ITEM := "Som Pegar Item.wav"
const SOM_LUZ_FOCO := "Som Luz Ligada (Botão Esquerdo Mouse).mp3"
const SOM_ALIEN_PRESENCA := "Som de Alien 1.wav"
const SOM_ALIEN_PERSEGUE := "Som de Alien 2.mp3"
const SOM_ISCA_LANCAR := "Som Sinalizador 1.mp3"
const SOM_ISCA_ACESA := "Som Sinalizador 2.mp3"
const SOM_COMPUTADOR := "Som Desbloqueando Digital Beep.wav"
const SOM_ALAVANCA := "Som Alavanca.mp3"
const SOM_ERRO := "Som Erro Beep.wav"
const SOM_SKILL_CHECK := "Som Skill Check.mp3"
const SOM_PORTA_ABERTA := "Som Porta Destrancando.wav"
const SOM_PORTA_TRAVA := "Som Porta Desbloqueando Beep.wav"
const AMBIENTE_NAVE := "Som Ambiente de Nave.wav"
const AMBIENTE_MOTORES := "Som perto de Engines.wav"
const AMBIENTE_ALIEN := "Som Ambiente de Alien.wav"
const ALERTA_DESPERTAR := "Som de Alerta Emergência Alien.mp3"
## Sem extensão de propósito: o .flac não é importado pelo Godot. Convertido pra .wav/.ogg/.mp3
## (mesmo nome), passa a tocar sozinho; até lá só dá um aviso no console, uma vez.
const AMBIENTE_NAVE_ALTO := "Som Ambiente de Nave (MAIS ALTO)"
const MUSICA_MENU := "Música - Menu ou Início ou Introdução.ogg"
const SOM_BOTAO := "Som Botões Interface.mp3"
const SOM_TECLADO := "Som de Teclado 2.mp3" # versão em teste
const SOM_TECLADO_ORIGINAL := "Som de Teclado (Mensagens iniciais do jogo).mp3" ## Usado se a versão em teste faltar
const SOM_DUTO := "Som de Ventilação ou Duto Abrindo.mp3"
const SOM_MORTE_MONSTRO := "Som de Morte por Monstro.mp3"
const SOM_MORTE_ENERGIA := "Som de Morte por Falta de Energia.mp3"
## O arquivo da morte por monstro tem ~1 s quase mudo (0,3–1,0 s) antes do som principal:
## começa direto nele (s). Mais alto = mais adiantado.
const MORTE_MONSTRO_ADIANTAR := 1.0

## Som extra quando um alien adormecido surge, por fase (ex.: na fase 3 o esqueleto sai
## pela ventilação). Toca na posição do alien, um pouco mais alto que o normal: é um susto.
const SURGIMENTO_POR_FASE := {
	"res://Scenes/fase3.tscn": "Som de Ventilação ou Duto Abrindo.mp3",
}
const VOLUME_SURGIMENTO := 6.0
const ATRASO_EMERGENCIA := 1.75 ## Segundos entre o alien surgir e o alarme começar
const SOM_PORTA_CORRER := "Som de Porta de Correr Abrindo.mp3"
const SOM_POD := "Som do POD Lançando (final).mp3"
## Começa o som do POD já adiantado (s): o pico do arquivo (~2,3 s) cai junto com a subida
## do pod na tela (treme 0,9 s + decola 1,6 s). Mais alto = som mais adiantado.
const POD_ADIANTAR := 0.6

## Som de cada tipo de alien, pela cena dele. Para dar um som novo a um tipo, é só apontar
## o arquivo aqui. presenca = som enquanto ele está visível; grito = ao começar a perseguir.
## modo "loop" = presença contínua; "rajadas" = toca inteira e repete após uma pausa
## aleatória (intervalo, em s) — bom pra sons curtos com fim marcado.
## pitch < 1 deixa mais grave/pesado, > 1 mais agudo/agitado. Cena fora da lista usa o besouro.
const ALIEN_PADRAO := "res://Scenes/monstro.tscn"
const ALIENS := {
	# Besouro (normal)
	"res://Scenes/monstro.tscn": {
		"presenca": "Som de Alien 1.wav", "modo": "loop", "pitch": 1.0,
		"grito": "Som de Alien 2.mp3", "pitch_grito": 1.0, "volume_db": 0.0,
	},
	# Vermelho (lento e grande): som próprio, um pouco mais grave e alto; grito bem grave
	"res://Scenes/monstro_laboratorio.tscn": {
		"presenca": "Som de Alien 3.mp3", "modo": "loop", "pitch": 0.9,
		"grito": "Som de Alien 2.mp3", "pitch_grito": 0.7, "volume_db": 2.0,
	},
	# Esqueleto (rápido): som próprio em rajadas agitadas, grito agudo
	"res://Scenes/monstro_rapido.tscn": {
		"presenca": "Som de Alien Esqueleto.mp3", "modo": "rajadas", "intervalo": Vector2(0.6, 2.5),
		"pitch": 1.05, "grito": "Som de Alien 2.mp3", "pitch_grito": 1.35, "volume_db": 0.0,
	},
	# Espécime: mesmo visual de esqueleto (um pouco mais grave: é o que escapou do tanque)
	"res://Scenes/monstro_especime.tscn": {
		"presenca": "Som de Alien Esqueleto.mp3", "modo": "rajadas", "intervalo": Vector2(0.8, 3.0),
		"pitch": 0.92, "grito": "Som de Alien 2.mp3", "pitch_grito": 1.2, "volume_db": 0.0,
	},
}

## Ganho por arquivo (dB), somado a todo volume pedido. Comentário: "RMS" = nível medido do
## arquivo (só as partes com som), "=>" = nível que sai depois do ganho. Hierarquia de terror:
##   tensão (grito, morte, presença dos aliens)   => -19 a -25   (os mais altos)
##   momentos-chave (POD, porta, erro, skill)      => -24 a -26
##   rotina (energia, duto, beeps, itens, botões)  => -26 a -34   (discretos)
##   fundo (ambiente, passos, teclado)             => -26 a -34
## Ajuste fino de ouvido: mexa só aqui.
const MIXAGEM := {
	# Interface / rotina
	"Som Botões Interface.mp3": -6.0, # RMS -28 => -34: clique discreto
	"Som de Teclado 2.mp3": 3.0, # RMS -36 => -33: fundo do texto
	"Som de Teclado (Mensagens iniciais do jogo).mp3": -4.0, # RMS -33 => -37 (original)
	"Som Desbloqueando Digital Beep.wav": -12.0, # RMS -14.5 => -26.5
	"Som Alavanca.mp3": -6.0, # RMS -20 => -26
	"Som Pegar Item.wav": 8.0, # RMS -34 => -26
	"Som Coletar Energia.ogg": -9.0, # RMS -21 => -30: estava alto demais pra algo tão frequente
	"Som de Ventilação ou Duto Abrindo.mp3": -7.0, # RMS -22 => -29
	"Som Sinalizador 1.mp3": 5.0, # RMS -43 => -38: o pico (-6) não deixa subir mais
	"Som Sinalizador 2.mp3": 2.0, # RMS -36 => -34: chiado da isca acesa
	"Som Luz Ligada (Botão Esquerdo Mouse).mp3": -12.0, # RMS -18 => -30: zumbido contínuo
	# Momentos-chave
	"Som Porta Desbloqueando Beep.wav": -2.0, # RMS -26.5 => -28.5
	"Som Porta Destrancando.wav": 2.0, # RMS -32 => -30 (sem uso no momento)
	"Som de Porta de Correr Abrindo.mp3": 13.0, # RMS -38.5 => -25.5 (pico -23: cabe o ganho)
	"Som do POD Lançando (final).mp3": -9.0, # RMS -15 => -24: era o mais alto do jogo; segue em destaque
	"Som Erro Beep.wav": -2.0, # RMS -22 => -24
	"Som Skill Check.mp3": 2.0, # RMS -27 => -25
	"Som de Morte por Falta de Energia.mp3": -8.0, # RMS -21 => -29 (estava alto)
	# Tensão (os mais altos)
	"Som de Alien 2.mp3": 5.0, # RMS -24 => -19: grito ao começar a perseguir
	"Som de Morte por Monstro.mp3": 8.0, # RMS -35 => -27: era baixo; o pico passa pelo limitador
	"Som de Alien 1.wav": 0.0, # RMS -23.4 => -23.4: besouro (a distância ainda atenua)
	"Som de Alien 3.mp3": -6.0, # RMS -19.5 => -25.5 (+2 da tabela ALIENS): vermelho
	"Som de Alien Esqueleto.mp3": -3.0, # RMS -22 => -25: esqueleto
	"Som de Alerta Emergência Alien.mp3": -4.0, # RMS -24.5 => -28.5 (+ VOLUME_EMERGENCIA)
	# Fundo
	"Som de Passos 2.mp3": -6.0, # RMS -28.6 => -34.6: presentes, mas abaixo dos aliens
	"Som de Passos.wav": -10.5, # RMS -24 => -34.5 (original)
	"Som perto de Engines.wav": -15.0, # RMS -19 => -34: só uma camada de fundo
	"Música - Menu ou Início ou Introdução.ogg": -7.0, # RMS -14.5 => -21.5 (só no menu)
}

## Segundos cortados no [início, fim] de cada loop: fades embutidos nos arquivos
const CORTES := {
	"Som Ambiente de Nave.wav": [0.0, 0.35], # cai de -28 para -80 dB nos últimos 0,3 s
	"Som Ambiente de Alien.wav": [1.5, 1.8], # entra e sai em fade
	"Som de Alerta Emergência Alien.mp3": [0.5, 4.5], # últimos 4 s são quase silêncio
}

# Mixagem geral (ajuste de ouvido)
const VOLUME_MUDO := -50.0
const DISTANCIA_MAX_2D := 300.0 ## Pixels até um som 2D sumir
const DISTANCIA_EVENTO := 520.0 ## Eventos distantes do ambiente somem mais longe
const DISTANCIA_MONSTRO := 420.0 ## Rosnado alcança além da tela (240 px de meia-largura): ouve antes de ver
const DISTANCIA_PORTA := 28.0 ## Perto disso de uma porta trancada, [E] dá o beep de erro
const VOLUME_TENSAO_MAX := 0.0 ## Camada de tensão na perseguição: -30 => -30 (era -34)
const TENSAO_SOBE_DB_S := 14.0
const TENSAO_DESCE_DB_S := 6.0 ## Mais lento: a tensão "demora a passar"
const DUCK_AMBIENTE_DB := -5.0 ## O ambiente abaixa enquanto a tensão está no máximo
const EVENTO_INTERVALO := Vector2(22.0, 55.0) ## Segundos entre sons de alien aleatórios
const QUEBRA_INTERVALO := Vector2(45.0, 90.0) ## Segundos entre as "quebras" do ambiente mais alto
const QUEBRA_DURACAO := Vector2(12.0, 22.0)
const QUEBRA_FADE := 5.0 ## Entra e sai bem devagar
# Alarme de emergência: fixo depois que aliens despertam (celas da fase 4, Espécime da
# fase 5) e temporário em perseguições longas ou com 2+ aliens atrás do jogador
const VOLUME_EMERGENCIA := 5.0 ## Alarme: -28.5 => -23.5 (pedido: mais alto, é o auge da tensão)
const EMERGENCIA_SOBE_DB_S := 30.0
const EMERGENCIA_DESCE_DB_S := 8.0
const PERSEGUICAO_LONGA := 6.0 ## Segundos de perseguição contínua até o alarme soar
const EMERGENCIA_PAUSA := 60.0 ## Depois de uma perseguição com alarme, espera isso até o próximo
const CORTE_ABERTO := 20000.0
const CORTE_ABAFADO := 700.0 ## Som do jogo abafado na pausa e na tela de morte
const VEL_FILTRO := 5.0
## Buses abafados na pausa. "Interface" fica de fora: os cliques dos botões soam limpos.
const BUSES_ABAFAVEIS := ["Musica", "Ambiente", "SFX", "Tensao"]

const ESTADO_PARADO := 0 ## Valores do enum Estado de maquina_reparo.gd
const ESTADO_GIRANDO := 2

# Camadas (LoopContinuo) sem tipo: podem guardar uma camada já liberada após o fade,
# e o GDScript acusa erro ao passar instância liberada para variável tipada
var _camada_musica
var _camada_ambiente
var _camada_motores
var _camada_tensao
var _camada_emergencia
var _tensao_db := VOLUME_MUDO
var _emergencia_db := VOLUME_MUDO
var _emergencia_fixa := false
var _geracao_fase := 0 ## Sobe a cada fase carregada: invalida timers da fase anterior
var _emergencia_perseguicao := false
var _tempo_perseguicao := 0.0
var _espera_emergencia := 0.0
var _em_fase := false
var _jogador_morto := false
var _proximo_evento := 0.0
var _proxima_quebra := 0.0
var _avisados := {} ## Sons que faltam: avisa uma vez só, não a cada tentativa
var _filtros: Array[AudioEffectLowPassFilter] = []
var _corte := CORTE_ABERTO
var _portas: Array = []
var _interativos: Array = [] ## Terminais e máquinas (para o beep de "já usado")

func _ready():
	# Música e ambiente continuam na pausa e na tela de morte
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Filtro de abafar criado só em tempo de execução (o LowPass do Master fica fixo em 20 kHz)
	for nome_bus in BUSES_ABAFAVEIS:
		var indice := AudioServer.get_bus_index(nome_bus)
		if indice >= 0:
			var filtro := AudioEffectLowPassFilter.new()
			filtro.cutoff_hz = CORTE_ABERTO
			AudioServer.add_bus_effect(indice, filtro)
			_filtros.append(filtro)
	get_tree().node_added.connect(_on_node_added)
	# A cena inicial (menu, ou a fase ao testar com F6) entra na árvore antes deste
	# autoload ficar pronto: o node_added dela já passou, então liga o que já existe
	_ligar_existentes(get_tree().root)

func _ligar_existentes(no: Node) -> void:
	for filho in no.get_children():
		if filho != self:
			_on_node_added(filho)
			_ligar_existentes(filho)

func _process(delta: float) -> void:
	_atualizar_tensao(delta)
	_atualizar_eventos(delta)
	var alvo := CORTE_ABAFADO if get_tree().paused else CORTE_ABERTO
	_corte = exp(move_toward(log(_corte), log(alvo), VEL_FILTRO * delta))
	for filtro in _filtros:
		filtro.cutoff_hz = _corte

# [E] sem nada que aceite a interação (terminal já usado, porta trancada...): beep de erro.
# Terminais, dutos e máquinas consomem o evento quando funcionam, então ele só chega aqui sobrando.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interagir") or get_tree().paused:
		return
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador and not jogador.get("controle_bloqueado") and _interacao_trancada(jogador):
		tocar_sfx(SOM_ERRO)

# Isca sem recarga/energia: o lançador engole a tecla, então checa antes dele
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("lancar_isca") or get_tree().paused:
		return
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var lancador := jogador.get_node_or_null("LancadorIsca")
	if lancador and lancador.has_method("_pode_lancar") and not jogador.get("controle_bloqueado") and not lancador.call("_pode_lancar"):
		tocar_sfx(SOM_ERRO, -4.0)

# ──────────────────────────────────────────────
# API pública
# ──────────────────────────────────────────────

func tocar_sfx(nome: String, volume_db := 0.0, variar_pitch := true) -> AudioStreamPlayer:
	return _tocar_uma_vez(_carregar("sfx", nome), "SFX", volume_db, variar_pitch) as AudioStreamPlayer

## Som posicional: mais alto perto da câmera, com pan esquerda/direita.
func tocar_sfx_2d(nome: String, posicao: Vector2, volume_db := 0.0, variar_pitch := true) -> AudioStreamPlayer2D:
	return _tocar_uma_vez(_carregar("sfx", nome), "SFX", volume_db, variar_pitch, posicao) as AudioStreamPlayer2D

func tocar_ambiente(nome: String, fade := 2.5) -> void:
	_camada_ambiente = _trocar_camada(_camada_ambiente, "ambiente", nome, "Ambiente", fade, true)

func tocar_musica(nome: String, fade := 2.0) -> void:
	_camada_musica = _trocar_camada(_camada_musica, "musica", nome, "Musica", fade, false, 3.0)

func parar_ambiente(fade := 1.5) -> void:
	for camada in [_camada_ambiente, _camada_motores, _camada_tensao, _camada_emergencia]:
		if is_instance_valid(camada):
			camada.parar(fade)

func parar_musica(fade := 1.5) -> void:
	if is_instance_valid(_camada_musica):
		_camada_musica.parar(fade)

# ──────────────────────────────────────────────
# Carregamento e reprodução
# ──────────────────────────────────────────────

func _carregar(subpasta: String, nome: String) -> AudioStream:
	var base := PASTA + subpasta + "/" + nome
	var caminhos: Array = [base] if nome.get_extension() != "" else EXTENSOES.map(func(e): return base + "." + e)
	for caminho in caminhos:
		if ResourceLoader.exists(caminho):
			return load(caminho)
	if not _avisados.has(base):
		_avisados[base] = true
		push_warning("Audio: som não encontrado: %s" % base)
	return null

## Tenta o som principal e, se ele faltar (ex.: ainda não importado), usa a reserva.
func _carregar_ou(subpasta: String, nome: String, reserva: String) -> AudioStream:
	var stream := _carregar(subpasta, nome)
	return stream if stream else _carregar(subpasta, reserva)

func _ganho(stream: AudioStream) -> float:
	return MIXAGEM.get(stream.resource_path.get_file(), 0.0)

# Cópia com loop ligado: o recurso original fica intacto (o mesmo som pode ser usado como SFX)
func _com_loop(stream: AudioStream) -> AudioStream:
	var s = stream.duplicate()
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	elif s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = true
	return s

func _criar_player(stream: AudioStream, bus: String, posicao, max_distancia := DISTANCIA_MAX_2D) -> Node:
	var p
	if posicao == null:
		p = AudioStreamPlayer.new()
		add_child(p)
	else:
		p = AudioStreamPlayer2D.new()
		p.max_distance = max_distancia
		# Fica na cena atual, para sumir junto com ela na troca de fase
		var cena := get_tree().current_scene
		(cena if cena else self).add_child(p)
		p.global_position = posicao
	p.stream = stream
	p.bus = bus
	p.finished.connect(p.queue_free)
	return p

func _tocar_uma_vez(stream: AudioStream, bus: String, volume_db: float, variar_pitch: bool, posicao = null) -> Node:
	if stream == null:
		return null
	var p = _criar_player(stream, bus, posicao)
	p.volume_db = volume_db + _ganho(stream)
	if variar_pitch:
		p.pitch_scale = randf_range(0.9, 1.1)  # evita som repetitivo
	p.play()
	return p

## Toca só um trecho de `duracao` s a partir de `desde`, com fade de entrada e de saída.
func _tocar_trecho(stream: AudioStream, bus: String, volume_db: float, desde: float, duracao: float,
		fade_in: float, fade_out: float, pitch := 1.0, posicao = null, max_distancia := DISTANCIA_MAX_2D) -> Node:
	if stream == null:
		return null
	var p = _criar_player(stream, bus, posicao, max_distancia)
	p.pitch_scale = pitch
	p.volume_db = VOLUME_MUDO
	p.play(desde)
	var t: Tween = p.create_tween()
	t.tween_property(p, "volume_db", volume_db + _ganho(stream), fade_in)
	t.tween_interval(maxf(duracao - fade_in - fade_out, 0.0))
	t.tween_property(p, "volume_db", VOLUME_MUDO, fade_out)
	t.tween_callback(p.queue_free)
	return p

## Some com um player (fade) e o libera.
func _sumir(p, tempo: float) -> void:
	if not is_instance_valid(p) or p.is_queued_for_deletion() or p.has_meta("sumindo"):
		return
	p.set_meta("sumindo", true)
	var t: Tween = p.create_tween()
	t.tween_property(p, "volume_db", VOLUME_MUDO, tempo)
	t.tween_callback(p.queue_free)

# Mesmo som já tocando (ex.: reiniciar a fase): mantém. Outro som: crossfade entre os dois.
func _trocar_camada(atual, subpasta: String, nome: String, bus: String, fade: float,
		aleatorio: bool, crossfade := 2.0, volume_db := 0.0):
	if is_instance_valid(atual) and atual.nome == nome and not atual.saindo():
		return atual
	if is_instance_valid(atual):
		atual.parar(fade)
	var stream := _carregar(subpasta, nome)
	if stream == null:
		return null
	var corte: Array = CORTES.get(nome, [0.0, 0.0])
	var camada := LoopContinuo.new()
	camada.nome = nome
	camada.ganho_db = _ganho(stream) + volume_db
	camada.configurar(stream, bus, corte[0], corte[1], crossfade)
	add_child(camada)
	camada.tocar(fade, aleatorio)
	return camada

# ──────────────────────────────────────────────
# Clima: tensão, eventos aleatórios
# ──────────────────────────────────────────────

func _contar_perseguidores() -> int:
	var total := 0
	for m in get_tree().get_nodes_in_group("monstro"):
		if m.get("perseguindo") and m.get("visible"):
			total += 1
	return total

func _atualizar_tensao(delta: float) -> void:
	var perseguidores := _contar_perseguidores() if _em_fase and not _jogador_morto else 0
	_atualizar_emergencia(delta, perseguidores)
	var alvo := VOLUME_MUDO
	if perseguidores > 0:
		alvo = VOLUME_TENSAO_MAX
	var vel := TENSAO_SOBE_DB_S if alvo > _tensao_db else TENSAO_DESCE_DB_S
	_tensao_db = move_toward(_tensao_db, alvo, vel * delta)
	var fracao := db_to_linear(_tensao_db) / db_to_linear(VOLUME_TENSAO_MAX)
	if is_instance_valid(_camada_tensao):
		_camada_tensao.ajuste_db = _tensao_db
	if is_instance_valid(_camada_ambiente):
		_camada_ambiente.ajuste_db = DUCK_AMBIENTE_DB * fracao

## Chamado pelo SomMonstro quando um alien adormecido surge: som de surgimento da fase
## (se houver) na hora e, pouco depois, alarme até o fim da fase.
func alien_surgiu(monstro: Node2D) -> void:
	var cena := get_tree().current_scene
	var som: String = SURGIMENTO_POR_FASE.get(cena.scene_file_path if cena else "", "")
	if som != "":
		tocar_sfx_2d(som, monstro.global_position, VOLUME_SURGIMENTO, false)
	# Timer pausável e marcado com a "geração" da fase: se ela recarregar antes, não liga
	var geracao := _geracao_fase
	get_tree().create_timer(ATRASO_EMERGENCIA, false).timeout.connect(func():
		if geracao == _geracao_fase:
			_emergencia_fixa = true)

# Na perseguição o alarme soa "em algum momento": se ela durar muito ou vierem 2+ aliens.
# Depois disso descansa um tempo, pra não virar trilha fixa de toda perseguição.
func _atualizar_emergencia(delta: float, perseguidores: int) -> void:
	_espera_emergencia = maxf(_espera_emergencia - delta, 0.0)
	if perseguidores > 0:
		_tempo_perseguicao += delta
		if not _emergencia_perseguicao and _espera_emergencia <= 0.0 \
				and (_tempo_perseguicao >= PERSEGUICAO_LONGA or perseguidores >= 2):
			_emergencia_perseguicao = true
	else:
		if _emergencia_perseguicao:
			_espera_emergencia = EMERGENCIA_PAUSA
		_emergencia_perseguicao = false
		_tempo_perseguicao = 0.0
	var ligado := _em_fase and not _jogador_morto and (_emergencia_fixa or _emergencia_perseguicao)
	var alvo := VOLUME_EMERGENCIA if ligado else VOLUME_MUDO
	var vel := EMERGENCIA_SOBE_DB_S if alvo > _emergencia_db else EMERGENCIA_DESCE_DB_S
	_emergencia_db = move_toward(_emergencia_db, alvo, vel * delta)
	if is_instance_valid(_camada_emergencia):
		_camada_emergencia.ajuste_db = _emergencia_db

# Só com a nave "calma": durante perseguição a camada de tensão já ocupa esse espaço
func _atualizar_eventos(delta: float) -> void:
	if not _em_fase or _jogador_morto or get_tree().paused:
		return
	_atualizar_quebra(delta)
	if _tensao_db > VOLUME_MUDO + 1.0:
		return
	_proximo_evento -= delta
	if _proximo_evento <= 0.0:
		_proximo_evento = randf_range(EVENTO_INTERVALO.x, EVENTO_INTERVALO.y)
		_evento_aleatorio()

# De tempos em tempos a nave "ronca" mais alto: um trecho do ambiente forte por cima do
# normal, entrando e saindo bem devagar, pra quebrar a monotonia
func _atualizar_quebra(delta: float) -> void:
	_proxima_quebra -= delta
	if _proxima_quebra > 0.0:
		return
	_proxima_quebra = randf_range(QUEBRA_INTERVALO.x, QUEBRA_INTERVALO.y)
	var stream := _carregar("ambiente", AMBIENTE_NAVE_ALTO)
	if stream == null:
		return
	var duracao := minf(randf_range(QUEBRA_DURACAO.x, QUEBRA_DURACAO.y), stream.get_length())
	var desde := randf_range(0.0, maxf(stream.get_length() - duracao, 0.0))
	_tocar_trecho(stream, "Ambiente", 0.0, desde, duracao, QUEBRA_FADE, QUEBRA_FADE)

# Um som de alien vindo de algum lugar em volta do jogador (parado lá: dá direção pelo pan)
func _evento_aleatorio() -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var pos := jogador.global_position + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 240.0)
	if randf() < 0.7:
		# Trecho do ambiente de alien, entrando e saindo devagar
		var stream := _carregar("ambiente", AMBIENTE_ALIEN)
		if stream == null:
			return
		var corte: Array = CORTES.get(AMBIENTE_ALIEN, [0.0, 0.0])
		var duracao := randf_range(8.0, 16.0)
		var desde := randf_range(corte[0], maxf(stream.get_length() - corte[1] - duracao, corte[0]))
		# RMS do arquivo -30 dB e ainda atenua pela distância: fica um pouco acima do ambiente
		_tocar_trecho(stream, "Ambiente", randf_range(-5.0, 0.0), desde, duracao, 3.0, 3.5,
				randf_range(0.85, 1.0), pos, DISTANCIA_EVENTO)
	else:
		# Rosnado grave e distante
		var rosnado := _carregar("sfx", SOM_ALIEN_PERSEGUE)
		if rosnado == null:
			return
		var pitch := randf_range(0.55, 0.75)
		_tocar_trecho(rosnado, "Ambiente", -9.0, 0.0, rosnado.get_length() / pitch, 0.4, 1.0,
				pitch, pos, DISTANCIA_EVENTO)

# ──────────────────────────────────────────────
# Ligação automática com as cenas do jogo
# ──────────────────────────────────────────────

func _on_node_added(node: Node) -> void:
	if node.get_parent() == get_tree().root and node.scene_file_path == CENA_MENU:
		_entrar_no_menu()
	# Qualquer botão (menu, pausa, morte, diálogos...): o player fica no autoload, então
	# o clique continua tocando mesmo se o botão trocar de cena na hora
	if node is BaseButton:
		node.pressed.connect(func(): _tocar_uma_vez(_carregar("sfx", SOM_BOTAO), "Interface", 0.0, false))
	var script: Script = node.get_script()
	if script == null:
		return
	var caminho := script.resource_path
	if caminho.begins_with(PREFIXO_ITEM):
		_ligar_item(node)
	# Adiado: durante node_added o nó ainda está entrando na árvore e o _ready dele não rodou
	match caminho:
		SCRIPT_JOGADOR:
			_anexar_jogador.call_deferred(node)
		SCRIPT_MONSTRO:
			_anexar_monstro.call_deferred(node)
		SCRIPT_PORTA:
			_portas.append(node as Node2D)
			_ligar_sinal.call_deferred(node, "trava_liberada", SOM_PORTA_TRAVA, 0.35)
			# Abrindo: beep na hora (LED fica verde) e o deslizar quando as metades se movem (0,3 s)
			_ligar_sinal.call_deferred(node, "aberta", SOM_PORTA_TRAVA, 0.0)
			_ligar_sinal.call_deferred(node, "aberta", SOM_PORTA_CORRER, 0.3)
		SCRIPT_TERMINAL:
			_interativos.append(node)
			_anexar_terminal.call_deferred(node)
		SCRIPT_MAQUINA:
			_interativos.append(node)
			_anexar_maquina.call_deferred(node)
		SCRIPT_ISCA:
			tocar_sfx(SOM_ISCA_LANCAR)
			_anexar_isca.call_deferred(node)
		SCRIPT_TELA_MORTE:
			_jogador_morto = true
			# Morreu com energia sobrando = pego por um monstro. No bus Interface: o jogo
			# pausa e abafa, mas esse som tem que soar inteiro
			# Sem energia = morreu apagando; com energia sobrando = pego por um monstro
			var jogador := get_tree().get_first_node_in_group("jogador")
			if jogador and jogador.get("energia_atual") > 0.0:
				var morte := _carregar("sfx", SOM_MORTE_MONSTRO)
				if morte:
					_tocar_trecho(morte, "Interface", 0.0, MORTE_MONSTRO_ADIANTAR,
							morte.get_length() - MORTE_MONSTRO_ADIANTAR, 0.03, 0.3)
			elif jogador:
				_tocar_uma_vez(_carregar("sfx", SOM_MORTE_ENERGIA), "Interface", 0.0, false)
		SCRIPT_DUTO:
			_anexar_duto.call_deferred(node)
		SCRIPT_HISTORIA:
			_anexar_historia.call_deferred(node)
		SCRIPT_POD:
			_anexar_pod.call_deferred(node)

func _entrar_no_menu() -> void:
	_em_fase = false
	parar_ambiente(1.5)
	tocar_musica(MUSICA_MENU)

# O jogador só existe dentro de uma fase: é o gatilho do áudio de fase
func _anexar_jogador(jogador: CharacterBody2D) -> void:
	if not is_instance_valid(jogador):
		return
	_em_fase = true
	_jogador_morto = false
	_tensao_db = VOLUME_MUDO
	_emergencia_db = VOLUME_MUDO
	_emergencia_fixa = false # a fase recarregou: os aliens voltam a dormir
	_geracao_fase += 1
	_emergencia_perseguicao = false
	_tempo_perseguicao = 0.0
	_espera_emergencia = 0.0
	_proximo_evento = randf_range(12.0, 25.0)
	_proxima_quebra = randf_range(30.0, 60.0)
	_portas = _portas.filter(func(n): return is_instance_valid(n))
	_interativos = _interativos.filter(func(n): return is_instance_valid(n))
	parar_musica(2.0)
	tocar_ambiente(AMBIENTE_NAVE, 3.0)
	_camada_motores = _trocar_camada(_camada_motores, "ambiente", AMBIENTE_MOTORES, "Ambiente", 4.0, true, 3.0)
	if _camada_motores:
		_camada_motores.deriva_db = 6.0 # sobe e desce devagar: tira a monotonia
	if is_instance_valid(_camada_ambiente):
		_camada_ambiente.deriva_db = 2.5
	# Tensão e emergência ficam tocando mudas; o volume sobe conforme a situação
	_camada_tensao = _trocar_camada(_camada_tensao, "ambiente", AMBIENTE_ALIEN, "Tensao", 0.5, true, 3.0)
	_camada_emergencia = _trocar_camada(_camada_emergencia, "ambiente", ALERTA_DESPERTAR, "Tensao", 0.5, true, 2.0)
	for camada in [_camada_tensao, _camada_emergencia]:
		if is_instance_valid(camada):
			camada.ajuste_db = VOLUME_MUDO

	if jogador.has_signal("energia_recarregada"):
		jogador.connect("energia_recarregada", func(): tocar_sfx(SOM_COLETAR_ENERGIA))

	var som := SomJogador.new()
	som.audio = self
	var stream := _carregar_ou("sfx", SOM_PASSOS, SOM_PASSOS_ORIGINAL)
	if stream:
		som.passos = AudioStreamPlayer.new()
		som.passos.stream = _com_loop(stream)
		som.passos.bus = "SFX"
		som.volume_passos_db = _ganho(stream)
		som.add_child(som.passos)
	jogador.add_child(som)

func _anexar_monstro(monstro: CharacterBody2D) -> void:
	if not is_instance_valid(monstro):
		return
	# Tipo pela cena instanciada (monstro_rapido.tscn etc.); desconhecida = besouro
	var tipo: Dictionary = ALIENS.get(monstro.scene_file_path, ALIENS[ALIEN_PADRAO])
	var som := SomMonstro.new()
	som.audio = self
	som.grito = tipo.get("grito", SOM_ALIEN_PERSEGUE)
	som.pitch_grito = tipo.get("pitch_grito", 1.0)
	# Leve variação por indivíduo: dois besouros na mesma sala não soam idênticos
	som.pitch_scale = tipo.get("pitch", 1.0) * randf_range(0.96, 1.04)
	som.rajadas = tipo.get("modo", "loop") == "rajadas"
	som.intervalo = tipo.get("intervalo", Vector2(1.0, 3.0))
	var stream := _carregar("sfx", tipo.get("presenca", SOM_ALIEN_PRESENCA))
	if stream:
		som.stream = stream if som.rajadas else _com_loop(stream)
		som.volume_base_db = _ganho(stream) + tipo.get("volume_db", 0.0)
	som.bus = "SFX"
	som.max_distance = DISTANCIA_MONSTRO
	monstro.add_child(som)

# Computador: beep digital. Nos dormitórios, as "centrais" são alavancas.
func _anexar_terminal(terminal: Node2D) -> void:
	if not is_instance_valid(terminal):
		return
	var som := SOM_COMPUTADOR
	for trecho in TERMINAIS_ALAVANCA:
		if trecho in String(terminal.name):
			som = SOM_ALAVANCA
	_observar(terminal, "_usado", func(_antes, agora):
		if agora:
			tocar_sfx_2d(som, terminal.global_position))

# Skill check: aviso ao começar cada checagem, beep a cada acerto e erro ao falhar
func _anexar_maquina(maquina: Node2D) -> void:
	if not is_instance_valid(maquina):
		return
	_observar(maquina, "_estado", func(antes, agora):
		if agora == ESTADO_GIRANDO:
			tocar_sfx(SOM_SKILL_CHECK, 0.0, false)
		# Voltou a parado sem concluir e sem o [E] de desistir = errou
		elif agora == ESTADO_PARADO and antes != ESTADO_PARADO and not maquina.get("_usado") \
				and not Input.is_action_just_pressed("interagir"):
			tocar_sfx(SOM_ERRO))
	# Beep a cada acerto, subindo o tom conforme o progresso
	_observar(maquina, "_acertos", func(antes, agora):
		if agora > antes:
			var beep := tocar_sfx(SOM_COMPUTADOR, -4.0, false)
			if beep:
				beep.pitch_scale = 1.25 + 0.1 * agora)
	_ligar_sinal(maquina, "concluida", SOM_COMPUTADOR)

# A isca acende depois do voo: chiado do sinalizador enquanto ela brilha
func _anexar_isca(isca: Node2D) -> void:
	if not is_instance_valid(isca):
		return
	_observar(isca, "_ativa", func(_antes, agora):
		if not agora:
			return
		var stream := _carregar("sfx", SOM_ISCA_ACESA)
		var duracao: float = isca.get("duracao") if isca.get("duracao") else 8.0
		var p = _tocar_trecho(stream, "SFX", 0.0, 0.0, minf(duracao, stream.get_length() if stream else 0.0), 0.3, 1.5, 1.0, isca.global_position)
		if p:
			isca.tree_exiting.connect(_sumir.bind(p, 0.4)))

# Duto abre na entrada e de novo (mais baixo) na saída, depois do escurecimento
func _anexar_duto(duto: Node2D) -> void:
	if not is_instance_valid(duto):
		return
	_observar(duto, "_em_uso", func(_antes, agora):
		if not agora:
			return
		tocar_sfx(SOM_DUTO)
		var espera: float = duto.get("tempo_escuro") if duto.get("tempo_escuro") else 0.35
		await get_tree().create_timer(espera).timeout
		var saida := tocar_sfx(SOM_DUTO, -4.0, false)
		if saida:
			saida.pitch_scale = 0.92)

# Pod de fuga (fim do jogo): ao embarcar, lançamento e a nave vai sumindo atrás.
# O som fica no autoload, então continua na tela de fim de jogo até acabar sozinho.
func _anexar_pod(pod: Node2D) -> void:
	if not is_instance_valid(pod):
		return
	_observar(pod, "_embarcou", func(_antes, agora):
		if not agora:
			return
		var stream := _carregar("sfx", SOM_POD)
		if stream:
			_tocar_trecho(stream, "SFX", 0.0, POD_ADIANTAR, stream.get_length() - POD_ADIANTAR, 0.05, 1.5)
		_em_fase = false # sem eventos aleatórios nem tensão durante a fuga
		parar_ambiente(4.0))

# História da fase 1: teclado enquanto cada fala está sendo "digitada"
func _anexar_historia(historia: Node) -> void:
	if not is_instance_valid(historia) or historia.is_queued_for_deletion():
		return
	var stream := _carregar_ou("sfx", SOM_TECLADO, SOM_TECLADO_ORIGINAL)
	if stream == null:
		return
	var som := SomTeclado.new()
	som.audio = self
	som.stream = stream
	historia.add_child(som)

# Item pego some com queue_free(); na troca de cena ele é liberado sem isso (não toca)
func _ligar_item(item: Node) -> void:
	item.tree_exiting.connect(func():
		if item.is_queued_for_deletion():
			tocar_sfx(SOM_PEGAR_ITEM))

func _ligar_sinal(node: Node2D, sinal: String, nome_som: String, atraso := 0.0) -> void:
	if not is_instance_valid(node) or not node.has_signal(sinal):
		return
	var tocar := func():
		if atraso > 0.0:
			await get_tree().create_timer(atraso).timeout
		if is_instance_valid(node):
			tocar_sfx_2d(nome_som, node.global_position)
	# unbind() descarta os argumentos do sinal (ex.: trava_liberada(restantes))
	var n_args := 0
	for s in node.get_signal_list():
		if s.name == sinal:
			n_args = s.args.size()
	node.connect(sinal, tocar.unbind(n_args) if n_args > 0 else tocar)

func _observar(alvo: Node, propriedade: String, ao_mudar: Callable) -> void:
	var o := Observador.new()
	o.propriedade = propriedade
	o.ao_mudar = ao_mudar
	alvo.add_child(o)

func _interacao_trancada(jogador: Node2D) -> bool:
	for n in _interativos:
		if is_instance_valid(n) and n.get("_jogador_perto") and n.get("_usado"):
			return true
	for p in _portas:
		if is_instance_valid(p) and not p.get("esta_aberta") \
				and p.global_position.distance_to(jogador.global_position) <= DISTANCIA_PORTA:
			return true
	return false

# ──────────────────────────────────────────────
# Classes internas
# ──────────────────────────────────────────────

## Loop sem emenda: duas vozes do mesmo som se revezam num crossfade de potência constante,
## pulando os trechos cortados. Também faz fade ao ligar/desligar e pode "respirar"
## (deriva_db: o volume sobe e desce devagar e ao acaso, pra não soar parado).
class LoopContinuo extends Node:
	var nome := ""
	var ganho_db := 0.0 ## Volume fixo da camada (mixagem)
	var ajuste_db := 0.0 ## Volume variável (tensão, duck)
	var deriva_db := 0.0 ## Amplitude da variação lenta e aleatória (0 = desligada)
	var _crossfade := 2.0
	var _ini := 0.0
	var _fim := 0.0
	var _vozes: Array[AudioStreamPlayer] = []
	var _atual := 0
	var _nivel := 0.0
	var _alvo_nivel := 1.0
	var _vel_nivel := 1.0
	var _liberar := false
	var _deriva := 0.0
	var _deriva_alvo := 0.0
	var _deriva_tempo := 0.0

	func configurar(stream: AudioStream, bus: String, corte_ini: float, corte_fim: float, crossfade: float) -> void:
		_ini = corte_ini
		_fim = maxf(stream.get_length() - corte_fim, corte_ini + 0.5)
		_crossfade = minf(crossfade, (_fim - _ini) / 3.0)
		for i in 2:
			var v := AudioStreamPlayer.new()
			v.stream = stream
			v.bus = bus
			v.volume_db = -80.0
			add_child(v)
			_vozes.append(v)

	func tocar(fade: float, aleatorio := false) -> void:
		var desde := randf_range(_ini, maxf(_fim - _crossfade * 2.0, _ini)) if aleatorio else _ini
		_vozes[0].set_meta("entrada", desde - _crossfade) # sem fade da voz: o fade geral cuida
		_vozes[0].play(desde)
		_nivel = 0.0
		_alvo_nivel = 1.0
		_vel_nivel = 1.0 / maxf(fade, 0.01)

	func parar(fade: float) -> void:
		_alvo_nivel = 0.0
		_vel_nivel = 1.0 / maxf(fade, 0.01)
		_liberar = true

	func saindo() -> bool:
		return _liberar

	func _process(delta: float) -> void:
		_nivel = move_toward(_nivel, _alvo_nivel, _vel_nivel * delta)
		if _liberar and _nivel <= 0.0:
			queue_free()
			return
		if deriva_db > 0.0:
			_deriva_tempo -= delta
			if _deriva_tempo <= 0.0:
				_deriva_alvo = randf_range(-deriva_db, 0.0)
				_deriva_tempo = randf_range(8.0, 18.0)
			_deriva = move_toward(_deriva, _deriva_alvo, 0.4 * delta)
		var base := db_to_linear(ganho_db + ajuste_db + _deriva) * _nivel
		for i in 2:
			var v := _vozes[i]
			if not v.playing:
				continue
			var pos := v.get_playback_position()
			var entrada: float = v.get_meta("entrada", _ini)
			var env := sin(clampf((pos - entrada) / _crossfade, 0.0, 1.0) * PI / 2.0)
			env *= cos(clampf((pos - (_fim - _crossfade)) / _crossfade, 0.0, 1.0) * PI / 2.0)
			v.volume_db = linear_to_db(maxf(base * env, 0.00001))
			if pos >= _fim:
				v.stop()
			elif i == _atual and pos >= _fim - _crossfade:
				var outra := _vozes[1 - i]
				if not outra.playing:
					outra.set_meta("entrada", _ini)
					outra.volume_db = -80.0
					outra.play(_ini)
					_atual = 1 - i

## Vigia uma propriedade de outro nó (quando não há sinal pra isso) e avisa quando muda.
class Observador extends Node:
	var propriedade := ""
	var ao_mudar: Callable
	var _antes

	func _ready() -> void:
		_antes = get_parent().get(propriedade)

	func _process(_delta: float) -> void:
		var agora = get_parent().get(propriedade)
		if agora != _antes:
			var antes = _antes
			_antes = agora
			ao_mudar.call(antes, agora)

## Teclado da história: um trecho do som (a partir de um ponto aleatório) enquanto o texto
## aparece; some rápido quando a fala termina ou o jogador clica pra completar.
class SomTeclado extends Node:
	var audio ## O próprio autoload (sem tipo, para chamar as funções dele)
	var stream: AudioStream
	var _digitando_antes := false
	var _player

	func _process(_delta: float) -> void:
		var historia := get_parent()
		var texto := historia.get("_texto") as Label
		var painel := historia.get("_painel") as Control
		var digitando: bool = texto != null and painel != null and painel.visible \
				and texto.visible_ratio < 1.0 and not historia.get("_encerrando")
		if digitando and not _digitando_antes:
			var desde := randf_range(0.0, maxf(stream.get_length() - 4.0, 0.0))
			_player = audio._tocar_trecho(stream, "Interface", 0.0, desde, stream.get_length() - desde, 0.05, 0.1)
		elif not digitando and _digitando_antes:
			audio._sumir(_player, 0.12)
		_digitando_antes = digitando

## Passos (com fade curto, sem corte seco) e o som da lanterna no modo foco.
class SomJogador extends Node:
	var audio ## O próprio autoload (sem tipo, para chamar as funções dele)
	var passos: AudioStreamPlayer
	var volume_passos_db := 0.0
	var _nivel_passos := 0.0
	var _foco_antes := 0.0
	var _luz ## Sem tipo: fica guardando o player depois que ele é liberado

	func _physics_process(delta: float) -> void:
		var jogador := get_parent() as CharacterBody2D
		if passos:
			var andando := jogador.velocity.length() > 1.0
			_nivel_passos = move_toward(_nivel_passos, 1.0 if andando else 0.0, delta / 0.12)
			if andando and not passos.playing:
				passos.play()
			elif _nivel_passos <= 0.0 and passos.playing:
				passos.stop()
			passos.volume_db = volume_passos_db + linear_to_db(maxf(_nivel_passos, 0.00001))
		# Lanterna focada: liga com o clique e some suave ao soltar (ou ao acabar a energia)
		var foco: float = jogador.get("fator_foco")
		if foco > 0.0 and _foco_antes == 0.0:
			_luz = audio.tocar_sfx(SOM_LUZ_FOCO, 0.0, false)
		elif foco < _foco_antes:
			audio._sumir(_luz, 0.25)
		_foco_antes = foco

## Rosnado 2D em loop do monstro (entra e sai em fade) + avisos de perseguição e despertar.
class SomMonstro extends AudioStreamPlayer2D:
	var audio ## O próprio autoload (sem tipo, para chamar as funções dele)
	var volume_base_db := 0.0
	var grito := SOM_ALIEN_PERSEGUE
	var pitch_grito := 1.0
	var rajadas := false
	var intervalo := Vector2(1.0, 3.0)
	var _espera := 0.0
	var _nivel := 0.0
	var _perseguindo_antes := false
	var _visivel_antes := true

	func _ready() -> void:
		_visivel_antes = (get_parent() as Node2D).visible

	func _physics_process(delta: float) -> void:
		var monstro := get_parent() as Node2D
		var perseguindo: bool = monstro.get("perseguindo")
		_nivel = move_toward(_nivel, 1.0 if monstro.visible else 0.0, delta / 1.5)
		if rajadas:
			# Toca o som inteiro, pausa um pouco ao acaso e repete
			_espera -= delta
			if monstro.visible and not playing and stream and _espera <= 0.0:
				play()
				_espera = stream.get_length() / pitch_scale + randf_range(intervalo.x, intervalo.y)
		elif monstro.visible and not playing and stream:
			# Começa num ponto aleatório: vários monstros não rosnam em sincronia
			play(randf() * stream.get_length())
		if _nivel <= 0.0 and playing:
			stop()
		volume_db = volume_base_db + linear_to_db(maxf(_nivel, 0.00001))
		# Alien adormecido surgiu (vent da fase 3, celas da fase 4, Espécime da fase 5)
		if monstro.visible and not _visivel_antes:
			audio.alien_surgiu(monstro)
		if perseguindo and not _perseguindo_antes:
			var p = audio.tocar_sfx_2d(grito, monstro.global_position)
			if p:
				p.pitch_scale *= pitch_grito
		_visivel_antes = monstro.visible
		_perseguindo_antes = perseguindo
