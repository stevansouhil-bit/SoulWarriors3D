extends Node3D

var player: Node3D
var enemy: Node3D
var player_hp := 100
var enemy_hp := 100
var cooldown := 0.0
var finished := false
var status: Label
var message: Label

func _ready() -> void:
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(18, 18)
    floor.mesh = plane
    floor.material_override = mat(Color(0.12, 0.07, 0.2))
    add_child(floor)

    for i in range(9):
        box(self, Vector3(18, 0.03, 0.03), Vector3(0, 0.03, i * 2 - 8), Color(0.35, 0.12, 0.65))

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50, -30, 0)
    light.light_energy = 1.4
    add_child(light)

    player = fighter("SoulReaper", Vector3(-2, 0, 0), Color(0.1, 0.4, 1.0))
    enemy = fighter("Hollow", Vector3(2, 0, 0), Color(0.9, 0.1, 0.25))
    camera_setup()
    ui_setup()
    update_status()

func mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    return m

func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
    var obj := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    obj.mesh = mesh
    obj.position = pos
    obj.material_override = mat(c)
    parent.add_child(obj)
    return obj

func fighter(title: String, pos: Vector3, c: Color) -> Node3D:
    var root := Node3D.new()
    root.name = title
    root.position = pos
    add_child(root)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.5
    body.mesh = capsule
    body.position.y = 0.9
    body.material_override = mat(c)
    root.add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.27
    head.mesh = sphere
    head.position.y = 1.85
    head.material_override = mat(Color(0.95, 0.76, 0.64))
    root.add_child(head)

    box(root, Vector3(0.1, 1.2, 0.12), Vector3(0.5, 0.9, 0), Color(0.8, 0.9, 1))
    return root

func camera_setup() -> void:
    var cam := Camera3D.new()
    cam.position = Vector3(0, 7, 11)
    cam.current = true
    add_child(cam)
    cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)

func ui_setup() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var column := VBoxContainer.new()
    column.position = Vector2(12, 12)
    layer.add_child(column)

    status = Label.new()
    column.add_child(status)

    message = Label.new()
    message.text = "SOUL WARRIORS 3D"
    column.add_child(message)

    var row := HBoxContainer.new()
    row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    row.offset_top = -75
    layer.add_child(row)

    add_button(row, "LEFT", func(): move_player(-0.6))
    add_button(row, "RIGHT", func(): move_player(0.6))
    add_button(row, "ATTACK", func(): attack(12))
    add_button(row, "SPIRIT", func(): attack(20))
    add_button(row, "RESET", reset_round)

func add_button(parent: HBoxContainer, title: String, action: Callable) -> void:
    var b := Button.new()
    b.text = title
    b.custom_minimum_size = Vector2(0, 55)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(action)
    parent.add_child(b)

func move_player(amount: float) -> void:
    if not finished:
        player.position.x = clampf(player.position.x + amount, -7, 7)

func attack(damage: int) -> void:
    if finished:
        return
    enemy_hp = maxi(0, enemy_hp - damage)
    message.text = "Spirit attack!" if damage > 12 else "Hit!"
    update_status()
    if enemy_hp == 0:
        finish_round(true)

func _process(delta: float) -> void:
    if finished:
        return

    cooldown += delta
    var distance := enemy.position.distance_to(player.position)

    if distance > 1.8:
        var direction := (player.position - enemy.position).normalized()
        enemy.position += direction * minf(delta * 1.3, distance - 1.8)

    if distance <= 2.3 and cooldown >= 1.6:
        cooldown = 0
        player_hp = maxi(0, player_hp - 8)
        update_status()
        if player_hp == 0:
            finish_round(false)

func update_status() -> void:
    status.text = "PLAYER HP: %d    ENEMY HP: %d" % [player_hp, enemy_hp]

func finish_round(won: bool) -> void:
    finished = true
    message.text = "YOU WIN!" if won else "YOU LOSE!"

func reset_round() -> void:
    player_hp = 100
    enemy_hp = 100
    cooldown = 0
    finished = false
    player.position = Vector3(-2, 0, 0)
    enemy.position = Vector3(2, 0, 0)
    message.text = "FIGHT!"
    update_status()
