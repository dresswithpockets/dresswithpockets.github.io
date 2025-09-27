---
layout: post
title:  "A Godot Replay System"
date:   2025-09-27 2:00:00 -0700
tags:   godot gamedev
---

If you load up Super Mario 64, and sit on the start screen for a little while, the game will show example gameplay on screen:

![sm64 start screen demo](/assets/images/godot-replay/sm64-demo.gif)

This gameplay isn't a video though - even if the Nintendo 64 was capable of video playback of this quality, it wouldve been quite the waste of space. If its not a video recording, how is gameplay being shown here?

## Demos

"Demo" can refer to many things:

- a free version of a game that has limited features or playtime,
- a live demonstration of a game - like at a convention booth,
- a very small self-contained program - which might show off gameplay, art, music, etc,
- or, **a user-input recording used to playback gameplay**

SM64 - and many other games - use recordings that contain snapshots of game state and user input data. These recordings are parsed by the game and used to emulate user-input, effectively recreating the gameplay the player experienced at time of recording.

> N.B.
>
> If you've ever seen an arcade cabinet playing back gameplay on screen, chances are it was using an input-based demo system.
>
> Source Engine games also offer prominent demo-recording features.

I'll refer to these as "replays" from now on, to differentiate from the other kinds of demos.

## You should have replays in your game

Why?

- players want them
- replays can aid in reproducing bugs
- players can submit replays alongside bug reports
- replays can be associated with leaderboard entries (ex: [Devil Daggers](https://devildaggers.info/leaderboard), [Half-Life Speedruns](https://www.speedrun.com/hl1))
- replays can be verified systematically, to prevent cheating
- replays can be analyzed for player behaviour, to aid in game design
- screen recordings are bigger and resource intensive to create

## How they work

The details of a replay system will vary drastically depending on the kind of game they are in service of. In general, a replay will include the following information:

- tickstamped/timestamped input data/input events, for example:
    - a button that was pressed is no longer pressed
    - a joystick axis changed strength
    - the mouse moved
- tickstamped/timestamped command data, for example:
    - in an RTS, the player selected a unit on the field
    - in an FPS, the player fired their weapon
- periodic snapshot data, for example:
    - the entire input state
    - the current scene
    - the current state of important game objects
        - e.g. did the player open a door?

During playback, the game will use the stored input data in place of a player's input. **If your game logic is deterministic, then the playback should be logically identical to the original gameplay.**

## Debugging your game with a replay

There are two scenarios where replays really come in handy: bug reproduction, and investigation.

### Reproduction

Lets say someone has sent you a bug report, but youre not able to recreate the bug using the description & dump sent in the report. You open up the replay and watch as some crazy glitch happens. Now you have a legitimate reproduction of the bug!

With good playback controls, you can pause and step back/forward to the ticks where the bug occurs, and do whatever debugging you need to do from that point on. Set breakpoints, step through code one tick at a time, etc.

### Investigation

You're playtesting your game and you run into a bug, and you want to debug it. You're able to reproduce it somewhat consistently, and you have an idea of where to set a breakpoint to start investigating what might be the culprit; but... theres no way to set a breakpoint that only pauses execution when "a bug happens".

So you start recording a replay, reproduce the bug, then play the replay back until the bug occurs. Now you have a specific tick you can pause on, set breakpoints on, and investigate in.

## Godot SReplay

I wanted to create a replay system for my games, in a way that doesn't require me to build my game _around_ the replay system. I want this tool to work without me having to consider how it works when writing game code.

In search of that, I've created [SReplay](https://github.com/dresswithpockets/godot-sreplay). This addon acts as a shim between your game logic and Godot's input systems. Its effectively a drop-in replacement for `Input` and the `_unhandled_input` event - though with some caveats.

### Integration

#### Input Polling

SReplay exposes an `Input`-like surface. In many cases, the only difference is replacing `Input` with `SReplay`. Heres an example usage of `get_vector`:

```gdscript
## get the direction the player wishes to move in
func get_wish_dir() -> Vector3:
    var input_dir := Vector2.ZERO
    if SReplay.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        input_dir = SReplay.get_vector("move_left", "move_right", "move_forward", "move_back")
    
    return camera.yaw * Vector3(input_dir.x, 0, input_dir.y)
```

The behaviour of this function and others should be identical to `Input`.

#### Input Events

SReplay captures `InputEvent`'s that you'd normally receive in `_unhandled_input`, and propogates them to `_sreplay_input` across the entire node tree:

```gdscript
func _sreplay_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and SReplay.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        move_camera(event.screen_relative)
```

#### Custom Data

Want to store your own data? SReplay exposes a function `capture` to capture arbitrary user data.

For example: if you're making an FPS, chances are your player's movement depends on the rotation of the camera. Your camera's rotation is probably getting updated before the player processes movement input. You can capture the camera's state every physics tick to ensure that the player's camera-based-movement is deterministic during playback:

```gdscript
# yaw and pitch are used to calculate the camera's global_basis, and are updated elsewhere
var yaw: Basis = Basis.IDENTITY
var pitch: Basis = Basis.IDENTITY

# ...

func _physics_process(_delta: float) -> void:
    yaw = SReplay.capture(replay_player_camera_yaw, yaw)
    pitch = SReplay.capture(replay_player_camera_pitch, pitch)
    global_basis = yaw * pitch
```

See [player_camera.gd](https://github.com/dresswithpockets/godot-sreplay/blob/main/example/player/player_camera.gd) for a complete example.

### Recording & Playback

SReplay exposes a few functions - `record`, `stop`, `play` - for recording & playback.

SReplay records input state captured on the Idle tick separately from those captured on the Physics tick. This allows you to show visual changes - like camera movement - across every frame while maintaining deterministic input in your physics tick. During playback, functions like `SReplay.get_vector`, members like `SReplay.mouse_mode`, and events like `_sreplay_input` will return the recorded state & events rather than the live input state or any live events.

Managing recording & playback is out of the scope of SReplay - the approach to recording & playback could vary drastically depending on the game, so its up to you to implement those systems. I've included an [example recording manager](https://github.com/dresswithpockets/godot-sreplay/blob/main/example/recorder), which includes a very basic playback control UI - with timeline scrubbing & speed controls.

Here's a demonstration of that recorder in practice:

<video src="/assets/videos/godot-replay/embed_demo.mp4" data-canonical-src="/assets/videos/godot-replay/embed_demo.mp4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit" style="max-height:640px; min-height: 200px" crossorigin="anonymous"></video>

### Serialization

SReplay provides functions to convert the recording to a serializable dictionary - so you can serialize the recording in any format you see fit. I've had good results with this approach to serialization:

```gdscript
## serializes the input recording to UTF8 JSON, and compresses it via GZIP
func serialize(recording: SReplay.Recording) -> PackedByteArray:
    var dict := recording.to_dict()
    var json := JSON.stringify(dict)
    var bytes := json.to_utf8_buffer()
    return bytes.compress(FileAccess.COMPRESSION_GZIP)

## deserializes the compressed UTF8 JSON bytes into a Recording
func deserialize(compressed_bytes: PackedByteArray) -> SReplay.Recording:
    # don't allow more than 512MB in decompressed size
    const max_size := 1024 * 1024 * 1024 * 512
    var bytes := compressed_bytes.decompress_dynamic(max_size, FileAccess.COMPRESSION_GZIP)
    var json := bytes.get_string_from_utf8()
    var dict := JSON.parse_string(json)
    retrun SReplay.Recording.from_dict(dict)
```
