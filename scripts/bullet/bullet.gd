extends Area2D

@export var speed: float = 600.0 # Bullet speed
var direction: Vector2 = Vector2.RIGHT # Default direction

@onready var onScreen = $VisibleOnScreenNotifier2D
@onready var anim = $Sprite2D # If using an AnimatedSprite2D, change this accordingly

func _ready():
    # Ensure the bullet faces the correct direction
    if direction.x < 0:
        scale.x = -1 # Flip the sprite if moving left

func _physics_process(delta: float) -> void:
    position += direction * speed * delta

func _on_VisibleOnScreenNotifier2D_screen_exited():
    print("Bullet exited the screen")
    queue_free() # Remove bullet when off-screen

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies"):
        anim.play("destroy")
        speed = 0 # Play destruction animation
        await anim.animation_finished # Wait for animation to finish
        queue_free()
