extends CharacterBody2D

## Script do Monstro na Sala da Esquerda
## Possui animação de respiração/pulsação e patrulha suave na sala.

const SPEED: float = 35.0

@onready var sprite: Sprite2D = $Sprite2D

var anim_timer: float = 0.0
var anim_frame: int = 0
const ANIM_FPS: float = 4.0

var patrol_timer: float = 0.0
var patrol_dir: Vector2 = Vector2.RIGHT
var origin_pos: Vector2


func _ready() -> void:
	origin_pos = global_position


func _physics_process(delta: float) -> void:
	# Animação de respiração/tentáculos
	anim_timer += delta
	if anim_timer >= (1.0 / ANIM_FPS):
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 3
		if sprite:
			sprite.frame = anim_frame

	# Movimento suave de patrulha ao redor de sua área
	patrol_timer += delta
	if patrol_timer > 3.0:
		patrol_timer = 0.0
		# Alterna direção
		patrol_dir = patrol_dir.rotated(PI * 0.5)

	velocity = patrol_dir * SPEED
	move_and_slide()

	# Mantém próximo da origem da sala
	if global_position.distance_to(origin_pos) > 100.0:
		patrol_dir = (origin_pos - global_position).normalized()
