---
layout: post
title:  "A Godot Replay System"
date:   2025-09-27 2:00:00 -0700
tags:   godot gamedev
---

If you load up Super Mario 64, and sit on the start screen for a little while, the game will show example gameplay on screen:

![sm64 start screen demo](/assets/images/godot-replay/sm64-demo.gif)

This gameplay isn't a video though - even if the Nintendo 64 was capable of video playback of this quality, it wouldve been quite the waste of space. If its not a video recording, how is gameplay being shown here?

# Demos

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

# You should have replays in your game

Why?

- players want them
- replays can aid in reproducing bugs
- players can submit replays alongside bug reports
- replays can be associated with leaderboard entries (ex: [Devil Daggers](https://devildaggers.info/leaderboard), [Half-Life Speedruns](https://www.speedrun.com/hl1))
- replays can be verified systematically, to prevent cheating
- replays can be analyzed for player behaviour, to aid in game design
- screen recordings are bigger and resource intensive to create

# How they work

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

# Debugging your game with a replay

There are two scenarios where replays really come in handy: bug reproduction, and investigation.

## Reproduction

Lets say someone has sent you a bug report, but youre not able to recreate the bug using the description & dump sent in the report. You open up the replay and watch as some crazy glitch happens. Now you have a legitimate reproduction of the bug!

With good playback controls, you can pause and step back/forward to the ticks where the bug occurs, and do whatever debugging you need to do from that point on. Set breakpoints, step through code one tick at a time, etc.

## Investigation

You're playtesting your game and you run into a bug, and you want to debug it. You're able to reproduce it somewhat consistently, and you have an idea of where to set a breakpoint to start investigating what might be the culprit; but... theres no way to set a breakpoint that only pauses execution when "a bug happens".

So you start recording a replay, reproduce the bug, then play the replay back until the bug occurs. Now you have a specific tick you can pause on, set breakpoints on, and investigate in.

# Godot SReplay

I wanted to create a replay system for my games, in a way that doesn't require me to build my game _around_ the replay system. I want this tool to work without me having to consider how it works when writing game code.

In search of that, I've created [SReplay](https://github.com/dresswithpockets/godot-sreplay). This addon acts as a shim between your game logic and Godot's input systems. Its effectively a drop-in replacement for `Input` and the `_unhandled_input` event - though with some caveats.

## Integration

### Input Polling

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

### Input Events

SReplay captures `InputEvent`'s that you'd normally receive in `_unhandled_input`, and propogates them to `_sreplay_input` across the entire node tree:

```gdscript
func _sreplay_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and SReplay.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        move_camera(event.screen_relative)
```

### Custom Data

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

## Recording & Playback

SReplay exposes a few functions - `record`, `stop`, `play` - for recording & playback.

SReplay records input state captured on the Idle tick separately from those captured on the Physics tick. This allows you to show visual changes - like camera movement - across every frame while maintaining deterministic input in your physics tick. During playback, functions like `SReplay.get_vector`, members like `SReplay.mouse_mode`, and events like `_sreplay_input` will return the recorded state & events rather than the live input state or any live events.

Managing recording & playback is out of the scope of SReplay - the approach to recording & playback could vary drastically depending on the game, so its up to you to implement those systems. I've included an [example recording manager](https://github.com/dresswithpockets/godot-sreplay/blob/main/example/recorder), which includes a very basic playback control UI - with timeline scrubbing & speed controls.

Here's a demonstration of that recorder in practice:

<video src="/assets/videos/godot-replay/embed_demo.1080p60.hevc.mp4" data-canonical-src="/assets/videos/godot-replay/embed_demo.1080p60.hevc.mp4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit" style="max-height:640px; min-height: 200px" crossorigin="anonymous"></video>

## Serialization & File Size

SReplay provides functions to convert the recording to a serializable dictionary - so you can serialize the recording in any format you see fit. I've had good results with this approach to serialization:

```gdscript
## serializes the input recording to UTF8 JSON, and optionally gzip-compresses it
func serialize(recording: SReplay.Recording, compress: bool) -> PackedByteArray:
    var dict := recording.to_dict()
    var json := JSON.stringify(dict)
    var bytes := json.to_utf8_buffer()
    if compress:
        return bytes.compress(FileAccess.COMPRESSION_GZIP)
    return bytes

## deserializes UTF8 JSON bytes into a Recording, optionally gzip-decompressing them before parsing
func deserialize(bytes: PackedByteArray, decompress: bool) -> SReplay.Recording:
    if decompress:
        # don't allow more than 512MB in decompressed size
        const max_size := 1024 * 1024 * 1024 * 512
        bytes = bytes.decompress_dynamic(max_size, FileAccess.COMPRESSION_GZIP)

    var json := bytes.get_string_from_utf8()
    var dict: Dictionary = JSON.parse_string(json)
    return SReplay.Recording.from_dict(dict)
```

The demonstration shown earlier produced a 5MB uncompressed replay file, for about 30 seconds of gameplay - about 166 KB per second on average. I was able to produce a 5MB video of the same gameplay with expensive lossy compression (see below for details on how I recorded & compressed the video). So, without compression, the replay is similar size as an aggressively compressed video - a video with just acceptable quality and framerate. 

With GZIP compression, that same replay only takes up 136KB! Thats 4.5 KB per second, a 97% reduction in bitrate. An hour long replay at this bitrate could be sent as an attachment in an email - which happens to be how some games accept bug reports.

Replays aren't a total replacement for videos - videos are portable; but, for the purposes of reproducing a game's exact state, or storing gameplay for future playback in-engine, replays are great.

### Video codec nerd stuff

For those interested, heres the final video I used in size comparisons:

<video src="/assets/videos/godot-replay/test.1080p30.hevc.mp4" data-canonical-src="/assets/videos/godot-replay/test.1080p30.hevc.mp4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit" style="max-height:640px; min-height: 200px" crossorigin="anonymous"></video>

I recorded the gameplay in OBS with the following video & encoder settings:
```
Canvas Resolution: 1920x1080
Scaled Resolution: 1920x1080
FPS:               120
Format:            Matroska Video
Encoder:           SVT-AV1
Rate Control:      CBR
Bitrate:           5000 Kbps
Keyframe Interval: 0 s
Preset:            Might be better (9)
```

Then I transcoded the video via ffmpeg:

```sh
ffmpeg -i test.1080p120.av1.mkv -filter:v fps=30 -c:v libx265 -crf 25 -preset slow test.1080p30.hevc.mp4
```

This took ~30 seconds to finish encoding. Most people recording clips won't be manually re-encoding their clips with an expensive compression mode like `-preset slow`, and are instead going to be encoding them in real-time with OBS or Shadowplay. My demo game is also not particularly noisy, so its particularly well suited to HEVC's compression. All in all, a recording of a more complex game with worse compression settings will likely produce a significantly larger video.

> N.B. AV1 can likely get better stats, but AV1 doesn't have great web support yet. Most people are going to be sharing AVC (h.264) or HEVC (h.265) videos. So, I chose HEVC which will produce decent quality with relatively small sizes. 
>
> N.B.B. Encoding with `fps=60` only increases the file size by about 20% for this video. Depending on the size limitations, that tradeoff may be desirable.
>
> N.B.B. I tried transcoding with NVDEC and NVENC for better performance. I was able to transcode the video in under two seconds, which exceeds real-time transcoding; but, since there arent equivalent CRF options in the `hevc_nvenc` encoder, I wasnt able to tune the encoder to get the same size performance.

## Under The Hood

The SReplay addon adds an `SReplay` autoload to your scene. The recording is just a handful of arrays of state snapshots and changes between the snapshots each tick. The logic thats most relevant to you looks like this:

```
every physics tick while recording:
    have we captured any input changes since last tick?
        then, add those changes to the recording

    has it been long enough since the last snapshot?
        then, duplicate our current aggregate state
        then, add the duplicated state to the recording

    capture any new inputs & user captures for the next tick

every physics tick during playback:
    are we at a new snapshot in the playback?
        then, replace our current state with the snapshot's state

    are there any new input states this tick?
        then, apply the changes to the current input state
```

The logic is almost identical in the idle tick with a couple differences:

```
every idle tick while recording:
    have we captured any input changes since last tick?
        then, add those changes to the recording

    have we captured any input events since last tick?
        then, add those changes to the recording

every idle tick during playback:
    for each input change in the recording:
        is it's timestamp less than or equal to idle_time?
            then, apply the change to the current input state

    for each input event in the recording:
        is it's timestamp less than or equal to idle_time?
            then, propogate the event
```

The idle tick does its processing based on time passed rather than a tick counter. It doesn't capture snapshots, and additionally handles `InputEvent`'s received from `_unhandled_input`.

The autoload also has drop-in replacements for almost every action-based function in `Input`. For example, `is_action_just_pressed` is implemented like this:

```gdscript
func is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
    if _mode != Mode.REPLAYING:
        return Input.is_action_just_pressed(action, exact_match)

    # _idle_input and _physics_input include the current aggregate input state for the idle tick 
    # and physics tick separately
    var input_state: InputState = _idle_input
    if Engine.is_in_physics_frame():
        input_state = _physics_input

    # the InputState includes two dictionaries that map the action to the action's state; one for
    # exact_match = true, and one for exact_match = false. This ensures exact_match always has
    # 1-to-1 parity with Godot's exact_match
    var actions: Dictionary[StringName, ActionState] = input_state.actions
    if exact_match:
        actions = input_state.actions_exact

    var action_state: ActionState = actions.get(action)
    if action_state == null:
        push_error("Action doesn't exist in replay: '%s'" % action)
        return null

    # the ActionState includes a handful of properties like `pressed`, `released`, `just_pressed` 
    # etc. These are all captured during recording every idle and physics tick, whenever there are
    # changes, and then applied each tick to the ActionState during playback.
    return action_state.just_pressed
```

The logic is the same for all other input functions which return a state for an `InputMap` action. Similar logic is used to capture `mouse_mode`, mouse velocity, and mouse buttons. At the moment some inputs like joys, gyroscopes, and keys, are not captured. With some minor tweaks, they could be added to the input state and recorded.

### Snapshots & Seeking

During playback, you might want to be able to "scrub" the timeline - that is, seek to an arbitrary point in time. With an input-based recording system, that can be quite difficult - without recording the entire game state, you'd have to "play" all of the inputs up to the tick you want to seek to. This can be process intensive and time consuming during. State snapshots can make seeking almost instantaneous.

SReplay will take periodic snapshots of the aggregate input state every so often. The rate is configurable when you call `SReplay.record`. Those snapshots include the current input delta, input event, and capture offsets - as well as a snapshot of the entire input & capture state. Periodic snapshots enable the `seek` function, which will look for the target tick's prior snapshot and quickly play up-to the target tick from the relevant snapshot. As a side effect, this enables bi-directional tick-by-tick stepping. 

