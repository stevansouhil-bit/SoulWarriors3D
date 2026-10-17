extends Node3D

var player: Node3D
var enemy: Node3D
var player_sword: MeshInstance3D
var enemy_sword: MeshInstance3D

var player_hp := 100
var enemy_hp := 100
var enemy_cooldown := 0.0
var attack_cooldown := 0.0
var energy_cooldown := 0.0
var finished := false

var status: Label
var message: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar

const ARENA_LIMIT := 7.0
const PLAYER_SPEED := 4.0
const ENEMY_SPEED := 2.1

func _ready() -> void:
    create_arena()
    player = create_fighter(
        "SoulReaper", Vector3(-2, 0, 0),
        Color(0.08, 0.35, 1.0)
    )
    enemy = create_fighter(
        "Hollow", Vector3(2, 0, 0),
        Color(0.95, 0.08, 0.22)
    )
    player_sword = player.get_node("Sword")
    enemy_sword = enemy.get_node("Sword")
    create_camera()
    create_ui()
    update_ui()

func material(c: Color, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 2.0
    return m

func add_box(parent: Node3D, size: Vector3,
        pos: Vector3, color: Color,
        glow := false) -> MeshInstance3D:
    var obj := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    obj.mesh = mesh
    obj.position = pos
    obj.material_override = material(color, glow)
    parent.add_child(obj)
    return obj

func create_arena() -> void:
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(18, 18)
    floor.mesh = plane
    floor.material_override = material(Color(0.045, 0.025, 0.09))
    add_child(floor)

    for i in range(-8, 9, 2):
        add_box(self, Vector3(17, 0.025, 0.025),
            Vector3(0, 0.02, i), Color(0.22, 0.08, 0.48), true)
        add_box(self, Vector3(0.025, 0.025, 17),
            Vector3(i, 0.025, 0), Color(0.12, 0.08, 0.3))

    for side in [-1.0, 1.0]:
        for i in range(3):
            add_box(self, Vector3(0.55, 2.2, 0.55),
                Vector3(side * 7.7, 1.1, i * 3.0 - 3.0),
                Color(0.12, 0.07, 0.22))
            add_box(self, Vector3(0.7, 0.12, 0.7),
                Vector3(side * 7.7, 2.25, i * 3.0 - 3.0),
                Color(0.25, 0.65, 1.0), true)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-52, -25, 0)
    light.light_energy = 1.5
    add_child(light)

    var glow_light := OmniLight3D.new()
    glow_light.position = Vector3(0, 4, 0)
    glow_light.light_color = Color(0.25, 0.15, 1.0)
    glow_light.light_energy = 2.0
    glow_light.omni_range = 12
    add_child(glow_light)

func create_fighter(title: String, pos: Vector3,
        color: Color) -> Node3D:
    var root := Node3D.new()
    root.name = title
    root.position = pos
    add_child(root)

    add_box(root, Vector3(0.85, 1.15, 0.48),
        Vector3(0, 1.0, 0), color)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.3
    head_mesh.height = 0.6
    head.mesh = head_mesh
    head.position = Vector3(0, 1.85, 0)
    head.material_override = material(Color(0.95, 0.76, 0.65))
    root.add_child(head)

    add_box(root, Vector3(0.28, 0.65, 0.32),
        Vector3(-0.23, 0.28, 0), color.darkened(0.3))
    add_box(root, Vector3(0.28, 0.65, 0.32),
        Vector3(0.23, 0.28, 0), color.darkened(0.3))

    var sword := add_box(root, Vector3(0.12, 1.35, 0.10),
        Vector3(0.62, 1.0, -0.05),
        Color(0.45, 0.85, 1.0), true)
    sword.name = "Sword"

    add_box(root, Vector3(0.65, 0.12, 0.12),
        Vector3(0.6, 0.48, -0.05), Color(0.95, 0.65, 0.2), true)

    return root

func create_camera() -> void:
    var cam := Camera3D.new()
    cam.position = Vector3(0, 8.5, 12)
    cam.current = true
    add_child(cam)
    cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)

func create_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var top := VBoxContainer.new()
    top.position = Vector2(18, 12)
    top.custom_minimum_size = Vector2(300, 0)
    layer.add_child(top)

    var title := Label.new()
    title.text = "SOUL WARRIORS 3D"
    title.add_theme_font_size_override("font_size", 23)
    top.add_child(title)

    player_bar = ProgressBar.new()
    player_bar.max_value = 100
    player_bar.show_percentage = false
    player_bar.custom_minimum_size = Vector2(260, 22)
    top.add_child(player_bar)

    enemy_bar = ProgressBar.new()
    enemy_bar.max_value = 100
    enemy_bar.show_percentage = false
    enemy_bar.custom_minimum_size = Vector2(260, 22)
    top.add_child(enemy_bar)

    status = Label.new()
    top.add_child(status)

    message = Label.new()
    message.text = "FIGHT!"
    message.add_theme_font_size_override("font_size", 22)
    message.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message.position = Vector2(-90, 12)
    layer.add_child(message)

    var controls := HBoxContainer.new()
    controls.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    controls.offset_top = -76
    controls.offset_bottom = -8
    controls.add_theme_constant_override("separation", 8)
    layer.add_child(controls)

    add_button(controls, "LEFT", func(): move_player(-1.0))
    add_button(controls, "RIGHT", func(): move_player(1.0))
    add_button(controls, "SWORD", func(): attack(12))
    add_button(controls, "SPIRIT", energy_attack)
    add_button(controls, "RESET", reset_round)

func add_button(parent: HBoxContainer, text_value: String,
        action: Callable) -> void:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(100, 58)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(action)
    parent.add_child(b)

func move_player(direction: float) -> void:
    if finished:
        return
    player.position.x = clampf(
        player.position.x + direction * 0.8,
        -ARENA_LIMIT, ARENA_LIMIT
    )
    face_each_other()

func face_each_other() -> void:
    if player and enemy:
        player.look_at(Vector3(enemy.position.x, 0, enemy.position.z),
            Vector3.UP)
        enemy.look_at(Vector3(player.position.x, 0, player.position.z),
            Vector3.UP)

func attack(damage: int) -> void:
    if finished or attack_cooldown > 0:
        return
    attack_cooldown = 0.45
    face_each_other()

    if player.position.distance_to(enemy.position) > 3.0:
        message.text = "Too far away!"
        return

    enemy_hp = maxi(0, enemy_hp - damage)
    message.text = "SWORD HIT!"
    show_effect(enemy.position, Color(0.25, 0.7, 1.0))
    update_ui()

    if enemy_hp == 0:
        finish_round(true)

func energy_attack() -> void:
    if finished or energy_cooldown > 0:
        return
    energy_cooldown = 2.0

    if player.position.distance_to(enemy.position) > 6.0:
        message.text = "Energy missed!"
        return

    enemy_hp = maxi(0, enemy_hp - 20)
    message.text = "SPIRIT BLAST!"
    show_effect(enemy.position, Color(0.2, 0.55, 1.0))
    update_ui()

    if enemy_hp == 0:
        finish_round(true)

func show_effect(pos: Vector3, color: Color) -> void:
    var orb := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.35
    mesh.height = 0.7
    orb.mesh = mesh
    orb.position = pos + Vector3(0, 1.1, 0)
    orb.material_override = material(color, true)
    add_child(orb)

    var tween := create_tween()
    tween.tween_property(orb, "scale", Vector3(3, 3, 3), 0.22)
    tween.tween_callback(orb.queue_free)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    energy_cooldown = maxf(0.0, energy_cooldown - delta)

    if finished:
        return

    enemy_cooldown += delta
    var distance := player.position.distance_to(enemy.position)

    if distance > 1.65:
        var direction := player.position - enemy.position
        direction.y = 0
        enemy.position += direction.normalized() * minf(
            ENEMY_SPEED * delta, distance - 1.65
        )
    elif enemy_cooldown >= 1.5:
        enemy_cooldown = 0
        player_hp = maxi(0, player_hp - 8)
        message.text = "ENEMY ATTACK!"
        show_effect(player.position, Color(1.0, 0.12, 0.2))
        update_ui()

        if player_hp == 0:
            finish_round(false)

    face_each_other()

func update_ui() -> void:
    if not is_instance_valid(status):
        return
    player_bar.value = player_hp
    enemy_bar.value = enemy_hp
    status.text = "PLAYER: %d HP     HOLLOW: %d HP" % [
        player_hp, enemy_hp
    ]

func finish_round(won: bool) -> void:
    finished = true
    message.text = "YOU WIN!" if won else "YOU LOSE!"

func reset_round() -> void:
    player_hp = 100
    enemy_hp = 100
    enemy_cooldown = 0
    attack_cooldown = 0
    energy_cooldown = 0
    finished = false
    player.position = Vector3(-2, 0, 0)
    enemy.position = Vector3(2, 0, 0)
    message.text = "FIGHT!"
    update_ui()
    face_each_other()
