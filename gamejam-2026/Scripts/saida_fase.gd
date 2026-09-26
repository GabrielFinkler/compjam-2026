extends Area2D
## Saída da fase: porta dupla que abre sozinha quando o jogador chega perto. Ao atravessá-la,
## a tela corta pro preto e o jogo segue para a cena "destino" (próxima fase ou tela final).
## O jogador entra pela frente (lado +Y, "de baixo"); gire o nó para usar em outra parede.

@export_file("*.tscn") var destino: String = ""
@export var tempo_corte: float = 0.4 ## Segundos escurecendo (e depois clareando na fase nova)

@onready var _portas: Array[Node] = [$PortaEsquerda, $PortaDireita]

var _usada: bool = false


func _ready() -> void:
	$Sensor.body_entered.connect(_on_sensor_body_entered)
	body_entered.connect(_on_body_entered)


func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		for porta in _portas:
			porta.abrir()


func _on_body_entered(body: Node2D) -> void:
	if _usada or destino == "" or not body.is_in_group("jogador"):
		return
	_usada = true
	body.controle_bloqueado = true
	# O corte fica na raiz da árvore: sobrevive à troca de cena e clareia já na fase nova
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
	tween.tween_property(tela, "color:a", 1.0, tempo_corte)
	tween.tween_callback(func(): arvore.change_scene_to_file(cena_destino))
	tween.tween_interval(0.3)
	tween.tween_property(tela, "color:a", 0.0, tempo_corte)
	tween.tween_callback(corte.queue_free)
