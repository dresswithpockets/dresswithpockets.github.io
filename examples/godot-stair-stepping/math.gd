class_name Math

static func exp_decay(a, b, decay: float, delta: float):
    return b + (a - b) * exp(-decay * delta)

static func exp_decay_f(a: float, b: float, decay: float, delta: float) -> float:
    return b + (a - b) * exp(-decay * delta)

static func exp_decay_v2(a: Vector2, b: Vector2, decay: float, delta: float) -> Vector2:
    return b + (a - b) * exp(-decay * delta)

static func exp_decay_v3(a: Vector3, b: Vector3, decay: float, delta: float) -> Vector3:
    return b + (a - b) * exp(-decay * delta)

static func slerp_exp_decay(a: Vector3, b: Vector3, decay: float, delta: float) -> Vector3:
    return a.slerp(b, exp(-decay * delta))

static func exp_decay_v3_length(a: Vector3, length: float, decay: float, delta: float) -> Vector3:
    if a == Vector3.ZERO:
        return a
    var a_length := a.length()
    var new_length := exp_decay_f(a.length(), length, decay, delta)
    return new_length * a / a_length
