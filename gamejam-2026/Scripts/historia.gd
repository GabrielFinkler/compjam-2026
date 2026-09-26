extends CanvasLayer
## História do começo da fase 1: o personagem está na ponte de comando, com o alarme
## vermelho piscando, e o computador da nave fala numa caixa de texto embaixo da tela.
## Cada clique (ou Espaço/Enter) passa pra próxima fala; clicar enquanto o texto ainda
## está aparecendo mostra ele inteiro. Enquanto isso o personagem não anda, não mira e não
## gasta energia. Só passa uma vez por sessão: morrer e recarregar a fase não repete.

const FALAS := [
	"Alerta, Traco! Foi detectada uma falha total nos reatores principais. A nave está usando a sua energia vital para manter os sistemas essenciais.",
	"Alimente sua energia vital com os Globs espalhados pela nave. Caso a barra se esgote completamente, estaremos fadados à morte.",
	"Cuidado! Pode haver invasores no caminho. Pelo que identifiquei, eles são sensíveis à luz. Para se defender, você pode atingi-los concentrando a sua luz em um raio direcionado.",
	"Mas atenção: isso consumirá a sua energia mais rápido. Utilize com sabedoria.",
	"Vá até a sala de sistemas para desbloquear a porta da engenharia e liberar a saída. Confiamos em você!",
]
const NOME := "COMPUTADOR DA NAVE"
const COR_ALERTA := Color(1.0, 0.22, 0.15)
const LETRAS_POR_SEGUNDO := 45.0
const TEMPO_ENTRADA := 1.2 # Tela clareando do preto antes da primeira fala
const CHAVE_VISTA := &"historia_fase1_vista" # Guardada no root: sobrevive ao reload da cena ao morrer

var _jogador: Node2D
var _indice: int = 0
var _pronto: bool = false # Só aceita clique depois que a tela clareou
var _encerrando: bool = false
var _painel: PanelContainer
var _texto: Label
var _seta: Label
var _digitando: Tween
var _alarme: PointLight2D
var _pisca_alarme: Tween

func _ready() -> void:
	layer = 10 # Por cima do HUD
	_jogador = get_tree().get_first_node_in_group("jogador")
	if _jogador == null or get_tree().root.get_meta(CHAVE_VISTA, false):
		queue_free()
		return
	_jogador.em_cena = true
	_criar_alarme()
	_criar_interface()

	# Começa no preto e vai clareando, com o alarme já piscando na ponte de comando
	var preto := ColorRect.new()
	preto.color = Color.BLACK
	preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preto)
	preto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(preto, "color:a", 0.0, TEMPO_ENTRADA)
	tween.tween_callback(preto.queue_free)
	tween.tween_callback(_comecar_falas)

func _comecar_falas() -> void:
	_pronto = true
	_mostrar_fala(0)

func _input(event: InputEvent) -> void:
	if not _pronto or _encerrando:
		return
	var clicou: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicou or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_avancar()

func _avancar() -> void:
	# Texto ainda aparecendo: o clique só completa a fala
	if _texto.visible_ratio < 1.0:
		_digitando.kill()
		_texto.visible_ratio = 1.0
		_seta.visible = true
	elif _indice + 1 < FALAS.size():
		_mostrar_fala(_indice + 1)
	else:
		_encerrar()

func _mostrar_fala(indice: int) -> void:
	_indice = indice
	_painel.visible = true
	_texto.text = FALAS[indice]
	_texto.visible_ratio = 0.0
	_seta.visible = false
	_digitando = create_tween()
	_digitando.tween_property(_texto, "visible_ratio", 1.0, FALAS[indice].length() / LETRAS_POR_SEGUNDO)
	_digitando.tween_callback(func(): _seta.visible = true)

func _encerrar() -> void:
	_encerrando = true
	get_tree().root.set_meta(CHAVE_VISTA, true)
	_pisca_alarme.kill()
	var tween := create_tween()
	tween.tween_property(_painel, "modulate:a", 0.0, 0.4)
	# Solta o personagem só depois: o último clique ainda segurado não acende o foco
	tween.tween_callback(func(): _jogador.em_cena = false)
	tween.parallel().tween_property(_alarme, "energy", 0.0, 1.5)
	tween.tween_callback(_alarme.queue_free)
	tween.tween_callback(queue_free)

# Luz vermelha grande em cima da ponte de comando, pulsando como sirene
func _criar_alarme() -> void:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	_alarme = PointLight2D.new()
	_alarme.texture = textura
	_alarme.texture_scale = 6.0 # ~190 px de raio: cobre a sala toda
	_alarme.color = COR_ALERTA
	_alarme.energy = 0.0
	_alarme.shadow_enabled = true # As paredes seguram a luz dentro da sala
	_alarme.position = _jogador.global_position # A raiz da fase fica na origem
	# Adiado: a fase ainda está montando os filhos quando este _ready roda
	get_tree().current_scene.add_child.call_deferred(_alarme)
	_pisca_alarme = create_tween().set_loops()
	_pisca_alarme.tween_property(_alarme, "energy", 0.9, 0.5).set_trans(Tween.TRANS_SINE)
	_pisca_alarme.tween_property(_alarme, "energy", 0.1, 0.7).set_trans(Tween.TRANS_SINE)

# Caixa de texto embaixo da tela: nome do computador, a fala e uma setinha piscando
# quando dá pra passar pra próxima
func _criar_interface() -> void:
	_painel = PanelContainer.new()
	_painel.theme = preload("res://Scripts/tema_pixel.gd").criar()
	_painel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_painel.offset_left = 12
	_painel.offset_right = -12
	_painel.offset_bottom = -8
	_painel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_painel.visible = false
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.03, 0.05, 0.88)
	estilo.border_color = COR_ALERTA
	estilo.set_border_width_all(1)
	estilo.border_width_left = 3
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(7)
	_painel.add_theme_stylebox_override("panel", estilo)
	add_child(_painel)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 6)
	_painel.add_child(caixa)

	var nome := Label.new()
	nome.text = NOME
	nome.add_theme_color_override("font_color", COR_ALERTA)
	caixa.add_child(nome)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(0, 44) # 4 linhas: a caixa não muda de tamanho entre falas
	_texto.add_theme_constant_override("line_spacing", 3)
	# Quebra as linhas pelo texto inteiro: as palavras não pulam de linha enquanto aparecem
	_texto.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	caixa.add_child(_texto)

	_seta = Label.new()
	_seta.text = "CLIQUE PARA CONTINUAR >"
	_seta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_seta.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	caixa.add_child(_seta)
	var pisca := create_tween().set_loops()
	pisca.tween_property(_seta, "modulate:a", 0.3, 0.5)
	pisca.tween_property(_seta, "modulate:a", 1.0, 0.5)
