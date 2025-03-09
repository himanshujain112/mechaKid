extends RigidBody2D

@onready var anim = $AnimatedSprite2D
var health = 20
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func take_damage():
	health -= 10
	anim.play("hit")
	await anim.animation_finished
	if health <= 0:
		anim.play("death")
		#$CollisionShape2D.disabled = true
		await anim.animation_finished
		anim.pause()