extends CharacterBody2D

@export var health: int = 100
var direction = 0
@onready var anim = $AnimatedSprite2D
@onready var speed: float = 180.0
var gravity: float = 980.0
@onready var jump_velocity: float = -300.0
var has_fired_bazooka = false
@onready var bullet_scene = preload("res://scenes/bullet/bullet.tscn")

@onready var leftAttackCollider = $attackArea/leftAttackCollider
@onready var rightAttackCollider = $attackArea/rightAttackCollider

# State Machine
enum State {IDLE, RUN, JUMP, FALL, BAZOOKA, ATTACK1, ATTACK2, COMBO, DEAD, DAMAGE}
var current_state = State.IDLE

# -----------------------------------

func _physics_process(delta: float) -> void:
    apply_gravity(delta)
    update_state()
    movement()
    death()
    move_and_slide()

func movement():
    direction = Input.get_axis("ui_left", "ui_right")

    if direction and current_state not in [State.BAZOOKA]:
        velocity.x = direction * speed
        anim.flip_h = direction < 0
        if is_on_floor():
            current_state = State.RUN
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        if is_on_floor() and current_state not in [State.BAZOOKA, State.ATTACK1, State.ATTACK2, State.COMBO, State.DEAD, State.DAMAGE]:
            current_state = State.IDLE

func death():
    if health <= 0:
        current_state = State.DEAD

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump") and is_on_floor() and current_state not in [State.JUMP, State.BAZOOKA, State.COMBO, State.DEAD]:
        current_state = State.JUMP
    elif event.is_action_pressed("bazooka") and is_on_floor():
        current_state = State.BAZOOKA
    elif event.is_action_pressed("attack1") and current_state not in [State.ATTACK1, State.ATTACK2, State.COMBO]:
        current_state = State.ATTACK1
    elif event.is_action_pressed("attack2") and current_state not in [State.ATTACK1, State.ATTACK2, State.COMBO]:
        current_state = State.ATTACK2
    elif event.is_action_pressed("combo") and is_on_floor():
        current_state = State.COMBO
    elif Input.is_key_pressed(KEY_TAB) and current_state not in [State.DAMAGE, State.DEAD]:
        current_state = State.DAMAGE

func update_state():
    match current_state:
        State.IDLE:
            anim.play("idle")
            reset_attack_state()
        State.RUN:
            anim.play("run")
        State.JUMP:
            anim.play("jump")
            velocity.y = jump_velocity
        State.FALL:
            anim.play("fall")
        State.BAZOOKA:
            anim.play("bazooka")
            handle_bazooka_shot()
        State.ATTACK1:
            anim.play("attack1")
            attack()
            await anim.animation_finished
            reset_attack_state()
        State.ATTACK2:
            anim.play("attack2")
            attack()
            await anim.animation_finished
            reset_attack_state()
        State.COMBO:
            anim.play("combo")
            attack()
            await anim.animation_finished
            reset_attack_state()
        State.DEAD:
            anim.play("death")
            if anim.frame == anim.sprite_frames.get_frame_count("death") - 1:
                anim.pause()
        State.DAMAGE:
            anim.play("hit")
            await anim.animation_finished
            current_state = State.IDLE

func handle_bazooka_shot():
    if current_state == State.BAZOOKA and anim.frame == 4 and not has_fired_bazooka:
        fire_bazooka()
        has_fired_bazooka = true
    if current_state == State.BAZOOKA and anim.frame == anim.sprite_frames.get_frame_count("bazooka") - 1:
        has_fired_bazooka = false
        current_state = State.IDLE

func fire_bazooka():
    var bullet_instance = bullet_scene.instantiate()
    if bullet_instance:
        get_tree().current_scene.add_child(bullet_instance)
        bullet_instance.direction = Vector2.RIGHT if not anim.flip_h else Vector2.LEFT
        bullet_instance.position = $bulletSpawnPos/leftMarker2D.global_position if anim.flip_h else $bulletSpawnPos/rightMarker2D.global_position

func apply_gravity(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
        if current_state not in [State.JUMP, State.BAZOOKA]:
            current_state = State.FALL

func attack():
    # Reset colliders first
    leftAttackCollider.disabled = true
    rightAttackCollider.disabled = true

    # Enable the correct attack collider based on direction
    if direction < 0 or anim.flip_h: # Facing left
        leftAttackCollider.disabled = false
    elif direction > 0 or not anim.flip_h: # Facing right
        rightAttackCollider.disabled = false

func reset_attack_state():
    leftAttackCollider.disabled = true
    rightAttackCollider.disabled = true
    current_state = State.IDLE

func _while_attacking_body_entered(body):
    if body.is_in_group("enemies"):
        print(body.name)
        body.take_damage()