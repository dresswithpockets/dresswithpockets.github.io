class_name Player extends CharacterBody3D

@export_group("Movement")
@export_subgroup("On Ground")
@export var ground_friction: float = 20.0
@export var ground_accel: float = 100.0
@export var ground_max_speed: float = 7.5
@export var max_step_height: float = 0.6
@export var max_step_up_slide_iterations: int = 4

@export_subgroup("In Air")
@export var gravity_up_scale: float = 1.0
@export var gravity_down_scale: float = 1.0
@export var air_friction: float = 10.0
@export var air_accel: float = 20.0
@export var air_max_speed: float = 7.5
@export var max_vertical_speed: float = 15.0

@onready var default_gravity: float = -ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera_yaw: Node3D = $CameraYaw
@onready var camera: Camera3D = $CameraYaw/Camera

# N.B. vertical_speed and horizontal_speed are only @export'd so that Node.duplicate()
# will duplicate their values, which is necessary for a playback history in the DemoRecorder
#
# These should not be exported normally.
@export var vertical_speed: float = 0
@export var horizontal_velocity: Vector3 = Vector3.ZERO

signal stepped(distance: float)

func _input(event: InputEvent) -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    
    if DemoRecorder.playback_state == DemoRecorder.PlaybackState.REPLAYING:
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        move_camera(event.relative)

func move_camera(relative_move: Vector2) -> void:
    var horizontal: float = relative_move.x * Settings.yaw_speed * Settings.mouse_speed
    var vertical: float = relative_move.y * Settings.pitch_speed * Settings.mouse_speed
    var yaw_rotation := deg_to_rad(-horizontal)
    var pitch_rotation := deg_to_rad(-vertical)
    camera_yaw.rotate_y(yaw_rotation)
    camera.rotate_x(pitch_rotation)

func _physics_process(delta: float) -> void:
    var wish_dir := Vector3.ZERO

    if DemoRecorder.playback_state == DemoRecorder.PlaybackState.REPLAYING:
        var next_state := DemoRecorder.get_next_state()
        if next_state == null:
            return
        
        wish_dir = next_state.wish_dir
    else:
        var input_dir := Vector2.ZERO
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            # get player's raw movement input as a 2d vector
            input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        
        # apply camera's yaw rotation onto the input vector
        wish_dir = camera_yaw.global_basis * Vector3(input_dir.x, 0, input_dir.y)
        DemoRecorder.push_state(wish_dir)

    # we have different movement properties depending on whether or not we're on floor.
    if is_on_floor():
        update_velocity_grounded(wish_dir, delta)
    else:
        update_velocity_air(wish_dir, delta)

    # we always apply gravity when we're not falling faster than terminal velocity
    apply_gravity(delta)
    
    # combine the horizontal and vertical components together & move
    var was_grounded := is_on_floor()
    stair_step_up(delta)
    
    velocity = horizontal_velocity
    move_and_slide()

    horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
    vertical_speed += velocity.y

    velocity = Vector3(0, vertical_speed, 0)
    move_and_slide()

    vertical_speed = velocity.y
    horizontal_velocity.x += velocity.x
    horizontal_velocity.z += velocity.z
    
    # velocity = Vector3(horizontal_velocity.x, vertical_speed, horizontal_velocity.z)
    # move_and_slide()
    stair_step_down(was_grounded)
    
    # get our new horizontal & vertical components after moving
    # horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
    # vertical_speed = velocity.y

func update_velocity_grounded(wish_dir: Vector3, delta: float) -> void:
    horizontal_velocity = Math.exp_decay_v3(
        horizontal_velocity,
        wish_dir * ground_max_speed,
        ground_friction,
        delta)

    horizontal_velocity += wish_dir * ground_accel * delta
    if horizontal_velocity.is_zero_approx():
        horizontal_velocity = Vector3.ZERO

    horizontal_velocity = horizontal_velocity.limit_length(ground_max_speed)
    print(horizontal_velocity.normalized().dot(wish_dir))

func update_velocity_air(wish_dir: Vector3, delta: float) -> void:
    horizontal_velocity = Math.exp_decay_v3(
        horizontal_velocity,
        wish_dir * air_max_speed,
        air_friction,
        delta)

    horizontal_velocity += wish_dir * air_accel * delta
    if horizontal_velocity.is_zero_approx():
        horizontal_velocity = Vector3.ZERO

    horizontal_velocity = horizontal_velocity.limit_length(air_max_speed)

func apply_gravity(delta: float) -> void:
    if vertical_speed > -max_vertical_speed:
        var gravity := default_gravity
        if vertical_speed > 0:
            gravity *= gravity_up_scale
        else:
            gravity *= gravity_down_scale

        vertical_speed += gravity * delta

        if vertical_speed < -max_vertical_speed:
            vertical_speed = -max_vertical_speed

func iterate_sweep(
    sweep_transform: Transform3D,
    motion: Vector3,
    params: PhysicsTestMotionParameters3D,
    result: PhysicsTestMotionResult3D
) -> Transform3D:
    for i in max_step_up_slide_iterations:
        params.from = sweep_transform
        params.motion = motion
        var hit := PhysicsServer3D.body_test_motion(get_rid(), params, result)
        sweep_transform = sweep_transform.translated(result.get_travel())
        if not hit:
            break

        var ceiling_normal := result.get_collision_normal()
        motion = motion.slide(ceiling_normal)
    
    return sweep_transform

func stair_step_up(delta: float) -> void:
    if !is_on_floor() or horizontal_velocity == Vector3.ZERO:
        return

    var sweep_transform := global_transform

    var result := PhysicsTestMotionResult3D.new()
    var params := PhysicsTestMotionParameters3D.new()
    params.margin = safe_margin

    # don't run through if theres nothing for us to step up onto
    params.from = sweep_transform
    params.motion = horizontal_velocity * delta
    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        return

    var horizontal_remainder := result.get_remainder()

    # sweep up
    sweep_transform = sweep_transform.translated(result.get_travel())
    var pre_sweep_y := sweep_transform.origin.y
    sweep_transform = iterate_sweep(sweep_transform, Vector3(0, max_step_height, 0), params, result)

    var height_travelled := sweep_transform.origin.y - pre_sweep_y
    if height_travelled <= 0:
        return

    # sweep forward using player's velocity
    sweep_transform = iterate_sweep(sweep_transform, horizontal_remainder, params, result)

    # sweep back down, at most the amount we travelled from the sweep up
    params.from = sweep_transform
    params.motion = Vector3(0, -height_travelled, 0)
    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        # don't bother if we don't hit anything
        return

    var floor_angle = result.get_collision_normal().angle_to(Vector3.UP)
    if absf(floor_angle) > floor_max_angle:
        return

    sweep_transform = sweep_transform.translated(result.get_travel())

    var distance := sweep_transform.origin.y - global_position.y
    global_position.y = sweep_transform.origin.y
    stepped.emit(distance)

func stair_step_down(was_grounded: bool) -> void:
    if !was_grounded or velocity.y >= 0 or is_on_floor():
        return

    var result := PhysicsTestMotionResult3D.new()
    var params := PhysicsTestMotionParameters3D.new()
    params.margin = safe_margin
    params.from = global_transform
    params.motion = Vector3(0, -max_step_height, 0)

    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        return

    var new_transform := global_transform.translated(result.get_travel())

    var previous_y := global_position.y
    global_transform = new_transform
    apply_floor_snap()
    
    var distance := global_position.y - previous_y
    stepped.emit(distance)
