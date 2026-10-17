extends Node3D

var player: Node3D
var battle_camera: Camera3D
var enemy: Node3D
var player_hp := 100
var enemy_hp := 100
var enemy_cooldown := 0.0
var attack_cooldown := 0.0
var energy_cooldown := 0.0
var finished := false

var player_bar: ProgressBar
var enemy_bar: ProgressBar
var status: Label
var message: Label

const ARENA_LIMIT := 7.0
const PLAYER_SPEED := 3.8
const ENEMY_SPEED := 1.7

func _ready() -> void:
    create_world()
    create_arena()
    player = create_fighter("SoulReaper", Vector3(-2, 0, 1), Color(0.045, 0.055, 0.12), Color(1.0, 0.32, 0.06))
    enemy = create_fighter("Hollow", Vector3(2, 0, -1), Color(0.28, 0.045, 0.09), Color(0.85, 0.08, 0.16))
    create_camera()
    create_ui()
    face_each_other()
    update_ui()

func make_material(c: Color, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.72
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 1.7
    return m

func add_box(parent: Node3D, size: Vector3, pos: Vector3,
        color: Color, glow := false) -> MeshInstance3D:
    var obj := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    obj.mesh = mesh
    obj.position = pos
    obj.material_override = make_material(color, glow)
    parent.add_child(obj)
    return obj

func add_sphere(parent: Node3D, pos: Vector3, radius: float,
        color: Color, glow := false) -> MeshInstance3D:
    var obj := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    obj.mesh = mesh
    obj.position = pos
    obj.material_override = make_material(color, glow)
    parent.add_child(obj)
    return obj

func create_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.035, 0.055, 0.13)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.48, 0.56, 0.82)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.45
    sun.shadow_enabled = true
    add_child(sun)

    var fill := OmniLight3D.new()
    fill.position = Vector3(0, 6, 0)
    fill.light_color = Color(0.2, 0.32, 1.0)
    fill.light_energy = 2.0
    fill.omni_range = 18
    add_child(fill)

func create_arena() -> void:
    # Large stone plaza and central road.
    add_box(self, Vector3(48, 0.5, 58), Vector3(0, -0.28, -5),
        Color(0.43, 0.43, 0.47))

    add_box(self, Vector3(4.6, 0.06, 52), Vector3(0, 0.005, -5),
        Color(0.63, 0.61, 0.59))

    # Stone road tiles.
    for z in range(-29, 21, 2):
        add_box(self, Vector3(4.45, 0.025, 0.055),
            Vector3(0, 0.045, float(z)), Color(0.34, 0.35, 0.40))

    # Keep the original central combat area clear.
    for x in range(-12, 13, 3):
        add_box(self, Vector3(0.025, 0.012, 24),
            Vector3(float(x), 0.015, 0), Color(0.23, 0.29, 0.40))
    for z in range(-12, 13, 3):
        add_box(self, Vector3(24, 0.012, 0.025),
            Vector3(0, 0.016, float(z)), Color(0.23, 0.29, 0.40))

    # Water canals on both sides of the road.
    for side in [-1.0, 1.0]:
        add_box(self, Vector3(1.45, 0.055, 43),
            Vector3(side * 6.8, -0.005, -5), Color(0.08, 0.36, 0.53))
        add_box(self, Vector3(0.22, 0.18, 44),
            Vector3(side * 7.65, 0.025, -5), Color(0.55, 0.53, 0.49))

        # Small bridges over each canal.
        for bridge_z in [-12.0, 0.0, 10.0]:
            add_box(self, Vector3(2.15, 0.16, 2.0),
                Vector3(side * 6.8, 0.075, bridge_z),
                Color(0.66, 0.60, 0.52))

        # Outer defensive walls.
        add_box(self, Vector3(0.7, 5.2, 48),
            Vector3(side * 18.0, 2.6, -5), Color(0.72, 0.70, 0.66))
        add_box(self, Vector3(1.0, 0.32, 48),
            Vector3(side * 18.0, 5.25, -5), Color(0.24, 0.25, 0.31))

        # Traditional Japanese houses along the street.
        for house_z in [-17.0, -10.0, -3.0, 5.0, 12.0]:
            add_japanese_house(
                Vector3(side * 11.0, 0, house_z),
                3.6, 2.5, 3.8
            )

        # Cherry blossom trees.
        for tree_z in [-20.0, -13.0, -6.0, 2.0, 10.0, 16.0]:
            add_cherry_tree(Vector3(side * 14.7, 0, tree_z), 1.35)

        # Warm lanterns along the plaza.
        for lamp_z in [-15.0, -7.0, 1.0, 9.0, 16.0]:
            add_box(self, Vector3(0.16, 1.9, 0.16),
                Vector3(side * 5.3, 0.95, lamp_z),
                Color(0.19, 0.15, 0.13))
            add_box(self, Vector3(0.65, 0.58, 0.55),
                Vector3(side * 5.3, 1.95, lamp_z),
                Color(1.0, 0.65, 0.28), true)

    # Grand castle gate at the far end of the road.
    add_box(self, Vector3(8.5, 3.2, 2.0),
        Vector3(0, 1.6, -20.5), Color(0.79, 0.77, 0.71))
    add_box(self, Vector3(3.2, 2.2, 0.35),
        Vector3(0, 1.0, -19.35), Color(0.12, 0.13, 0.17))
    add_box(self, Vector3(10.0, 0.3, 3.2),
        Vector3(0, 3.25, -20.5), Color(0.18, 0.19, 0.25))
    var gate_roof_left := add_box(self, Vector3(5.7, 0.22, 2.2),
        Vector3(-2.4, 3.55, -20.5), Color(0.16, 0.17, 0.23))
    gate_roof_left.rotation_degrees.z = -8
    var gate_roof_right := add_box(self, Vector3(5.7, 0.22, 2.2),
        Vector3(2.4, 3.55, -20.5), Color(0.16, 0.17, 0.23))
    gate_roof_right.rotation_degrees.z = 8

    # Multi-level Japanese castle silhouette.
    add_box(self, Vector3(9.0, 3.1, 5.2),
        Vector3(0, 1.55, -27.0), Color(0.79, 0.78, 0.74))
    add_box(self, Vector3(10.0, 0.24, 5.8),
        Vector3(0, 3.15, -27.0), Color(0.16, 0.18, 0.25))

    add_box(self, Vector3(6.7, 2.4, 4.4),
        Vector3(0, 4.35, -27.0), Color(0.82, 0.80, 0.75))
    add_box(self, Vector3(7.8, 0.22, 5.0),
        Vector3(0, 5.6, -27.0), Color(0.15, 0.17, 0.24))

    add_box(self, Vector3(4.6, 2.0, 3.4),
        Vector3(0, 6.7, -27.0), Color(0.84, 0.82, 0.77))
    add_box(self, Vector3(5.8, 0.22, 4.0),
        Vector3(0, 7.75, -27.0), Color(0.14, 0.16, 0.23))

    add_box(self, Vector3(2.8, 1.35, 2.5),
        Vector3(0, 8.5, -27.0), Color(0.83, 0.81, 0.76))
    add_box(self, Vector3(3.8, 0.22, 3.1),
        Vector3(0, 9.25, -27.0), Color(0.14, 0.16, 0.23))
    add_box(self, Vector3(0.22, 1.0, 0.22),
        Vector3(0, 9.85, -27.0), Color(0.91, 0.72, 0.34), true)

func add_japanese_house(pos: Vector3, width: float,
        height: float, depth: float) -> void:
    # Raised foundation and timber-framed walls.
    add_box(self, Vector3(width + 0.25, 0.25, depth + 0.25),
        pos + Vector3(0, 0.12, 0), Color(0.31, 0.30, 0.31))
    add_box(self, Vector3(width, height, depth),
        pos + Vector3(0, height * 0.5 + 0.24, 0),
        Color(0.73, 0.66, 0.55))

    # Dark sloping roof panels.
    var roof_y := height + 0.55
    var roof_left := add_box(self,
        Vector3(width + 0.8, 0.20, depth * 0.62),
        pos + Vector3(0, roof_y, -depth * 0.19),
        Color(0.15, 0.17, 0.23))
    roof_left.rotation_degrees.x = -24
    var roof_right := add_box(self,
        Vector3(width + 0.8, 0.20, depth * 0.62),
        pos + Vector3(0, roof_y, depth * 0.19),
        Color(0.15, 0.17, 0.23))
    roof_right.rotation_degrees.x = 24

    # Front door and glowing windows.
    add_box(self, Vector3(0.75, 1.45, 0.09),
        pos + Vector3(0, 0.97, depth * 0.5 + 0.055),
        Color(0.25, 0.15, 0.12))
    for side in [-1.0, 1.0]:
        add_box(self, Vector3(0.48, 0.62, 0.08),
            pos + Vector3(side * width * 0.29, height * 0.63,
                depth * 0.5 + 0.06), Color(1.0, 0.72, 0.39), true)
        add_box(self, Vector3(0.06, 0.72, 0.09),
            pos + Vector3(side * width * 0.29, height * 0.63,
                depth * 0.5 + 0.11), Color(0.23, 0.16, 0.13))

func add_cherry_tree(pos: Vector3, size: float) -> void:
    # Brown trunk.
    add_box(self, Vector3(0.25 * size, 1.65 * size, 0.25 * size),
        pos + Vector3(0, 0.82 * size, 0), Color(0.28, 0.17, 0.13))

    # Pink blossom clusters.
    var pinks := [
        Color(1.0, 0.61, 0.76),
        Color(1.0, 0.73, 0.83),
        Color(0.91, 0.46, 0.66)
    ]
    var offsets := [
        Vector3(0, 1.7, 0),
        Vector3(0.65, 1.5, 0.15),
        Vector3(-0.65, 1.5, -0.1),
        Vector3(0.25, 2.0, -0.35),
        Vector3(-0.25, 1.95, 0.35)
    ]
    for i in range(offsets.size()):
        add_sphere(self, pos + offsets[i] * size,
            0.53 * size, pinks[i % pinks.size()])

func create_fighter(title: String, pos: Vector3,
        robe_color: Color, hair_color: Color) -> Node3D:
    var root := Node3D.new()
    root.name = title
    root.position = pos
    add_child(root)

    # Layered robe and shoulders.
    add_box(root, Vector3(0.92, 1.25, 0.48),
        Vector3(0, 1.0, 0), robe_color)
    add_box(root, Vector3(1.12, 0.24, 0.52),
        Vector3(0, 1.48, 0), robe_color.lightened(0.12))
    add_box(root, Vector3(0.62, 0.12, 0.55),
        Vector3(0, 0.42, 0), Color(0.75, 0.72, 0.68))

    # Arms and hands.
    for side in [-1.0, 1.0]:
        var arm := add_box(root, Vector3(0.23, 0.78, 0.25),
            Vector3(side * 0.59, 1.0, 0), robe_color)
        arm.rotation_degrees.z = side * -9.0
        add_sphere(root, Vector3(side * 0.62, 0.56, -0.02),
            0.13, Color(0.88, 0.67, 0.56))

    # Legs and boots.
    for side in [-1.0, 1.0]:
        add_box(root, Vector3(0.29, 0.65, 0.34),
            Vector3(side * 0.23, 0.22, 0), robe_color.darkened(0.25))
        add_box(root, Vector3(0.34, 0.14, 0.46),
            Vector3(side * 0.23, -0.12, -0.05),
            Color(0.045, 0.045, 0.065))

    # Head, hair and face details.
    add_sphere(root, Vector3(0, 1.91, 0), 0.30,
        Color(0.91, 0.70, 0.59))
    add_sphere(root, Vector3(0, 2.08, -0.04), 0.31, hair_color)
    for i in range(7):
        var hx := -0.24 + float(i) * 0.08
        var spike := add_box(root, Vector3(0.10, 0.32, 0.12),
            Vector3(hx, 2.28 + float(i % 2) * 0.06, -0.02),
            hair_color)
        spike.rotation_degrees.z = float(i - 3) * 11.0

    add_box(root, Vector3(0.34, 0.055, 0.035),
        Vector3(0, 1.98, 0.275), Color(0.08, 0.12, 0.2))
    for side in [-1.0, 1.0]:
        add_sphere(root, Vector3(side * 0.095, 1.99, 0.29),
            0.035, Color(0.95, 0.12, 0.12), true)

    # Long sword, guard and handle.
    var sword := add_box(root, Vector3(0.105, 1.45, 0.075),
        Vector3(0.65, 1.05, -0.04),
        Color(0.68, 0.86, 1.0), true)
    sword.name = "Sword"
    sword.rotation_degrees.z = -12.0
    add_box(root, Vector3(0.32, 0.075, 0.12),
        Vector3(0.65, 0.42, -0.04), Color(0.92, 0.64, 0.22))
    add_box(root, Vector3(0.10, 0.36, 0.12),
        Vector3(0.65, 0.21, -0.04), Color(0.18, 0.12, 0.1))

    return root

func create_camera() -> void:
    var cam := Camera3D.new()
    cam.name = "BattleCamera"
    cam.position = Vector3(0, 9.5, 15.5)
    cam.current = true
    cam.fov = 58.0
    add_child(cam)
    battle_camera = cam
    cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

func create_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    add_child(layer)

    var top := VBoxContainer.new()
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 14
    top.offset_top = 8
    top.offset_right = -14
    top.offset_bottom = 122
    top.add_theme_constant_override("separation", 3)
    layer.add_child(top)

    var title := Label.new()
    title.text = "SOUL WARRIORS 3D"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 21)
    top.add_child(title)

    player_bar = ProgressBar.new()
    player_bar.max_value = 100
    player_bar.show_percentage = false
    player_bar.custom_minimum_size = Vector2(0, 19)
    top.add_child(player_bar)

    enemy_bar = ProgressBar.new()
    enemy_bar.max_value = 100
    enemy_bar.show_percentage = false
    enemy_bar.custom_minimum_size = Vector2(0, 19)
    top.add_child(enemy_bar)

    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 14)
    top.add_child(status)

    message = Label.new()
    message.text = "FIGHT!"
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message.offset_left = -140
    message.offset_top = 126
    message.offset_right = 140
    message.offset_bottom = 158
    message.add_theme_font_size_override("font_size", 20)
    layer.add_child(message)

    var controls := HBoxContainer.new()
    controls.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    controls.offset_left = 8
    controls.offset_top = -78
    controls.offset_right = -8
    controls.offset_bottom = -8
    controls.add_theme_constant_override("separation", 5)
    layer.add_child(controls)

    add_button(controls, "BACK", func(): move_player(Vector3(0, 0, 1)))
    add_button(controls, "FORWARD", func(): move_player(Vector3(0, 0, -1)))
    add_button(controls, "LEFT", func(): move_player(Vector3(-1, 0, 0)))
    add_button(controls, "RIGHT", func(): move_player(Vector3(1, 0, 0)))
    add_button(controls, "SWORD", func(): attack(14))
    add_button(controls, "SPIRIT", energy_attack)
    add_button(controls, "RESET", reset_round)

func add_button(parent: HBoxContainer, label_text: String,
        action: Callable) -> void:
    var b := Button.new()
    b.text = label_text
    b.custom_minimum_size = Vector2(0, 58)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 13)
    b.pressed.connect(action)
    parent.add_child(b)

func move_player(direction: Vector3) -> void:
    if finished:
        return
    player.position += direction * 0.85
    player.position.x = clampf(player.position.x, -ARENA_LIMIT, ARENA_LIMIT)
    player.position.z = clampf(player.position.z, -ARENA_LIMIT, ARENA_LIMIT)
    face_each_other()

func face_each_other() -> void:
    if player and enemy:
        player.look_at(Vector3(enemy.position.x, player.position.y, enemy.position.z), Vector3.UP)
        enemy.look_at(Vector3(player.position.x, enemy.position.y, player.position.z), Vector3.UP)

func attack(damage: int) -> void:
    if finished or attack_cooldown > 0:
        return
    attack_cooldown = 0.45
    face_each_other()

    if player.position.distance_to(enemy.position) > 3.5:
        message.text = "TOO FAR!"
        return

    enemy_hp = maxi(0, enemy_hp - damage)
    message.text = "SWORD HIT!"
    show_effect(enemy.position, Color(0.12, 0.65, 1.0))
    update_ui()
    if enemy_hp <= 0:
        finish_round(true)

func energy_attack() -> void:
    if finished or energy_cooldown > 0:
        return
    energy_cooldown = 2.0

    if player.position.distance_to(enemy.position) > 7.0:
        message.text = "ENERGY MISSED!"
        return

    enemy_hp = maxi(0, enemy_hp - 24)
    message.text = "SPIRIT BLAST!"
    show_effect(enemy.position, Color(0.15, 0.55, 1.0))
    update_ui()
    if enemy_hp <= 0:
        finish_round(true)

func show_effect(pos: Vector3, color: Color) -> void:
    var orb := add_sphere(self, pos + Vector3(0, 1.2, 0), 0.4, color, true)
    var tween := create_tween()
    tween.tween_property(orb, "scale", Vector3(3.0, 3.0, 3.0), 0.24)
    tween.tween_callback(orb.queue_free)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    energy_cooldown = maxf(0.0, energy_cooldown - delta)
    enemy_cooldown = maxf(0.0, enemy_cooldown - delta)

    # Smooth third-person camera follow.
    if is_instance_valid(player) and is_instance_valid(battle_camera):
        var target_camera := player.global_position + Vector3(0, 9.5, 15.5)
        battle_camera.global_position = battle_camera.global_position.lerp(
            target_camera, clampf(delta * 3.0, 0.0, 1.0))
        battle_camera.look_at(
            player.global_position + Vector3(0, 1.0, -1.5), Vector3.UP)

    if finished or not is_instance_valid(player) or not is_instance_valid(enemy):
        return

    var distance := player.position.distance_to(enemy.position)
    if distance > 2.2:
        var direction := player.position - enemy.position
        direction.y = 0
        if direction.length() > 0.01:
            enemy.position += direction.normalized() * ENEMY_SPEED * delta
        enemy.position.x = clampf(enemy.position.x, -ARENA_LIMIT, ARENA_LIMIT)
        enemy.position.z = clampf(enemy.position.z, -ARENA_LIMIT, ARENA_LIMIT)
    elif enemy_cooldown <= 0.0:
        enemy_cooldown = 1.4
        player_hp = maxi(0, player_hp - 8)
        message.text = "ENEMY ATTACK!"
        show_effect(player.position, Color(1.0, 0.12, 0.2))
        update_ui()
        if player_hp <= 0:
            finish_round(false)

    face_each_other()

func update_ui() -> void:
    if is_instance_valid(player_bar):
        player_bar.value = player_hp
    if is_instance_valid(enemy_bar):
        enemy_bar.value = enemy_hp
    if is_instance_valid(status):
        status.text = "PLAYER: %d HP     HOLLOW: %d HP" % [player_hp, enemy_hp]

func finish_round(won: bool) -> void:
    finished = true
    message.text = "VICTORY!" if won else "DEFEAT!"
    update_ui()

func reset_round() -> void:
    player_hp = 100
    enemy_hp = 100
    enemy_cooldown = 0.0
    attack_cooldown = 0.0
    energy_cooldown = 0.0
    finished = false
    player.position = Vector3(-2, 0, 1)
    enemy.position = Vector3(2, 0, -1)
    message.text = "FIGHT!"
    face_each_other()
    update_ui()
