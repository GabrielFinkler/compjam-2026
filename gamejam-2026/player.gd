extends CharacterBody2D

# ==============================================================================
# JOGADOR - TOP-DOWN (ASTRONAUTA FUGINDO DO ALIEN)
# ==============================================================================

@export var velocidade: float = 120.0
@export var velocidade_corrida: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var lanterna: PointLight2D = $Lanterna
@onready var anim_timer: float = 0.0

func _physics_process(delta: float):
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	
	# Suporte adicional para teclas WASD
	if Input.is_key_pressed(KEY_A): dir.x = -1.0
	elif Input.is_key_pressed(KEY_D): dir.x = 1.0
	if Input.is_key_pressed(KEY_W): dir.y = -1.0
	elif Input.is_key_pressed(KEY_S): dir.y = 1.0
	
	dir = dir.normalized()
	
	var correndo = Input.is_key_pressed(KEY_SHIFT)
	var vel_atual = velocidade_corrida if correndo else velocidade
	
	velocity = dir * vel_atual
	move_and_slide()
	
	# Animação de caminhada nos frames do sprite
	if dir != Vector2.ZERO:
		anim_timer += delta * (10.0 if correndo else 6.0)
		if sprite.hframes > 1:
			sprite.frame = int(anim_timer) % sprite.hframes
		
		# Orientação do sprite
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
		
		# Lanterna acompanha a direção do movimento suavemente
		var angulo_alvo = dir.angle()
		lanterna.rotation = lerp_angle(lanterna.rotation, angulo_alvo, delta * 12.0)
	else:
		if sprite.hframes > 1:
			sprite.frame = 0
		# Lanterna também pode apontar para o mouse quando parado
		var mouse_pos = get_global_mouse_position()
		var dir_mouse = (mouse_pos - global_position).normalized()
		if dir_mouse.length_squared() > 0:
			lanterna.rotation = lerp_angle(lanterna.rotation, dir_mouse.angle(), delta * 8.0)
