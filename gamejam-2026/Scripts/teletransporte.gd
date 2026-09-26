extends Area2D
## Teleporte: quando o jogador pisa, a tela brilha em ciano e o jogo vai pra cena destino.

@export_file("*.tscn") var destino: String = "res://Scenes/fim_fase1.tscn"

const TEMPO_FLASH := 0.4

var _usado: bool = false

func _ready() -> void:
	$AnimatedSprite2D.play("pulsar")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _usado or not body.is_in_group("jogador"):
		return
	_usado = true
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	var flash := ColorRect.new()
	flash.color = Color(0.6, 0.95, 1.0, 0.0)
	camada.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 1.0, TEMPO_FLASH)
	tween.tween_callback(func(): get_tree().change_scene_to_file(destino))
