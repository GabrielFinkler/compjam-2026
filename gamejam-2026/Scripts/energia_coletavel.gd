extends Area2D
## Energia coletável: ao encostar, a nave recarrega toda a energia.

func _ready() -> void:
	add_to_group("energia_coletavel")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("recarregar_energia"):
		body.recarregar_energia()
		queue_free()
