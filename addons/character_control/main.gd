@tool
extends CharacterBody3D

@export_group("Character Control")
@export_subgroup("Player")
var player: CharacterBody3D
var is_player_fps: bool = false
@export_range(0, 1000) var player_move_speed: float = 300.0
@export_range(1, 10, 1, "or_greater") var player_collision_layer: int = 2:
	get:
		return player_collision_layer
	set(value):
		player_collision_layer = value
		if is_instance_valid(player):
			player.collision_layer = player_collision_layer

@export_subgroup("Srping")
var spring: SpringArm3D = SpringArm3D.new()
var spring_shape: SphereShape3D = SphereShape3D.new()
@export_range(0, 100) var spring_length: float = 3:
	get:
		return spring_length
	set(value):
		spring_length = value
		if is_instance_valid(spring):
			spring.spring_length = spring_length
@export_range(1, 10) var spring_collision_mask: int = 1:
	get:
		return spring_collision_mask
	set(value):
		spring_collision_mask = value
		if is_instance_valid(spring):
			spring.collision_mask = spring_collision_mask
@export var spring_position: Vector3 = Vector3(0, 2, 0):
	get:
		return spring_position
	set(value):
		spring_position = value
		if is_instance_valid(spring):
			spring.position = value
@export_range(0, 1000) var spring_rotation_h_sensitivity: float = 100:
	get:
		return spring_rotation_h_sensitivity
	set(value):
		spring_rotation_h_sensitivity = value
@export_range(0, 1000) var spring_rotation_v_sensitivity: float = 100:
	get:
		return spring_rotation_v_sensitivity
	set(value):
		spring_rotation_v_sensitivity = value
@export_range(-100, 100) var spring_min_rotation_v: int = -45:
	get:
		return spring_min_rotation_v
	set(value):
		spring_min_rotation_v = value
@export_range(-100, 100) var spring_max_rotation_v: int = 7:
	get:
		return spring_max_rotation_v
	set(value):
		spring_max_rotation_v = value
@export_range(0, 10, 0.1, "or_greater") var spring_shape_radius: float = 0.1:
	get:
		return spring_shape_radius
	set(value):
		spring_shape_radius = value
		if is_instance_valid(spring_shape):
			spring_shape.radius = value
@export var spring_offset_position: Vector3 = Vector3(0, 0.8, 0):
	get:
		return spring_offset_position
	set(value):
		spring_offset_position = value

@export_subgroup("Camera")
var camera: Camera3D = Camera3D.new()
@export_range(0, 100) var camera_fov: float = 75:
	get:
		return camera_fov
	set(value):
		camera_fov = value
		if is_instance_valid(camera):
			camera.fov = camera_fov

@export_subgroup("Joystick")
@export_range(0, 100) var joystick_axis: int = 0
@export_range(0, 100) var left_stick_horizontal: int = 0
@export_range(0, 100) var left_stick_vertical: int = 1
@export_range(0, 1) var left_stick_deadzone: float = 0.15
@export_range(0, 100) var right_stick_horizontal: int = 2
@export_range(0, 100) var right_stick_vertical: int = 3
@export_range(0, 1) var right_stick_deadzone: float = 0.15

@export_subgroup("Buttons")
@export_range(0, 100) var button_a_id: int = 0
@export_range(0, 100) var button_b_id: int = 1
@export_range(0, 100) var button_c_id: int = 2
@export_range(0, 100) var button_d_id: int = 3
@export_range(0, 100) var button_r_id: int = 10
@export_range(0, 100) var button_l_id: int = 9

var left_stick: Vector2 = Vector2.ZERO
var left_stick_distance: float = 0.0
var left_stick_angle: float = 0.0
var left_stick_angle_clockwise: float = 0.0
var left_stick_angle_not_clockwise: float = 0.0

var right_stick: Vector2 = Vector2.ZERO
var right_stick_distance: float = 0.0
var right_stick_angle: float = 0.0
var right_stick_angle_clockwise: float = 0.0
var right_stick_angle_not_clockwise: float = 0.0

var button_a: bool = false
var button_b: bool = false
var button_c: bool = false
var button_d: bool = false
var button_r: bool = false
var button_l: bool = false

func _ready() -> void:
	if Engine.is_editor_hint() and not get_node_or_null("CollisionShape3D"):
		var col = CollisionShape3D.new()
		col.shape = null
		add_child(col)

	if get_parent() is CharacterBody3D:
		player = get_parent()
		player.velocity = Vector3.ZERO
		spring.position = spring_position + spring_offset_position + player.position
		spring.spring_length = spring_length
		spring.collision_mask = spring_collision_mask
		spring_shape.radius = spring_shape_radius
		spring.shape = spring_shape
		camera.fov = camera_fov
		spring.add_child(camera)
		get_tree().root.get_child(0).add_child.call_deferred(spring)
		player.collision_layer = player_collision_layer
	else:
		push_warning("CharacterControl: O nó pai não é um CharacterBody3D. Considere adicionar CharacterControl dentro de um CharacterBody3D como filho.")

	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if get_parent() is CharacterBody3D:
		get_joystick()
		get_buttons()
	pass

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if get_parent() is CharacterBody3D:
		player_gravity(delta)
		player_jump(delta)
		player_move(delta)
		spring_follow(delta)
		spring_rotation(delta)
	pass

func get_joystick() -> void:
	left_stick = Vector2(Input.get_joy_axis(joystick_axis, left_stick_horizontal), Input.get_joy_axis(joystick_axis, left_stick_vertical))
	if left_stick.x <= left_stick_deadzone and left_stick.x >= -left_stick_deadzone:
		left_stick.x = 0
	if left_stick.y <= left_stick_deadzone and left_stick.y >= -left_stick_deadzone:
		left_stick.y = 0
	left_stick_distance = min(left_stick.length(), 1.0)

	left_stick_angle = rad_to_deg(atan2(left_stick.y, left_stick.x))
	left_stick_angle_clockwise = rad_to_deg(atan2(-left_stick.y, left_stick.x))
	left_stick_angle_not_clockwise = left_stick_angle

	if left_stick_angle_clockwise < 0:
		left_stick_angle_clockwise += 360

	if left_stick_angle_not_clockwise < 0:
		left_stick_angle_not_clockwise += 360

	right_stick = Vector2(Input.get_joy_axis(joystick_axis, right_stick_horizontal), Input.get_joy_axis(joystick_axis, right_stick_vertical))
	if right_stick.x <= right_stick_deadzone and right_stick.x >= -right_stick_deadzone:
		right_stick.x = 0
	if right_stick.y <= right_stick_deadzone and right_stick.y >= -right_stick_deadzone:
		right_stick.y = 0
	right_stick_distance = min(right_stick.length(), 1.0)

	right_stick_angle = rad_to_deg(atan2(right_stick.y, right_stick.x))
	right_stick_angle_clockwise = rad_to_deg(atan2(-right_stick.y, right_stick.x))
	right_stick_angle_not_clockwise = right_stick_angle

	if right_stick_angle_clockwise < 0:
		right_stick_angle_clockwise += 360

	if right_stick_angle_not_clockwise < 0:
		right_stick_angle_not_clockwise += 360
	pass

func get_buttons() -> void:
	button_a = Input.is_joy_button_pressed(joystick_axis, button_a_id)
	button_b = Input.is_joy_button_pressed(joystick_axis, button_b_id)
	button_c = Input.is_joy_button_pressed(joystick_axis, button_c_id)
	button_d = Input.is_joy_button_pressed(joystick_axis, button_d_id)
	button_r = Input.is_joy_button_pressed(joystick_axis, button_r_id)
	button_l = Input.is_joy_button_pressed(joystick_axis, button_l_id)
	pass

func player_move(delta: float) -> void:
	if button_l:
		is_player_fps = true
	else:
		is_player_fps = false

	if is_player_fps:
		spring.spring_length = 0
		player.visible = false
	else:
		spring.spring_length = spring_length
		player.visible = true

	var camera_transform = spring.transform
	var camera_forward = camera_transform.basis.z.normalized()
	var camera_right = camera_transform.basis.x.normalized()
	var move_direction: Vector3 = (camera_forward * left_stick.y) + (camera_right * left_stick.x)

	if left_stick_distance > 0:
		move_direction = move_direction.normalized()
		move_direction.y = 0

		var target_rotation = player.global_transform.basis.get_rotation_quaternion()
		var desired_direction = Vector3(player.global_transform.origin + move_direction)
		var look_at_rotation = player.global_transform.looking_at(desired_direction, Vector3.UP).basis.get_rotation_quaternion()

		target_rotation = target_rotation.slerp(look_at_rotation, delta * 20)
		player.global_transform.basis = Basis(target_rotation)

	player.velocity.x = move_direction.x * player_move_speed * left_stick_distance * delta
	player.velocity.z = move_direction.z * player_move_speed * left_stick_distance * delta

	player.move_and_slide()
	pass

func spring_rotation(delta: float) -> void:
	if right_stick.x != 0:
		if is_player_fps:
			spring.rotation.y = lerp(spring.rotation.y, spring.rotation.y + deg_to_rad(-right_stick.x * spring_rotation_h_sensitivity), delta * 2)
		else:
			spring.rotation.y = lerp(spring.rotation.y, spring.rotation.y + deg_to_rad(right_stick.x * spring_rotation_h_sensitivity), delta * 2)

	if right_stick.y != 0:
		if is_player_fps:
			spring.rotation.x = lerp(spring.rotation.x, spring.rotation.x + deg_to_rad(-right_stick.y * spring_rotation_v_sensitivity), delta * 2)
		else:
			spring.rotation.x = lerp(spring.rotation.x, spring.rotation.x + deg_to_rad(right_stick.y * spring_rotation_v_sensitivity), delta * 2)

		if spring.rotation.x <= deg_to_rad(spring_min_rotation_v):
			spring.rotation.x = deg_to_rad(spring_min_rotation_v)
		if spring.rotation.x >= deg_to_rad(spring_max_rotation_v):
			spring.rotation.x = deg_to_rad(spring_max_rotation_v)
	pass

func spring_follow(delta) -> void:
	if not is_player_fps:
		if not button_r:
			spring.position = spring.position.lerp(player.position + spring_offset_position, delta * 8)
	else:
		spring.position = player.position + spring_offset_position

	pass

func player_jump(delta) -> void:
	if button_a and player.is_on_floor():
		player.velocity.y = 5

func player_gravity(delta) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
