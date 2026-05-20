extends Node2D

const TILE := 48
const WORLD_W := 42
const WORLD_H := 30
const PLAYER_SPEED := 150.0
const CHARACTER_SHEETS: Dictionary = {
	"male": "res://assets/personagem_masculino.png",
	"female": "res://assets/personagem_feminina.png"
}

var hero_walk_sheet: Texture2D
var logo_texture: Texture2D = preload("res://assets/logo_simbora.png")
var picos_sign_texture: Texture2D = preload("res://assets/placa_picos.png")
var asphalt_texture: Texture2D = preload("res://assets/asfalto.png")
var selected_character := "male"
var character_buttons := {}

var player_pos := Vector2(27 * TILE, 18 * TILE)
var player_size := Vector2(30, 40)
var player_dir := "down"
var walk_time := 0.0
var hero_walk_frames := {
	"right": [],
	"left": [],
	"up": [],
	"down": []
}
var camera_pos := Vector2.ZERO
var running := false
var active_dialog := false
var active_mission = null
var touch_vector := Vector2.ZERO
var touch_buttons := {}

var solids := {}
var water := {}
var props := []
var learned := {}

var missions := []

var hud_layer: CanvasLayer
var start_layer: CanvasLayer
var dialog_panel: PanelContainer
var dialog_title: Label
var dialog_text: Label
var answer_box: VBoxContainer
var score_label: Label
var place_label: Label
var collection_panel: PanelContainer
var collection_list: VBoxContainer


func _ready() -> void:
	get_window().min_size = Vector2i(480, 270)
	load_character_sheet(selected_character)
	build_world()
	load_progress()
	build_ui()
	update_hud()
	set_process(true)


func _process(delta: float) -> void:
	if running and not active_dialog and not collection_panel.visible:
		update_player(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("open_collection"):
		toggle_collection()


func load_character_sheet(character_id: String) -> void:
	var sheet_path: String = String(CHARACTER_SHEETS.get(character_id, CHARACTER_SHEETS["male"]))
	hero_walk_sheet = load(sheet_path) as Texture2D


func select_character(character_id: String) -> void:
	selected_character = character_id
	load_character_sheet(character_id)
	update_character_selection()


func load_hero_walk_frames() -> void:
	var image := hero_walk_sheet.get_image()
	if image == null:
		return
	image.convert(Image.FORMAT_RGBA8)

	var frame_size := Vector2i(220, 300)
	var frame_x: Array[int] = [167, 409, 648, 887]
	var front_frames: Array[Rect2i] = []
	var left_frames: Array[Rect2i] = []
	var right_frames: Array[Rect2i] = []
	var back_frames: Array[Rect2i] = []
	for x in frame_x:
		front_frames.append(Rect2i(Vector2i(x, 70), frame_size))
		left_frames.append(Rect2i(Vector2i(x, 360), frame_size))
		right_frames.append(Rect2i(Vector2i(x, 640), frame_size))
		back_frames.append(Rect2i(Vector2i(x, 918), frame_size))

	hero_walk_frames["left"] = build_hero_frame_textures(image, left_frames)
	hero_walk_frames["right"] = build_hero_frame_textures(image, right_frames)
	hero_walk_frames["up"] = build_hero_frame_textures(image, back_frames)
	hero_walk_frames["down"] = build_hero_frame_textures(image, front_frames)


func build_hero_frame_textures(source: Image, frames: Array) -> Array:
	var textures: Array[Texture2D] = []
	for frame_rect in frames:
		var frame: Image = source.get_region(frame_rect)
		frame.convert(Image.FORMAT_RGBA8)
		var min_x := frame.get_width()
		var min_y := frame.get_height()
		var max_x := 0
		var max_y := 0
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var color := frame.get_pixel(x, y)
				var gray_delta := maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
				var is_gray_bg := color.r > 0.40 and color.r < 0.78 and color.g > 0.40 and color.g < 0.78 and color.b > 0.40 and color.b < 0.78 and gray_delta < 0.08
				if is_gray_bg:
					color.a = 0.0
					frame.set_pixel(x, y, color)
				elif color.a > 0.03:
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)
		if max_x >= min_x and max_y >= min_y:
			var pad := 3
			var sx := maxi(0, min_x - pad)
			var sy := maxi(0, min_y - pad)
			var sw := mini(frame.get_width() - sx, max_x - min_x + pad * 2)
			var sh := mini(frame.get_height() - sy, max_y - min_y + pad * 2)
			frame = frame.get_region(Rect2i(Vector2i(sx, sy), Vector2i(sw, sh)))

		var normalized := Image.create(96, 128, false, Image.FORMAT_RGBA8)
		normalized.fill(Color(0, 0, 0, 0))
		var max_draw := Vector2i(78, 118)
		var scale := minf(float(max_draw.x) / float(frame.get_width()), float(max_draw.y) / float(frame.get_height()))
		var fitted_size := Vector2i(maxi(1, roundi(frame.get_width() * scale)), maxi(1, roundi(frame.get_height() * scale)))
		frame.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
		var paste_pos := Vector2i((normalized.get_width() - fitted_size.x) / 2, normalized.get_height() - fitted_size.y)
		normalized.blit_rect(frame, Rect2i(Vector2i.ZERO, fitted_size), paste_pos)
		textures.append(ImageTexture.create_from_image(normalized))
	return textures


func build_world() -> void:
	for x in range(WORLD_W):
		add_solid(x, 0)
		add_solid(x, WORLD_H - 1)
	for y in range(WORLD_H):
		add_solid(0, y)
		add_solid(WORLD_W - 1, y)

	add_picos_block()
	clear_player_spawn_area()


func clear_player_spawn_area() -> void:
	var spawn_tile := Vector2i(roundi(player_pos.x / TILE), roundi(player_pos.y / TILE))
	for x in range(spawn_tile.x - 1, spawn_tile.x + 2):
		for y in range(spawn_tile.y - 1, spawn_tile.y + 3):
			solids.erase(tile_key(x, y))
	props = props.filter(func(prop):
		if not prop.has("tile"):
			return true
		var tile: Vector2i = prop["tile"]
		var near_spawn: bool = abs(tile.x - spawn_tile.x) <= 1 and abs(tile.y - spawn_tile.y) <= 2
		return not near_spawn
	)


func add_picos_block() -> void:
	props.append({"type": "picos_sign", "tile": Vector2i(13, 15)})
	props.append({"type": "church", "tile": Vector2i(27, 14)})
	for offset in [
		Vector2i(-9, -5), Vector2i(-5, -5), Vector2i(5, -5), Vector2i(9, -5),
		Vector2i(-9, 4), Vector2i(-5, 6), Vector2i(5, 6), Vector2i(9, 4),
		Vector2i(-3, -2), Vector2i(3, -2), Vector2i(-3, 4), Vector2i(3, 4)
	]:
		add_named_house(Vector2i(21, 15) + offset)
	for offset in [
		Vector2i(-7, -1), Vector2i(7, -1), Vector2i(-7, 7), Vector2i(7, 7),
		Vector2i(-1, -6), Vector2i(1, -6), Vector2i(-1, 7), Vector2i(1, 7)
	]:
		props.append({"type": "bush", "tile": Vector2i(21, 15) + offset})
	for x in range(25, 30):
		for y in range(13, 17):
			add_solid(x, y)


func add_named_house(tile: Vector2i) -> void:
	props.append({"type": "house", "tile": tile})
	add_solid(tile.x, tile.y)
	add_solid(tile.x + 1, tile.y)


func add_rock_cluster(sx: int, sy: int, w: int, h: int) -> void:
	for x in range(sx, sx + w):
		for y in range(sy, sy + h):
			if abs(x - (sx + w / 2.0)) + abs(y - (sy + h / 2.0)) < w / 1.6:
				props.append({"type": "rock", "tile": Vector2i(x, y)})
				add_solid(x, y)


func add_village(sx: int, sy: int) -> void:
	for offset in [Vector2i(0, 0), Vector2i(3, -1), Vector2i(5, 2)]:
		props.append({"type": "house", "tile": Vector2i(sx + offset.x, sy + offset.y)})
		add_solid(sx + offset.x, sy + offset.y)
		add_solid(sx + offset.x + 1, sy + offset.y)


func add_solid(x: int, y: int) -> void:
	solids[tile_key(x, y)] = true


func add_water(x: int, y: int) -> void:
	water[tile_key(x, y)] = true
	add_solid(x, y)


func tile_key(x: int, y: int) -> String:
	return "%s,%s" % [x, y]


func near_mission(x: int, y: int) -> bool:
	for mission in missions:
		var tile: Vector2i = mission["tile"]
		if abs(tile.x - x) < 2 and abs(tile.y - y) < 2:
			return true
	return false


func update_player(delta: float) -> void:
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move += touch_vector
	if touch_buttons.get("left", false):
		move.x -= 1
	if touch_buttons.get("right", false):
		move.x += 1
	if touch_buttons.get("up", false):
		move.y -= 1
	if touch_buttons.get("down", false):
		move.y += 1

	if move.length() > 1:
		move = move.normalized()

	if move.length() > 0:
		player_dir = "right" if abs(move.x) > abs(move.y) and move.x > 0 else player_dir
		player_dir = "left" if abs(move.x) > abs(move.y) and move.x < 0 else player_dir
		player_dir = "down" if abs(move.y) >= abs(move.x) and move.y > 0 else player_dir
		player_dir = "up" if abs(move.y) >= abs(move.x) and move.y < 0 else player_dir
		walk_time += delta * 9.0
		move_player(Vector2(move.x * PLAYER_SPEED * delta, 0))
		move_player(Vector2(0, move.y * PLAYER_SPEED * delta))
	else:
		walk_time = 0

	var viewport := get_viewport_rect().size
	var target := player_pos - viewport / 2.0
	camera_pos = camera_pos.lerp(target, 0.12)
	camera_pos.x = clamp(camera_pos.x, 0, WORLD_W * TILE - viewport.x)
	camera_pos.y = clamp(camera_pos.y, 0, WORLD_H * TILE - viewport.y)

	place_label.text = "Picos"


func move_player(delta_pos: Vector2) -> void:
	var next_pos := player_pos + delta_pos
	if not collides(next_pos):
		player_pos = next_pos


func collides(pos: Vector2) -> bool:
	var left := int(floor((pos.x - 12.0) / TILE))
	var right := int(floor((pos.x + 12.0) / TILE))
	var top := int(floor((pos.y + 8.0) / TILE))
	var bottom := int(floor((pos.y + 20.0) / TILE))
	for x in range(left, right + 1):
		for y in range(top, bottom + 1):
			if solids.has(tile_key(x, y)):
				return true
	return false


func nearest_mission():
	var best = null
	var best_dist := INF
	for mission in missions:
		var pos: Vector2 = Vector2(mission["tile"]) * TILE
		var dist := player_pos.distance_to(pos)
		if dist < best_dist:
			best = mission
			best_dist = dist
	if best_dist < 116:
		return best
	return null


func interact() -> void:
	if collection_panel.visible:
		return
	if active_dialog:
		close_dialog()
		return

	var mission = nearest_mission()
	if mission == null:
		show_dialog("Picos", "Explore a cidade livremente.", [])
		return
	if learned.has(mission["id"]):
		show_dialog(mission["name"], "%s Item já coletado: %s." % [mission["fact"], mission["item"]], [])
		return
	show_quiz(mission)


func show_quiz(mission) -> void:
	active_dialog = true
	active_mission = mission
	dialog_title.text = "%s - %s" % [mission["npc"], mission["name"]]
	dialog_text.text = mission["question"]
	clear_answers()
	for i in mission["options"].size():
		var button := make_button(mission["options"][i])
		button.pressed.connect(func(): answer_mission(mission, i))
		answer_box.add_child(button)
	dialog_panel.visible = true


func answer_mission(mission, index: int) -> void:
	if index == mission["answer"]:
		learned[mission["id"]] = true
		save_progress()
		update_hud()
		show_dialog("%s desbloqueado" % mission["item"], mission["fact"], [])
	else:
		show_dialog("Tente de novo", "Observe a paisagem e converse novamente. O conhecimento também é uma trilha.", [])


func show_dialog(title: String, text: String, _buttons: Array) -> void:
	active_dialog = true
	active_mission = null
	dialog_title.text = title
	dialog_text.text = text
	clear_answers()
	var button := make_button("Continuar")
	button.pressed.connect(close_dialog)
	answer_box.add_child(button)
	dialog_panel.visible = true


func close_dialog() -> void:
	active_dialog = false
	active_mission = null
	dialog_panel.visible = false


func toggle_collection() -> void:
	render_collection()
	collection_panel.visible = not collection_panel.visible


func clear_answers() -> void:
	for child in answer_box.get_children():
		child.queue_free()


func save_progress() -> void:
	var save := FileAccess.open("user://simbora_piaui.save", FileAccess.WRITE)
	save.store_var(learned)


func load_progress() -> void:
	if FileAccess.file_exists("user://simbora_piaui.save"):
		var save := FileAccess.open("user://simbora_piaui.save", FileAccess.READ)
		var data = save.get_var()
		if typeof(data) == TYPE_DICTIONARY:
			learned = data


func update_hud() -> void:
	if score_label:
		score_label.text = "Saberes %d/%d" % [learned.size(), missions.size()]
	render_collection()


func render_collection() -> void:
	if not collection_list:
		return
	for child in collection_list.get_children():
		child.queue_free()
	for mission in missions:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if learned.has(mission["id"]):
			label.text = "%s\n%s" % [mission["item"], mission["fact"]]
		else:
			label.text = "Item oculto\nExplore %s para desbloquear." % mission["name"]
		collection_list.add_child(label)


func build_ui() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var hud := HBoxContainer.new()
	hud.anchor_right = 1
	hud.offset_left = 10
	hud.offset_top = 10
	hud.offset_right = -10
	hud.add_theme_constant_override("separation", 10)
	hud_layer.add_child(hud)

	place_label = make_label("Picos", 16)
	score_label = make_label("Saberes 0/%d" % missions.size(), 16)
	hud.add_child(wrap_panel(place_label, Vector2(240, 40)))
	hud.add_spacer(false)
	hud.add_child(wrap_panel(score_label, Vector2(170, 40)))

	var bag_button := make_button("Mochila")
	bag_button.anchor_left = 1
	bag_button.anchor_right = 1
	bag_button.offset_left = -132
	bag_button.offset_top = 58
	bag_button.offset_right = -10
	bag_button.offset_bottom = 100
	bag_button.pressed.connect(toggle_collection)
	hud_layer.add_child(bag_button)

	build_dialog_ui()
	build_collection_ui()
	build_touch_ui()
	build_start_ui()


func build_start_ui() -> void:
	start_layer = CanvasLayer.new()
	add_child(start_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.08, 0.16, 0.82)
	shade.anchor_right = 1
	shade.anchor_bottom = 1
	start_layer.add_child(shade)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_top = 0.5
	box.anchor_right = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -330
	box.offset_top = -210
	box.offset_right = 330
	box.offset_bottom = 210
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	start_layer.add_child(box)

	var logo := TextureRect.new()
	logo.texture = logo_texture
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(620, 240)
	box.add_child(logo)

	var title := make_label("Uma jornada pelo Piauí", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var copy := make_label("Explore paisagens, converse com personagens e desbloqueie saberes sobre cultura, história, geografia e turismo piauiense.", 18)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(copy)

	character_buttons.clear()
	var wardrobe := make_character_card("wardrobe", "VESTIÁRIO")
	wardrobe.anchor_left = 1
	wardrobe.anchor_top = 1
	wardrobe.anchor_right = 1
	wardrobe.anchor_bottom = 1
	wardrobe.offset_left = -172
	wardrobe.offset_top = -190
	wardrobe.offset_right = -24
	wardrobe.offset_bottom = -24
	start_layer.add_child(wardrobe)
	update_character_selection()

	var start := make_button("Começar jornada")
	start.custom_minimum_size = Vector2(240, 50)
	start.pressed.connect(func():
		start_layer.visible = false
		running = true
	)
	box.add_child(start)


func make_character_card(character_id: String, label: String) -> Button:
	var button := make_button(label)
	button.custom_minimum_size = Vector2(148, 166)
	button.icon = make_character_preview_texture(selected_character)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.pressed.connect(toggle_character)
	character_buttons[character_id] = button
	return button


func make_character_preview_texture(character_id: String) -> Texture2D:
	var sheet_path: String = String(CHARACTER_SHEETS.get(character_id, CHARACTER_SHEETS["male"]))
	var sheet := load(sheet_path) as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = get_character_source_rect(character_id, "down", 0)
	return atlas


func get_character_source_rect(character_id: String, direction: String, frame_index: int) -> Rect2:
	var frame_sources_x: Array[int] = [167, 409, 648, 887]
	var frame_sources_y: Dictionary = {"down": 70, "left": 360, "right": 640, "up": 918}
	if character_id == "female":
		frame_sources_x = [160, 400, 638, 878]
		frame_sources_y = {"down": 38, "left": 330, "right": 625, "up": 900}
	var source_x: int = frame_sources_x[frame_index]
	var source_y: int = int(frame_sources_y.get(direction, frame_sources_y["down"]))
	return Rect2(Vector2(source_x, source_y), Vector2(220, 300))


func update_character_selection() -> void:
	for character_id in character_buttons:
		var button: Button = character_buttons[character_id]
		button.text = "VESTIÁRIO"
		button.icon = make_character_preview_texture(selected_character)
		button.modulate = Color.WHITE


func toggle_character() -> void:
	select_character("female" if selected_character == "male" else "male")


func build_dialog_ui() -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.visible = false
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_top = 1
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_bottom = 1
	dialog_panel.offset_left = -380
	dialog_panel.offset_top = -185
	dialog_panel.offset_right = 380
	dialog_panel.offset_bottom = -18
	hud_layer.add_child(dialog_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	dialog_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	dialog_title = make_label("", 18)
	dialog_title.add_theme_color_override("font_color", Color(1, 0.78, 0.28))
	box.add_child(dialog_title)

	dialog_text = make_label("", 16)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(dialog_text)

	answer_box = VBoxContainer.new()
	answer_box.add_theme_constant_override("separation", 8)
	box.add_child(answer_box)


func build_collection_ui() -> void:
	collection_panel = PanelContainer.new()
	collection_panel.visible = false
	collection_panel.anchor_left = 0.5
	collection_panel.anchor_top = 0.5
	collection_panel.anchor_right = 0.5
	collection_panel.anchor_bottom = 0.5
	collection_panel.offset_left = -360
	collection_panel.offset_top = -220
	collection_panel.offset_right = 360
	collection_panel.offset_bottom = 220
	hud_layer.add_child(collection_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	collection_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(make_label("Coleção Cultural", 24))
	row.add_spacer(false)
	var close := make_button("Fechar")
	close.pressed.connect(toggle_collection)
	row.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 330)
	box.add_child(scroll)
	collection_list = VBoxContainer.new()
	collection_list.add_theme_constant_override("separation", 12)
	scroll.add_child(collection_list)


func build_touch_ui() -> void:
	var dpad := GridContainer.new()
	dpad.columns = 3
	dpad.anchor_top = 1
	dpad.anchor_bottom = 1
	dpad.offset_left = 22
	dpad.offset_top = -144
	dpad.offset_right = 166
	dpad.offset_bottom = -18
	hud_layer.add_child(dpad)

	add_pad_space(dpad)
	add_touch_button(dpad, "up", "▲")
	add_pad_space(dpad)
	add_touch_button(dpad, "left", "◀")
	add_pad_space(dpad)
	add_touch_button(dpad, "right", "▶")
	add_pad_space(dpad)
	add_touch_button(dpad, "down", "▼")
	add_pad_space(dpad)

	var action := make_button("E")
	action.anchor_left = 1
	action.anchor_top = 1
	action.anchor_right = 1
	action.anchor_bottom = 1
	action.offset_left = -98
	action.offset_top = -100
	action.offset_right = -22
	action.offset_bottom = -24
	action.pressed.connect(interact)
	hud_layer.add_child(action)


func add_touch_button(parent: GridContainer, action_name: String, text: String) -> void:
	var button := make_button(text)
	button.custom_minimum_size = Vector2(48, 42)
	button.button_down.connect(func(): touch_buttons[action_name] = true)
	button.button_up.connect(func(): touch_buttons[action_name] = false)
	parent.add_child(button)


func add_pad_space(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(48, 42)
	parent.add_child(spacer)


func make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1, 0.97, 0.86))
	return label


func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	return button


func wrap_panel(child: Control, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	margin.add_child(child)
	return panel


func _draw() -> void:
	draw_ground()
	draw_paths()
	draw_church_plaza()
	draw_props()
	draw_missions()
	draw_player()
	draw_vignette()


func world_rect(tile: Vector2i) -> Rect2:
	return Rect2(Vector2(tile) * TILE - camera_pos, Vector2(TILE, TILE))


func world_pos(pos: Vector2) -> Vector2:
	return pos - camera_pos


func draw_ground() -> void:
	for x in range(WORLD_W):
		for y in range(WORLD_H):
			var key := tile_key(x, y)
			var dry := y > 20 or x > 26
			var fill := Color("#2a8fc1") if water.has(key) else (Color("#b9a05c") if dry else Color("#71ad5a"))
			var line := Color("#1e6e9d") if water.has(key) else (Color("#8f7d42") if dry else Color("#4d873f"))
			var rect := world_rect(Vector2i(x, y))
			draw_rect(rect, fill)
			draw_rect(rect.grow(-0.5), line, false, 1.0)
			if not water.has(key) and (x * 13 + y * 7) % 9 == 0:
				draw_rect(Rect2(rect.position + Vector2(9, 14), Vector2(6, 6)), Color("#93c46d") if not dry else Color("#d6bd75"))
				draw_rect(Rect2(rect.position + Vector2(28, 31), Vector2(5, 5)), Color("#93c46d") if not dry else Color("#d6bd75"))


func draw_paths() -> void:
	var points: Array[Vector2] = [
		Vector2(2, 16.5) * TILE,
		Vector2(15, 16.5) * TILE,
		Vector2(23, 16.5) * TILE,
		Vector2(31, 15) * TILE
	]
	for i in range(points.size() - 1):
		draw_line(world_pos(points[i]), world_pos(points[i + 1]), Color("#24282d"), 46)
		draw_line(world_pos(points[i]), world_pos(points[i + 1]), Color("#3d4144"), 40)
	draw_asphalt_texture_path(points)
	for i in range(points.size() - 1):
		var start := world_pos(points[i])
		var finish := world_pos(points[i + 1])
		var tangent := (finish - start).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		draw_line(start + normal * 17.0, finish + normal * 17.0, Color("#f0efdd"), 2)
		draw_line(start - normal * 17.0, finish - normal * 17.0, Color("#f0efdd"), 2)
	for i in range(1, points.size() * 4):
		var p: Vector2 = world_pos(Vector2(2 + i * 2.2, 16.5) * TILE)
		draw_rect(Rect2(p + Vector2(-10, -2), Vector2(20, 5)), Color("#efe8c9"))


func draw_asphalt_texture_path(points: Array[Vector2]) -> void:
	if asphalt_texture == null:
		return
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var steps: int = maxi(1, int(start.distance_to(finish) / (TILE * 0.55)))
		for step in range(steps + 1):
			var point: Vector2 = start.lerp(finish, step / float(steps))
			var pos: Vector2 = world_pos(point) - Vector2(TILE * 0.5, TILE * 0.5)
			draw_texture_rect(asphalt_texture, Rect2(pos, Vector2(TILE, TILE)), false)


func draw_church_plaza() -> void:
	for x in range(24, 31):
		for y in range(17, 21):
			var rect := world_rect(Vector2i(x, y))
			draw_rect(rect, Color("#cfc4a6"))
			draw_rect(rect.grow(-0.5), Color("#968c73"), false, 1.0)
			if (x + y) % 3 == 0:
				draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(5, 5)), Color(0.88, 0.84, 0.70, 0.55))
			if x % 3 == 0 and y % 2 == 0:
				draw_rect(Rect2(rect.position + Vector2(18, 18), Vector2(12, 12)), Color(0.76, 0.72, 0.60, 0.35), false, 1)
	var left_bench := world_pos(Vector2(24.5, 19.2) * TILE)
	var right_bench := world_pos(Vector2(29.0, 19.2) * TILE)
	draw_rect(Rect2(left_bench, Vector2(54, 8)), Color("#795033"))
	draw_rect(Rect2(left_bench + Vector2(6, 9), Vector2(5, 13)), Color("#4d3324"))
	draw_rect(Rect2(right_bench, Vector2(54, 8)), Color("#795033"))
	draw_rect(Rect2(right_bench + Vector2(43, 9), Vector2(5, 13)), Color("#4d3324"))


func draw_props() -> void:
	var sorted_props := props.duplicate()
	sorted_props.sort_custom(func(a, b): return a["tile"].y < b["tile"].y)
	for prop in sorted_props:
		var pos := Vector2(prop["tile"]) * TILE - camera_pos
		match prop["type"]:
			"palm":
				draw_palm(pos)
			"cactus":
				draw_cactus(pos)
			"bush":
				draw_bush(pos)
			"rock":
				draw_rock(pos)
			"house":
				draw_house(pos)
			"picos_sign":
				draw_picos_sign(pos)
			"church":
				draw_simple_church(pos)


func draw_palm(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(20, 18), Vector2(8, 30)), Color("#70482c"))
	for i in range(6):
		var angle := i * PI / 3.0
		draw_circle(pos + Vector2(24 + cos(angle) * 12, 17 + sin(angle) * 8), 13, Color("#226d3d"))


func draw_cactus(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(20, 12), Vector2(10, 34)), Color("#2f8148"))
	draw_rect(Rect2(pos + Vector2(12, 24), Vector2(10, 8)), Color("#2f8148"))
	draw_rect(Rect2(pos + Vector2(28, 20), Vector2(10, 8)), Color("#2f8148"))


func draw_bush(pos: Vector2) -> void:
	draw_circle(pos + Vector2(18, 30), 12, Color("#3f8739"))
	draw_circle(pos + Vector2(30, 28), 14, Color("#3f8739"))
	draw_circle(pos + Vector2(27, 37), 10, Color("#3f8739"))


func draw_rock(pos: Vector2) -> void:
	draw_colored_polygon([pos + Vector2(8, 38), pos + Vector2(19, 13), pos + Vector2(35, 8), pos + Vector2(44, 39)], Color("#916d55"))


func draw_house(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(5, 20), Vector2(78, 48)), Color("#bc7b43"))
	draw_colored_polygon([pos + Vector2(0, 22), pos + Vector2(44, -8), pos + Vector2(88, 22)], Color("#7b3c2b"))
	draw_rect(Rect2(pos + Vector2(39, 42), Vector2(14, 26)), Color("#29344c"))


func draw_picos_sign(pos: Vector2) -> void:
	if picos_sign_texture:
		var draw_w: float = 270.0
		var draw_h: float = draw_w * (picos_sign_texture.get_height() / float(picos_sign_texture.get_width()))
		draw_texture_rect(picos_sign_texture, Rect2(pos + Vector2(-82, -50), Vector2(draw_w, draw_h)), false)
		return
	draw_rect(Rect2(pos + Vector2(18, 34), Vector2(6, 42)), Color("#47301f"))
	draw_rect(Rect2(pos + Vector2(84, 34), Vector2(6, 42)), Color("#47301f"))
	draw_rect(Rect2(pos + Vector2(0, 0), Vector2(108, 42)), Color("#1f2428"))
	draw_rect(Rect2(pos + Vector2(4, 4), Vector2(100, 34)), Color("#30363a"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(22, 28), "PICOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd84a"))


func draw_simple_church(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-18, 12), Vector2(132, 72)), Color("#e9dfc8"))
	draw_rect(Rect2(pos + Vector2(28, -34), Vector2(38, 48)), Color("#d8cfbd"))
	draw_colored_polygon([pos + Vector2(-28, 16), pos + Vector2(48, -36), pos + Vector2(124, 16)], Color("#7d3b2b"))
	draw_circle(pos + Vector2(47, -10), 9, Color("#ffd84a"))
	draw_rect(Rect2(pos + Vector2(39, 52), Vector2(18, 32)), Color("#333942"))
	draw_rect(Rect2(pos + Vector2(5, 34), Vector2(18, 18)), Color("#8aa4b8"))
	draw_rect(Rect2(pos + Vector2(75, 34), Vector2(18, 18)), Color("#8aa4b8"))


func draw_missions() -> void:
	for mission in missions:
		var center := Vector2(mission["tile"]) * TILE - camera_pos
		draw_circle(center + Vector2(0, -34), 10 + sin(Time.get_ticks_msec() / 180.0) * 2.0, Color("#ffc247") if learned.has(mission["id"]) else Color("#fff7dc"))
		draw_npc(center, mission["id"])


func draw_npc(pos: Vector2, id: String) -> void:
	var palettes := {
		"museu_ozildo": [Color("#78442c"), Color("#f2d17a")],
		"igreja_picos": [Color("#54677c"), Color("#eef6ff")],
		"praca_ozildo": [Color("#3a8f57"), Color("#fff7dc")],
		"feira_picos": [Color("#a33e3e"), Color("#ffc247")],
		"guaribas": [Color("#1b6fa8"), Color("#ffd6a0")]
	}
	var palette = palettes[id]
	draw_rect(Rect2(pos + Vector2(-12, -34), Vector2(24, 14)), palette[1])
	draw_rect(Rect2(pos + Vector2(-14, -20), Vector2(28, 32)), palette[0])
	draw_rect(Rect2(pos + Vector2(-16, -38), Vector2(32, 7)), Color("#2a1a15"))


func draw_player() -> void:
	var moving := walk_time > 0.0
	var screen_pos := player_pos - camera_pos
	if hero_walk_sheet:
		var frame_index: int = int(floor(walk_time * 0.7)) % 4 if moving else 0
		var source: Rect2 = get_character_source_rect(selected_character, player_dir, frame_index)
		var draw_size: Vector2 = Vector2(66, 90)
		var target: Rect2 = Rect2(screen_pos + Vector2(-draw_size.x / 2.0, -draw_size.y + 18), draw_size)
		draw_texture_rect_region(hero_walk_sheet, target, source)
		return

	draw_rect(Rect2(screen_pos + Vector2(-14, -34), Vector2(28, 34)), Color("#d96b28"), true)
	draw_rect(Rect2(screen_pos + Vector2(-18, -48), Vector2(36, 12)), Color("#f2d17a"), true)


func draw_vignette() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0, 0, 0, 0.12), true)
