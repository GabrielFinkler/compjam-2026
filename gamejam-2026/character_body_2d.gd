extends CharacterBody2D

## Script de movimentação top-down do astronauta
## Configurado para resolução interna de 480x270 e tiles de 16x16 px.

const SPEED: float = 110.0
const ACCELERATION: float = 750.0
const FRICTION: float = 850.0

@onready var sprite: Sprite2D = $Sprite2D

# Controle de animação a ~8 FPS (conforme spec do projeto)
var anim_timer: float = 0.0
var anim_frame: int = 0
const ANIM_FPS: float = 8.0


func _physics_process(delta: float) -> void:
	var direction := get_movement_direction()

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		update_walk_animation(delta, direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		update_idle_animation()

	move_and_slide()


func get_movement_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	return dir.normalized()


func update_walk_animation(delta: float, direction: Vector2) -> void:
	if not sprite:
		return

	if direction.x < -0.1:
		sprite.flip_h = true
	elif direction.x > 0.1:
		sprite.flip_h = false

	anim_timer += delta
	if anim_timer >= (1.0 / ANIM_FPS):
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 2
		sprite.frame = 1 + anim_frame


func update_idle_animation() -> void:
	if not sprite:
		return
	anim_frame = 0
	anim_timer = 0.0
	sprite.frame = 0
