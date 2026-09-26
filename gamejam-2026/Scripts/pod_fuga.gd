extends Area2D
## Pod de emergência: o fim do jogo. Quando o jogador encosta, ele embarca, o pod fecha,
## treme ligando os motores e dispara pra cima (saindo pela porta da nave). A tela escurece
## e o jogo vai pra cena "destino" (tela de fim de jogo).
## Desenhado por código, no estilo pixel do resto do jogo: não precisa de sprite.

@export_file("*.tscn") var destino: String = "res://Scenes/fim_jogo.tscn"
@export var mensagem: String = "EMBARCANDO NO POD DE EMERGÊNCIA!"
@export var distancia_decolagem: float = 220.0 ## Quanto o pod sobe antes da tela escurecer (px)

const Aviso := preload("res://Scripts/aviso.gd")
const COR_CASCO := Color(0.58, 0.61, 0.66)
const COR_CASCO_ESCURO := Color(0.25, 0.27, 0.32)
const COR_FAIXA := Color(1.0, 0.6, 0.15)
const COR_VIDRO := Color(0.3, 0.8, 1.0)
const COR_VIDRO_OCUPADO := Color(0.23, 1.0, 0.43)
const COR_ALERTA := Color(1.0, 0.25, 0.15)
const COR_CHAMA := Color(1.0, 0.55, 0.1)
const COR_CHAMA_MIOLO := Color(1.0, 0.95, 0.6)
const TEMPO_TREMER := 0.9
const TEMPO_DECOLAR := 1.6
const TEMPO_CORTE := 0.6

var _embarcou: bool = false
var _motor: float = 0.0 # 0 = desligado, 1 = força total (tamanho da chama)
var _tempo: float = 0.0
var _origem: Vector2
var _luzes: Node2D # Vidro, luzes de alerta e chamas: brilham sozinhos, sem depender de luz
var _brilho: PointLight2D
var _luz_chama: PointLight2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_luzes = Node2D.new()
	var sem_sombra := CanvasItemMaterial.new()
	sem_sombra.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_luzes.material = sem_sombra
	_luzes.draw.connect(_desenhar_luzes)
	add_child(_luzes)
	# Brilho laranja pulsando: dá pra achar o pod no escuro, como os LEDs dos terminais
	_brilho = _criar_luz(COR_FAIXA, 1.0, Vector2(0, -4))
	_luz_chama = _criar_luz(COR_CHAMA, 0.8, Vector2(0, 16))
	_luz_chama.energy = 0.0

func _process(delta: float) -> void:
	_tempo += delta
	if not _embarcou:
		_brilho.energy = 0.6 + 0.5 * (0.5 + 0.5 * sin(_tempo * 5.0))
	_luz_chama.energy = _motor * randf_range(1.2, 1.8)
	queue_redraw()
	_luzes.queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _embarcou or not body.is_in_group("jogador"):
		return
	_embarcou = true
	body.embarcar()
	_brilho.color = COR_VIDRO_OCUPADO
	_brilho.energy = 1.0
	Aviso.mostrar(get_tree().current_scene, mensagem, COR_VIDRO_OCUPADO, 3.0)

	_origem = position
	var tween := create_tween()
	tween.tween_method(_tremer, 0.0, 1.0, TEMPO_TREMER)
	tween.tween_callback(func(): position = _origem)
	tween.tween_property(self, "_motor", 1.0, 0.25)
	tween.parallel().tween_property(self, "position:y", _origem.y - distancia_decolagem, TEMPO_DECOLAR) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# A tela começa a escurecer antes do fim da subida, pra não ficar um vazio parado
	tween.parallel().tween_callback(_cortar_para_fim).set_delay(TEMPO_DECOLAR - TEMPO_CORTE)

# Motores esquentando: o pod treme cada vez mais e a chama vai crescendo
func _tremer(t: float) -> void:
	_motor = t * 0.4
	var forca := ceilf(t * 2.0)
	position = _origem + Vector2(randi_range(-1, 1), randi_range(-1, 1)) * forca

# Mesmo corte pro preto da saída de fase (saida_fase.gd): fica na raiz e clareia na cena nova
func _cortar_para_fim() -> void:
	var arvore := get_tree()
	var corte := CanvasLayer.new()
	corte.layer = 100
	corte.process_mode = Node.PROCESS_MODE_ALWAYS
	arvore.root.add_child(corte)
	var tela := ColorRect.new()
	tela.color = Color(0, 0, 0, 0)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corte.add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cena_destino := destino
	var tween := corte.create_tween()
	tween.tween_property(tela, "color:a", 1.0, TEMPO_CORTE)
	tween.tween_callback(func(): arvore.change_scene_to_file(cena_destino))
	tween.tween_interval(0.3)
	tween.tween_property(tela, "color:a", 0.0, TEMPO_CORTE)
	tween.tween_callback(corte.queue_free)

# Casco visto de cima: cápsula cinza com faixa laranja e dois motores atrás
func _draw() -> void:
	draw_rect(Rect2(-9, 5, 6, 6), COR_CASCO_ESCURO)
	draw_rect(Rect2(3, 5, 6, 6), COR_CASCO_ESCURO)
	draw_circle(Vector2(0, -4), 12.0, COR_CASCO_ESCURO)
	draw_rect(Rect2(-12, -4, 24, 11), COR_CASCO_ESCURO)
	draw_circle(Vector2(0, -4), 11.0, COR_CASCO)
	draw_rect(Rect2(-11, -4, 22, 10), COR_CASCO)
	draw_rect(Rect2(-11, 2, 22, 2), COR_FAIXA)
	draw_circle(Vector2(0, -7), 5.0, COR_CASCO_ESCURO)

func _desenhar_luzes() -> void:
	# Chamas dos motores, tremulando
	if _motor > 0.0:
		for lado in [-6.0, 6.0]:
			var comprimento := (5.0 + 12.0 * _motor) * randf_range(0.8, 1.2)
			_luzes.draw_colored_polygon(PackedVector2Array([
				Vector2(lado - 3.0, 11), Vector2(lado + 3.0, 11), Vector2(lado, 11 + comprimento)]), COR_CHAMA)
			_luzes.draw_colored_polygon(PackedVector2Array([
				Vector2(lado - 1.5, 11), Vector2(lado + 1.5, 11), Vector2(lado, 11 + comprimento * 0.6)]), COR_CHAMA_MIOLO)
	# Vidro da cabine: azul vazio, verde com o jogador dentro
	_luzes.draw_circle(Vector2(0, -7), 4.0, COR_VIDRO_OCUPADO if _embarcou else COR_VIDRO)
	_luzes.draw_rect(Rect2(-2, -10, 2, 1), Color(1, 1, 1, 0.8))
	# Luzes de alerta nas laterais, piscando alternadas
	var aceso := fmod(_tempo, 0.8) < 0.4
	_luzes.draw_rect(Rect2(-13, -1, 2, 2), COR_ALERTA if aceso else COR_ALERTA.darkened(0.7))
	_luzes.draw_rect(Rect2(11, -1, 2, 2), COR_ALERTA.darkened(0.7) if aceso else COR_ALERTA)

func _criar_luz(cor: Color, escala: float, posicao: Vector2) -> PointLight2D:
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
	var luz := PointLight2D.new()
	luz.texture = textura
	luz.texture_scale = escala
	luz.color = cor
	luz.position = posicao
	add_child(luz)
	return luz
