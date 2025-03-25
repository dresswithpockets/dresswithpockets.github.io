## A very naive "demo" recorder that allows me to record & playback the player's
## input. This just exists to debug some issues with the player controller code.
extends Node

class PlayerState extends RefCounted:
    var wish_dir: Vector3

class StateBuffer extends RefCounted:
    var buffer: Array[PlayerState] = []
    var start: int = 0
    var end: int = 0
    var size: int = 0
    
    func _init(capacity: int) -> void:
        buffer.resize(capacity)

    func push(state: PlayerState) -> void:
        buffer[end] = state
        end += 1
        if end == buffer.size():
            end = 0

        if size == buffer.size():
            start = end
        else:
            size += 1
    
    func to_array() -> Array[PlayerState]:
        var array: Array[PlayerState] = []
        array.append_array(_array_one())
        array.append_array(_array_two())
        return array

    func _array_one() -> Array[PlayerState]:
        if size == 0:
            return []
        if start < end:
            return buffer.slice(start, end)
        return buffer.slice(start)
    
    func _array_two() -> Array[PlayerState]:
        if size == 0 or start < end:
            return []
        return buffer.slice(0, end)

var _playground_scene: PackedScene = preload("res://playground/playground.tscn")

enum PlaybackState { OFF, RECORDING, REPLAYING }
var playback_state: PlaybackState = PlaybackState.RECORDING

# 2 second long buffer
const BUFFER_CAPACITY: int = 60 * 2
var _state_buffer := StateBuffer.new(BUFFER_CAPACITY)

var _recording: Array[PlayerState]
var _current_state_idx: int = 0
var _next_state_queue: Array[PlayerState] = []
var _player_state_history: Array[Node3D] = []

func push_state(wish_dir: Vector3) -> void:
    var player_state := PlayerState.new()
    player_state.wish_dir = wish_dir
    _state_buffer.push(player_state)

func get_next_state() -> PlayerState:
    if len(_next_state_queue) == 0:
        return null

    return _next_state_queue.pop_front()

func _input(event: InputEvent) -> void:
    match playback_state:
        PlaybackState.RECORDING:
            if event is InputEventKey and event.keycode == KEY_P and event.is_pressed():
                _begin_playback()
        PlaybackState.REPLAYING:
            if event is InputEventKey and event.is_pressed():
                if event.keycode == KEY_K:
                    _increment_player_state()
                elif event.keycode == KEY_J:
                    _reload_previous_player_state()

func _begin_playback() -> void:
    # reload the Playground scene & update our state so that the player 
    # controller receives no input from the user.
    playback_state = PlaybackState.REPLAYING
    _recording = _state_buffer.to_array()
    assert(get_tree().reload_current_scene() == OK)

func _increment_player_state() -> void:
    if len(_recording) - _current_state_idx <= 0:
        return

    var player_node: Node = get_tree().root.get_node("Playground/Player")
    _player_state_history.append(player_node.duplicate())

    var next_state := _recording[_current_state_idx]
    _next_state_queue.push_back(next_state)
    _current_state_idx += 1

func _reload_previous_player_state() -> void:
    if len(_player_state_history) == 0:
        return

    var playground := get_tree().root.get_node("Playground")
    var current_player: Node = playground.get_node("Player")
    playground.remove_child(current_player)
    current_player.free()

    var new_player: Node = _player_state_history.pop_back()
    playground.add_child(new_player)

    _current_state_idx -= 1
