---
layout: post
title:  "Stepping Up & Down Stairs in Godot 4"
date:   2025-03-19 5:00:00 -0700
tags:   godot gamedev
---

For this guide, I've configured:
- Jolt Physics
- 60 physics ticks per second
- `CharacterBody3D.safe_margin = 0.001`
- `CharacterBody3D.constant_speed = true`
- `CharacterBody3D`'s `CollisionShape3D.shape.margin = 0.001`

And, the following script attached:

```gdscript
class_name Player extends CharacterBody3D

# ...

func _physics_process(delta: float) -> void:
    # get player's raw movement input as a 2d vector
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    
    # apply camera's yaw rotation onto the input vector
    var wish_dir := camera_yaw.global_basis * Vector3(input_dir.x, 0, input_dir.y)
    
    # we have different movement properties depending on whether or not we're on floor.
    if is_on_floor():
        update_velocity_grounded(wish_dir, delta)
    else:
        update_velocity_air(wish_dir, delta)
    
    # we always apply gravity when we're not falling faster than terminal velocity
    apply_gravity(delta)
    
    # combine the horizontal and vertical components together & move
    velocity = Vector3(horizontal_velocity.x, vertical_speed, horizontal_velocity.z)
    move_and_slide()
    
    # get our new horizontal & vertical components after moving
    horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
    vertical_speed = velocity.y

# ...
```

It works great! Its not too floaty, and not too snappy. It handles things like speed acceleration and exponential decay like friction, max speed clamping, terminal falling speed, gravity, etc. But...

## I can't climb stairs!

![clip brush slope](/assets/images/godot-stair-stepping/cant-climb-stairs.gif)

Climbing stairs is a surprisingly unintuitive problem. Theres one obvious solution we could try, which is to add an invisible collision mesh with an angle lower than our controller's max slope angle:

![clip brush slope](/assets/images/godot-stair-stepping/clip-brush-slope.png)

This works pretty well, actually! My character controller is able to move up and down this without any changes:

![clip brush slope](/assets/images/godot-stair-stepping/clip-brush-slope.gif)

I'm not satisfied, though; After thinking about it, there are some problems:

- I have to add "stair clipping" to every walkable staircase & ledge in my game.
- Anytime I want to change the visual geometry of some walkable staircases or ledges, I also have to update the stair clipping to match.
- The potential shape of the geometry is super limited. Spiral staircases are effectively impossible to make totally smooth, for example.
- Now there is an invisible "on ramp" in front of the initial step up to any staircase or walkable ledge.
    - This will block the player from the sides - could be solved by adding more clipping on the sides, but thats even more clipping work!

I've played plenty of games that don't use stair clipping at all but have really smooth stair stepping - like Selaco, Ion Fury, and Quake 3. I want the boon of a robust character controller that can walk up and down any appropriate geometry with satisfying smoothing.

## Enter: `body_test_motion`

Godot's `PhsyicsServer3D` has a function, [`body_test_motion`](https://docs.godotengine.org/en/4.4/classes/class_physicsserver3d.html#class-physicsserver3d-method-body-test-motion), which tests if a particular motion applied to a `PhysicsBody3D` will hit anything. The test gives us back some useful information in the result, like how far the test travelled before hitting anything, and the normal of the surface the test hit.

So, we could do a test motion downward, with its origin at `global_position + (velocity * delta) + Vector3(0, max_step_height, 0)`, with a downard motion thats `max_step_height` in length:

```
                        body_test_motion     
                           ┌──────┐           
                           │      │           
                           │      │           
 player                    │      │           
┌──────┐                   │      │           
│      │  player velocity  │      │           
│      ├─────────────────► │      │           
│      │                   └──┬───┘           
│      │                      │               
│      │                      │max step height
│      │                      │               
└──────┘                      ▼               
```

So we can write a function that does that test for us:

```gdscript
func stair_step_up(delta: float) -> void:
    var params := PhysicsTestMotionParameters3D.new()
    params.margin = safe_margin
    params.from = global_transform.translated(horizontal_velocity * delta + Vector3(0, max_step_height, 0))
    params.motion = Vector3(0, -max_step_height, 0)

    var result := PhysicsTestMotionResult3D.new()
    var hit_something := PhysicsServer3D.body_test_motion(get_rid(), params, result)
    if hit_something:
        global_position.y = params.from.translated(result.get_travel()).origin.y
```

And call it before we call `move_and_slide()`:

```gdscript
func _physics_process(delta: float) -> void:
    # ...
    stair_step_up(delta)

    # combine the horizontal and vertical components together & move
    velocity = Vector3(horizontal_velocity.x, vertical_speed, horizontal_velocity.z)
    move_and_slide()
    # ...
```

And give it a try, without any extra stair clipping:

![clip brush slope](/assets/images/godot-stair-stepping/stair-stepping-1.gif)

It works!!! Though, its not particularly smooth. I'll get to smoothing out the vertical motion later in this post.

It's not too hard to come up with some obvious problems to this approach though, it:

- can't step _down_ onto a step,
- ignores some ceilings you'd expect to block the player,
- ignores walls the player might bump into and slide against during `move_and_slide`

## Less Naive Test

We can account for ceilings & walls with a relatively trivial change to our naive stair step procedure, by testing up, and forward, before testing down. If we hit anything during the upwards or forwards test, we adjust our next test's origin to account for the collision.

```
┌──────┐                 ┌──────┐
│      │                 │      │
│      │ player velocity │      │
│sweep ├────────────────►│sweep │
│right │                 │down  │
│      │                 │      │
│      │                 │      │
└──────┘                 └───┬──┘
    ▲                        │   
    │max step height         │   
┌───┴──┐                     │   
│      │                     │   
│      │                     │   
│sweep │       step remainder│   
│up    │                     │   
│      │                     │   
│      │                     │   
└──────┘                     ▼   
 player                 destination
```

And the updated procedure:

```gdscript
func stair_step_up(delta: float) -> void:
    var sweep_transform := global_transform

    var result := PhysicsTestMotionResult3D.new()
    var params := PhysicsTestMotionParameters3D.new()
    params.margin = safe_margin
    
    # sweep up
    params.from = sweep_transform
    params.motion = Vector3(0, max_step_height, 0)
    PhysicsServer3D.body_test_motion(get_rid(), params, result)
    
    # sweep forward using player's velocity
    var height_travelled = result.get_travel().y
    sweep_transform = sweep_transform.translated(result.get_travel())
    params.from = sweep_transform
    params.motion = horizontal_velocity * delta
    PhysicsServer3D.body_test_motion(get_rid(), params, result)
    
    # sweep back down, at most the amount we travelled from the sweep up
    sweep_transform = sweep_transform.translated(result.get_travel())
    params.from = sweep_transform
    params.motion = Vector3(0, -height_travelled, 0)
    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        # don't bother if we don't hit anything
        return

    sweep_transform = sweep_transform.translated(result.get_travel())
    global_position.y = sweep_transform.origin.y
```

And that works... but there is certainly some unexpected behaviour that happens occasionally when going up each step:

![clip brush slope](/assets/images/godot-stair-stepping/stair-stepping-2.gif)

### Mis-steps

I'm making some assumptions about why this happens:
- Jolt uses an SAT-derived solver
- Jolt evaluates the vertical axis before either of the horizontal axes in the motion are tested

I believe this happens because `stair_step_up` _only_ moves the player vertically. It could be possible that the vertical velocity due to gravity causes the player to fall too fast for Jolt to determine that the player is "on" the next step.

So, I'll try to solve the problem given these assumptions. Lets force the body to only move the horizontal component first, then handle vertical after:

```gdscript
func _physics_process(delta: float) -> void:
    # ...
    stair_step_up(delta)
    
    # horizontal-only move
    velocity = horizontal_velocity
    move_and_slide()

    horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

    # the horizontal motion may have induced some vertical motion after a slide iteration
    vertical_speed += velocity.y

    # vertical-only move
    velocity = Vector3(0, vertical_speed, 0)
    move_and_slide()
    
    # the vertical motion may have induced some horizontal motion after a slide iteration
    vertical_speed = velocity.y
    horizontal_velocity.x += velocity.x
    horizontal_velocity.z += velocity.z
```

Lets see how that feels:

![fixed missteps](/assets/images/godot-stair-stepping/fixed-missteps.gif)

Not bad. Its not a perfect solution since I effectively doubled the number of slide iterations I'm doing each frame - but spending time solving for a more performant solution would be time spent prematurely on an optimization I may not even need.

Good enough is better than good.

### Small Gains

We can make some small improvements to the stair step procedure. For starters, we shouldn't be trying to step up if the player isn't grounded, or if their velocity is zero:

```gdscript
func stair_step_up(delta: float) -> void:
    if !is_on_floor() or horizontal_velocity == Vector3.ZERO:
        return

    # ...
```

We shouldn't be running the entire sweep if theres not ledge we could potentially step up onto in the first place:

```gdscript
    # ...

    # don't run through if theres nothing for us to step up onto
    params.from = sweep_transform
    params.motion = horizontal_velocity * delta
    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        return

    # capture whatever remainder was left over from the horizontal move
    # to be used in the forward sweep
    var horizontal_remainder := result.get_remainder()

    # sweep up, from the wall we hit
    sweep_transform = sweep_transform.translated(result.get_travel())
    params.from = sweep_transform
    params.motion = Vector3(0, max_step_height, 0)
    PhysicsServer3D.body_test_motion(get_rid(), params, result)
    
    # sweep forward using player's velocity
    var height_travelled := result.get_travel().y
    sweep_transform = sweep_transform.translated(result.get_travel())
    params.from = sweep_transform
    params.motion = horizontal_remainder
    PhysicsServer3D.body_test_motion(get_rid(), params, result)

    # ...
```

We shouldn't try stepping down if the height traveled by the up-sweep is too small:

```gdscript
    # ...
    # sweep up, from the wall we hit
    sweep_transform = sweep_transform.translated(result.get_travel())
    params.from = sweep_transform
    params.motion = Vector3(0, max_step_height, 0)
    PhysicsServer3D.body_test_motion(get_rid(), params, result)

    var height_travelled := result.get_travel().y
    if height_travelled <= 0:
        return
    
    # ...
```

We shouldn't try stepping onto a surface thats too steep for us to walk onto anyways:

```gdscript
    # after sweeping down, skip if the hit surface is too steep
    var floor_angle = result.get_collision_normal().angle_to(Vector3.UP)
    if absf(floor_angle) > floor_max_angle:
        return
```

## Stepping down

Stepping down is pretty similar to what we've done so far, except we only need to test straight beneath the player:

```
 player                          
┌──────┐                         
│      │                         
│      │                         
│sweep │                         
│down  │                         
│      │                         
│      │                         
└───┬──┘                         
    │                            
    │max step height             
    │                            
    ▼                            
```

So, lets just do that:

```gdscript
func stair_step_down() -> void:
    var result := PhysicsTestMotionResult3D.new()
    var params := PhysicsTestMotionParameters3D.new()
    params.margin = safe_margin
    params.from = global_transform
    params.motion = Vector3(0, -max_step_height, 0)

    if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
        return

    var new_transform := global_transform.translated(result.get_travel())
    global_transform = new_transform
```

And call it in `_physics_process` after `move_and_slide()`:

```gdscript
func _physics_process(delta: float) -> void:
    # ...
    stair_step_up(delta)

    # horizontal-only move
    velocity = horizontal_velocity
    move_and_slide()
    # ...

    stair_step_down()
    # ...
```

We call `stair_step_down()` after `move_and_slide()`; if we don't, the player could be in the air until next physics frame, even though they should step down.

### Small Gains

Just like the step-up procedure, there are some scenarios where we don't need to test downward at all:

- If the player wasn't grounded before `move_and_slide()`,
- If the player is currently grounded,
- If the player has a positive vertical speed (theyre going up!)

```gdscript
func _physics_process(delta: float) -> void:
    # ...
    var was_grounded := is_on_floor()
    stair_step_up(delta)

    # horizontal-only move
    velocity = horizontal_velocity
    move_and_slide()
    # ...

    stair_step_down(was_grounded)
    # ...

func stair_step_down(was_grounded: bool) -> void:
    if !was_grounded or velocity.y >= 0 or is_on_floor():
        return
    # ...
```

We can also avoid a situation where we're not snapped to the ground by calling `apply_floor_snap()` after moving the player:

```gdscript
func stair_step_down(was_grounded: bool) -> void:
    # ...
    global_transform = new_transform
    apply_floor_snap()
```

## Camera Smoothing

To make stepping up & down less stuttery, we can smooth the position of the camera whenever the player steps up or down. Lets add a couple signals indicating whenever we step up or down:

```gdscript
signal stepped(vertical_travel: float)
```

We pass in the absolute vertical distance travelled whenever we step up or down:

```gdscript
func stair_step_up(delta: float) -> void:
    # ...

    var distance := sweep_transform.origin.y - global_position.y
    global_position.y = sweep_transform.origin.y
    stepped.emit(distance)

func stair_step_down(was_grounded: bool) -> void:
    # ...

    var previous_y := global_position.y
    global_transform = new_transform
    apply_floor_snap()
    
    var distance := global_position.y - previous_y
    stepped.emit(distance)
```

We can connect this signal to a function in the script attached to the camera, which offsets the camera's local position by the height travelled, and smooths the camera's local position back to 0:

```gdscript
extends Camera3D

func _on_player_stepped(distance: float) -> void:
    position.y -= distance

func _process(delta: float) -> void:
    position.y = Math.exp_decay_f(position.y, 0, 20, delta)
```

And, `Math.exp_decay_f` is [Freya Holmer](https://www.acegikmo.com/)'s [frame-rate-independent smoothing function](https://substack.com/home/post/p-145129242):

```gdscript
static func exp_decay_f(a: float, b: float, decay: float, delta: float) -> float:
    return b + (a - b) * exp(-decay * delta)
```

![clip brush slope](/assets/images/godot-stair-stepping/stair-stepping-3.gif)

Wow. That is really nice. Its not perfectly interpolating between each step, but I personally really like that it doesn't do that. This feels like theres weight to each step, and the code itself is really simple and satisfying.

## Iterating Sweeps

Theres one more thing we can do to improve the accuracy of our step-up procedure, and to decrease it's jankiness in some rare situations: iterating & sliding.

Instead of just stopping whenever we detect a collision during one of our initial sweeps, we could "iterate" the sweep a few times by "sliding" the motion against the collision's normal. I have a little function that does all this for me:

```gdscript
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
```

Then we replace our up- and forward- sweep tests with calls to `iterate_sweep`:
```gdscript
func stair_step_up(delta: float) -> void:
    # ...
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
    # ...
```

With that we get some better accuracy around walls & low slanted ceilings:

![clip brush slope](/assets/images/godot-stair-stepping/wall-sliding.gif)

## Slopes

We actually don't need to make any special considerations for this code to work on slopes! This implementation is sufficiently generalized that it should work on most reasonable geometry!

![slope walking](/assets/images/godot-stair-stepping/slope-walking.gif)

Smooth (:

## Thats It!

For me, this is a pretty satisfying character controller. Its perfect for the kinds of games I work on, and could be easily augmented to have more complex movement features without disrupting the stair sweep code.

I've got an example project with the fully implemented player controller [here](https://github.com/dresswithpockets/dresswithpockets.github.io/blob/main/examples/godot-stair-stepping), if you wanted to see the full code.

Thanks for reading <3
