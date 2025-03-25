extends Node

func _input(event: InputEvent) -> void:
    match Input.mouse_mode:
        Input.MOUSE_MODE_CAPTURED:
            if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _:
            if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
