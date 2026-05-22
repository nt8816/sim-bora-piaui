extends Node2D

const TILE := 48
const WORLD_W := 66
const WORLD_H := 30
const PLAYER_SPEED := 150.0
const OPENING_MISSION_ID := "boas_vindas_picos"
const PHASE1_ACCEPTED_ID := "fase1_diario_aceita"
const PHASE1_DONE_ID := "fase1_diario_concluida"
const PAGE_FEIRA_ID := "pagina_diario_feira"
const PAGE_MUSEU_ID := "pagina_diario_museu"
const CHURCH_DRAW_W := 505.0
const CHURCH_BASE_OFFSET := Vector2(-198, 71)
const MENU_IMAGE_SIZE := Vector2(1694, 928)
const SEU_ZE_IDLE_COLUMNS := 5
const SEU_ZE_IDLE_ROWS := 8
const SEU_ZE_IDLE_FRAME_COUNT := 40
const SEU_ZE_IDLE_FRAME_SIZE := Vector2(96, 128)
const SEU_ZE_IDLE_FPS := 8.0
const SEU_ZE_FAN_COLUMNS := 11
const SEU_ZE_FAN_ROWS := 11
const SEU_ZE_FAN_FRAME_COUNT := 120
const SEU_ZE_FAN_LOOP_START_FRAME := 55
const SEU_ZE_FAN_FPS := 18.0
const SEU_ZE_FAN_CROP_X_RATIO := 430.0 / 1950.0
const SEU_ZE_FAN_CROP_WIDTH_RATIO := 1040.0 / 1950.0
const CHARACTER_SHEETS: Dictionary = {
	"male": "res://assets/personagem_masculino.png",
	"female": "res://assets/personagem_feminina.png"
}

var menu_texture: Texture2D
var menu_button_jogar_texture: Texture2D
var menu_button_opcoes_texture: Texture2D
var menu_button_marketplace_texture: Texture2D
var hero_walk_sheet: Texture2D
var logo_texture: Texture2D = preload("res://assets/logo_simbora.png")
var dynamic_dirt_texture: Texture2D = preload("res://assets/terra_dinamica.png")
var ozildo_plaza_texture: Texture2D = preload("res://assets/praca_ozildo_albano.jpeg")
var church_plaza_texture: Texture2D = preload("res://assets/praca_igreja_picos_hd.png")
var cactus_texture: Texture2D = preload("res://assets/cacto_pixel.png")
var museum_picos_texture: Texture2D = preload("res://assets/museu_picos.png")
var church_picos_texture: Texture2D = preload("res://assets/igreja_picos.png")
var picos_sign_texture: Texture2D = preload("res://assets/placa_picos.png")
var asphalt_texture: Texture2D = preload("res://assets/asfalto.png")
var asphalt_curve_texture: Texture2D = preload("res://assets/asfalto_curva.png")
var seu_ze_texture: Texture2D = preload("res://assets/seu_ze_lendas.png")
var seu_ze_idle_texture: Texture2D = preload("res://assets/seu_ze_idle_clean.png")
var seu_ze_fan_texture: Texture2D
var camera_texture: Texture2D = preload("res://assets/camera.png")
var memory_polaroid_texture: Texture2D = preload("res://assets/memoria_picos_polaroid.png")
var opening_music_stream: AudioStream = preload("res://assets/audio_abertura_picos.mp3")
var water_textures := [
	preload("res://assets/agua_rio_2.jpeg")
]

var future_trade_items := {
	"moeda_troca": preload("res://assets/moeda_troca.png"),
	"cabaca_troca": preload("res://assets/cabaca_troca.jpeg")
}

var tree_textures := {
	"aroeira": preload("res://assets/aroeira.png"),
	"buriti": preload("res://assets/buriti.png"),
	"malungu": preload("res://assets/malungu.png"),
	"manga": preload("res://assets/manga.png"),
	"manga_diferente": preload("res://assets/manga-diferente.png"),
	"umbu": preload("res://assets/umbu.png"),
	"ype": preload("res://assets/ype.png")
}
var tree_types := tree_textures.keys()
var tree_sprites := {}
var cactus_sprite := {}
var museum_picos_sprite := {}
var church_picos_sprite := {}
var asphalt_curve_sprite := {}
var camera_sprite := {}
var seu_ze_sprite := {}
var water_sprites := []
var hero_walk_frames := {
	"right": [],
	"left": [],
	"up": [],
	"down": []
}

var player_pos := Vector2(27 * TILE, 19 * TILE)
var player_size := Vector2(30, 40)
var player_dir := "down"
var walk_time := 0.0
var camera_pos := Vector2.ZERO
var opening_camera_x := 0.0
var opening_active := false
var opening_phase := "fade"
var opening_time := 0.0
var opening_player_x := -90.0
var opening_player_y := 0.0
var opening_memory_open := false
var opening_ze_ready := false
var opening_camera_collected := false
var opening_script_active := false
var opening_script_index := 0
var phase1_reward_active := false
var phase1_reward_index := 0
var opening_hint := "Toque no ícone para registrar sua primeira memória!"
var opening_flash := 0.0
var seu_ze_fan_started_msec := -1
var seu_ze_fan_intro_done := false
var opening_music_player: AudioStreamPlayer
var camera_sound_player: AudioStreamPlayer
var running := false
var active_dialog := false
var active_mission = null
var touch_vector := Vector2.ZERO
var touch_buttons := {}
var current_speed := PLAYER_SPEED
var settings := {
	"music_volume": 70.0,
	"sfx_volume": 80.0,
	"difficulty": "normal",
	"touch_controls": true,
	"fullscreen": false,
	"outfit": "explorador",
	"character": "male"
}
var redeemed := {}
var outfits := {
	"explorador": {"name": "Explorador", "color": Color("#d96b28"), "description": "Camisa laranja clássica da jornada."},
	"rio": {"name": "Azul de Picos", "color": Color("#1b79b5"), "description": "Azul inspirado na cidade."},
	"serra": {"name": "Caatinga de Picos", "color": Color("#2f8b4f"), "description": "Verde para trilhas e paisagens do município."},
	"festa": {"name": "Festa Popular", "color": Color("#c7333f"), "description": "Vermelho vivo para a cultura popular."}
}

var solids := {}
var solid_rects: Array[Rect2] = []
var church_collision_image: Image
var water := {}
var plaza_tiles := {}
var picos_tiles := {}
var road_tiles := {}
var props := []
var learned := {}

var missions := []
var opening_mission := {
	"id": OPENING_MISSION_ID,
	"name": "Bem-vindo a Picos",
	"npc": "Seu Zé das Lendas",
	"item": "Primeira Memória",
	"fact": "Você sabia? Picos é um dos maiores entroncamentos rodoviários do Nordeste e é famosa nacionalmente como a Capital do Mel!"
}
var opening_script_lines := [
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Opa, meu jovem! Seja muito bem-vindo à nossa querida Picos! Está sentindo esse cheirinho doce no ar? Não é à toa que nos chamam de a Capital do Mel."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Aproveite a sombra aqui da nossa imponente Igreja Matriz. Ela é o coração da cidade há muitas gerações. Eu venho aqui todos os dias anotar as histórias que os mais velhos contam."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Mas hoje o vento soprou forte demais! Uma ventania daquelas espalhou as páginas do meu Diário das Raízes por toda a cidade."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Eu já não tenho as pernas tão rápidas quanto as suas. Você poderia me ajudar a recuperar essas páginas? Uma voou para a Feira Livre e outra foi parar perto do Museu Ozildo Albano."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Se você trouxer as páginas, eu compartilho os segredos escritos nelas e te dou um item especial para ajudar na jornada pelo Piauí. O que me diz? SIM-BORA?"
	}
]
var phase1_reward_lines := [
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Ah, meu jovem, você encontrou as páginas! Agora o Diário das Raízes pode respirar de novo."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Aqui está o segredo: Picos cresceu como ponto de encontro, de passagem e de trabalho. Das estradas ao mel, muita gente ajudou a construir essa história."
	},
	{
		"speaker": "Seu Zé das Lendas",
		"text": "Receba este Marcador de Memórias. Ele vai lembrar você de olhar para cada canto com atenção. Fase 1 concluída!"
	}
]

var hud_layer: CanvasLayer
var start_layer: CanvasLayer
var dialog_panel: PanelContainer
var dialog_title: Label
var dialog_text: Label
var answer_box: VBoxContainer
var dialog_full_text := ""
var dialog_type_time := 0.0
var dialog_typewriter_done := true
var typewriter_font: Font
var score_label: Label
var place_label: Label
var hint_label: Label
var hint_panel: PanelContainer
var bag_button: Button
var collection_panel: PanelContainer
var collection_list: VBoxContainer
var menu_modal: PanelContainer
var menu_modal_title: Label
var menu_modal_body: VBoxContainer
var memory_continue_button: Button
var touch_ui: Control
var menu_root: Control
var menu_hitbox_buttons := []
var menu_highlights := []
var character_buttons := {}
var picos_district_tile := Vector2i(40, 15)
var ozildo_museum_tile := Vector2i(31, 20)
var ozildo_plaza_tile := Vector2i(26, 18)
var ozildo_plaza_size := Vector2i(12, 8)
var picos_church_tile := Vector2i(33, 9)
var picos_church_plaza_tile := Vector2i(17, 5)
var picos_church_plaza_size := Vector2i(34, 22)
var picos_church_plaza_art_tile := Vector2i(18, 12)
var picos_church_plaza_art_size := Vector2i(30, 12)


func _ready() -> void:
	get_window().min_size = Vector2i(480, 270)
	load_tree_sprites()
	load_special_sprites()
	load_menu_assets()
	build_world()
	load_progress()
	opening_active = not learned.has(OPENING_MISSION_ID)
	if opening_active:
		setup_opening_spawn()
	load_settings()
	load_character_sheet(String(settings.get("character", "male")))
	build_audio_players()
	build_ui()
	apply_settings()
	update_hud()
	set_process(true)


func _process(delta: float) -> void:
	update_dialog_typewriter(delta)
	if running and not active_dialog and not collection_panel.visible:
		if opening_active:
			update_opening(delta)
		else:
			update_player(delta)
	if start_layer and start_layer.visible:
		update_menu_selection_animation()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if opening_active and event is InputEventMouseButton and event.pressed:
		if handle_opening_pointer(event.position):
			return
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("open_collection"):
		toggle_collection()


func build_audio_players() -> void:
	opening_music_player = AudioStreamPlayer.new()
	opening_music_player.stream = opening_music_stream
	opening_music_player.bus = "Master"
	opening_music_player.finished.connect(loop_opening_music)
	add_child(opening_music_player)

	camera_sound_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.12
	camera_sound_player.stream = generator
	camera_sound_player.bus = "Master"
	add_child(camera_sound_player)


func loop_opening_music() -> void:
	if opening_music_player:
		opening_music_player.play()


func load_menu_assets() -> void:
	menu_texture = load_png_texture("res://assets/menu_inicial_limpa.png")
	menu_button_jogar_texture = load_png_texture("res://assets/botao_jogar.png")
	menu_button_opcoes_texture = load_png_texture("res://assets/botao_opcoes.png")
	menu_button_marketplace_texture = load_png_texture("res://assets/botao_marketplace.png")


func load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func load_character_sheet(character_id: String) -> void:
	var sheet_path: String = String(CHARACTER_SHEETS.get(character_id, CHARACTER_SHEETS["male"]))
	hero_walk_sheet = load(sheet_path) as Texture2D


func select_character(character_id: String) -> void:
	settings["character"] = character_id
	load_character_sheet(character_id)
	save_settings()
	update_character_selection()

func build_world() -> void:
	for x in range(WORLD_W):
		add_solid(x, 0)
		add_solid(x, WORLD_H - 1)
	for y in range(WORLD_H):
		add_solid(0, y)
		add_solid(WORLD_W - 1, y)

	add_picos_district(picos_district_tile.x, picos_district_tile.y)
	clear_player_spawn_area()


func clear_player_spawn_area() -> void:
	var spawn_tile := Vector2i(roundi(player_pos.x / TILE), roundi(player_pos.y / TILE))
	for x in range(spawn_tile.x - 1, spawn_tile.x + 2):
		for y in range(spawn_tile.y - 1, spawn_tile.y + 3):
			solids.erase(tile_key(x, y))
			plaza_tiles[tile_key(x, y)] = true
	props = props.filter(func(prop):
		if not prop.has("tile"):
			return true
		var tile: Vector2i = prop["tile"]
		var near_spawn: bool = abs(tile.x - spawn_tile.x) <= 1 and abs(tile.y - spawn_tile.y) <= 2
		return not near_spawn
	)


func add_natural_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260513
	var clusters := [
		Vector2i(4, 7), Vector2i(7, 21), Vector2i(13, 5), Vector2i(14, 25),
		Vector2i(21, 11), Vector2i(25, 24), Vector2i(32, 11), Vector2i(36, 18)
	]

	for cluster_index in range(clusters.size()):
		var center: Vector2i = clusters[cluster_index]
		for attempt in range(18):
			var offset := Vector2i(rng.randi_range(-4, 4), rng.randi_range(-3, 3))
			var tile := center + offset
			if can_place_vegetation(tile):
				var type = tree_types[(cluster_index + attempt) % tree_types.size()]
				props.append({"type": type, "tile": tile})

	for i in range(80):
		var tile := Vector2i(rng.randi_range(2, WORLD_W - 3), rng.randi_range(2, WORLD_H - 3))
		if can_place_vegetation(tile):
			if i % 5 == 0 and not near_path_tile(tile, 1.4):
				props.append({"type": "cactus", "tile": tile})
				add_solid(tile.x, tile.y)
			else:
				props.append({"type": "bush", "tile": tile})


func add_rivers() -> void:
	add_river_path([
		Vector2(1, 5), Vector2(4, 4), Vector2(8, 5), Vector2(12, 3), Vector2(15, 4)
	], 1)
	add_river_path([
		Vector2(27, 3), Vector2(31, 4), Vector2(35, 3), Vector2(40, 5)
	], 2)
	add_river_path([
		Vector2(26, 27), Vector2(29, 25), Vector2(31, 23), Vector2(33, 21)
	], 1)


func add_river_path(points: Array, radius: int) -> void:
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var steps := maxi(1, int(start.distance_to(finish) * 3.0))
		for step in range(steps + 1):
			var pos := start.lerp(finish, step / float(steps))
			var tile := Vector2i(roundi(pos.x), roundi(pos.y))
			for ox in range(-radius, radius + 1):
				for oy in range(-radius, radius + 1):
					if abs(ox) + abs(oy) <= radius + 1:
						var tx := tile.x + ox
						var ty := tile.y + oy
						if tx > 0 and ty > 0 and tx < WORLD_W - 1 and ty < WORLD_H - 1:
							add_water(tx, ty)


func can_place_vegetation(tile: Vector2i) -> bool:
	if tile.x <= 1 or tile.y <= 1 or tile.x >= WORLD_W - 2 or tile.y >= WORLD_H - 2:
		return false
	if solids.has(tile_key(tile.x, tile.y)):
		return false
	if plaza_tiles.has(tile_key(tile.x, tile.y)) or picos_tiles.has(tile_key(tile.x, tile.y)):
		return false
	if near_mission(tile.x, tile.y):
		return false
	if Vector2(tile).distance_to(player_pos / TILE) < 4.0:
		return false
	if near_path_tile(tile, 1.25):
		return false
	for prop in props:
		if prop.has("tile"):
			var other: Vector2i = prop["tile"]
			if Vector2(other).distance_to(Vector2(tile)) < 1.45:
				return false
	return true


func near_path_tile(tile: Vector2i, radius: float) -> bool:
	var center := (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
	for point in get_path_samples():
		if center.distance_to(point) < radius * TILE:
			return true
	return false


func load_tree_sprites() -> void:
	for type in tree_textures:
		var texture: Texture2D = tree_textures[type]
		var image := texture.get_image()
		if image == null:
			continue

		var min_x := image.get_width()
		var min_y := image.get_height()
		var max_x := 0
		var max_y := 0

		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				var is_white_background := color.r > 0.96 and color.g > 0.96 and color.b > 0.96
				if is_white_background:
					color.a = 0.0
					image.set_pixel(x, y, color)
				elif color.a > 0.03:
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)

		var pad := 4
		var sx := maxi(0, min_x - pad)
		var sy := maxi(0, min_y - pad)
		var sw := mini(image.get_width() - sx, max_x - min_x + pad * 2)
		var sh := mini(image.get_height() - sy, max_y - min_y + pad * 2)
		tree_sprites[type] = {
			"texture": ImageTexture.create_from_image(image),
			"region": Rect2(Vector2(sx, sy), Vector2(sw, sh))
		}


func load_special_sprites() -> void:
	cactus_sprite = make_clean_sprite(cactus_texture, true)
	museum_picos_sprite = make_clean_sprite(museum_picos_texture, true)
	church_picos_sprite = make_clean_sprite(church_picos_texture, true)
	if not church_picos_sprite.is_empty():
		church_collision_image = church_picos_sprite["texture"].get_image()
	asphalt_curve_sprite = make_clean_sprite(asphalt_curve_texture, true)
	camera_sprite = make_clean_sprite(camera_texture, true)
	seu_ze_fan_texture = load_png_texture("res://assets/seu_ze_abanando_120.png")
	seu_ze_sprite = make_clean_sprite(seu_ze_texture, true)
	water_sprites.clear()
	for texture in water_textures:
		water_sprites.append(make_clean_sprite(texture, true))


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
				var is_checker_bg := color.r > 0.42 and color.r < 0.82 and color.g > 0.42 and color.g < 0.82 and color.b > 0.42 and color.b < 0.82 and gray_delta < 0.10
				if is_checker_bg:
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


func make_clean_sprite(texture: Texture2D, erase_white_background: bool) -> Dictionary:
	var image := texture.get_image()
	if image == null:
		return {}
	image.convert(Image.FORMAT_RGBA8)

	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := 0
	var max_y := 0

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var is_white_background := erase_white_background and color.r > 0.96 and color.g > 0.96 and color.b > 0.96
			if is_white_background:
				color.a = 0.0
				image.set_pixel(x, y, color)
			elif color.a > 0.03:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return {
			"texture": texture,
			"region": Rect2(Vector2.ZERO, Vector2(texture.get_width(), texture.get_height()))
		}

	var pad := 4
	var sx := maxi(0, min_x - pad)
	var sy := maxi(0, min_y - pad)
	var sw := mini(image.get_width() - sx, max_x - min_x + pad * 2)
	var sh := mini(image.get_height() - sy, max_y - min_y + pad * 2)
	return {
		"texture": ImageTexture.create_from_image(image),
		"region": Rect2(Vector2(sx, sy), Vector2(sw, sh))
	}


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


func add_picos_district(sx: int, sy: int) -> void:
	for x in range(sx - 12, WORLD_W - 1):
		for y in range(sy - 9, sy + 11):
			if x > 1 and y > 1 and x < WORLD_W - 1 and y < WORLD_H - 1:
				picos_tiles[tile_key(x, y)] = true
				if x >= sx - 9 and x <= sx + 6 and y >= sy - 3 and y <= sy + 6:
					plaza_tiles[tile_key(x, y)] = true

	for x in range(ozildo_plaza_tile.x, ozildo_plaza_tile.x + ozildo_plaza_size.x):
		for y in range(ozildo_plaza_tile.y, ozildo_plaza_tile.y + ozildo_plaza_size.y):
			plaza_tiles[tile_key(x, y)] = true

	for x in range(picos_church_plaza_tile.x, picos_church_plaza_tile.x + picos_church_plaza_size.x):
		for y in range(picos_church_plaza_tile.y, picos_church_plaza_tile.y + picos_church_plaza_size.y):
			plaza_tiles[tile_key(x, y)] = true
			road_tiles.erase(tile_key(x, y))

	for data in [
		{"offset": Vector2i(-11, -6), "variant": 2},
		{"offset": Vector2i(-7, -5), "variant": 0},
		{"offset": Vector2i(-3, -6), "variant": 1},
		{"offset": Vector2i(3, -6), "variant": 2},
		{"offset": Vector2i(7, -4), "variant": 1},
		{"offset": Vector2i(-11, 3), "variant": 1},
		{"offset": Vector2i(-7, 4), "variant": 2},
		{"offset": Vector2i(7, 4), "variant": 0},
		{"offset": Vector2i(10, -1), "variant": 2},
		{"offset": Vector2i(10, 5), "variant": 0}
	]:
		var tile: Vector2i = Vector2i(sx, sy) + data["offset"]
		props.append({"type": "city_building", "tile": tile, "variant": data["variant"]})
		add_city_solid(tile)

	for offset in [Vector2i(-5, 0), Vector2i(5, 0), Vector2i(-5, 5), Vector2i(5, 5), Vector2i(9, 1)]:
		props.append({"type": "street_lamp", "tile": Vector2i(sx, sy) + offset})
	for offset in [Vector2i(-12, 5), Vector2i(-8, 5), Vector2i(-3, 5), Vector2i(3, 5), Vector2i(8, -3)]:
		props.append({"type": "city_bench", "tile": Vector2i(sx, sy) + offset})

	var picos_sign_tile := Vector2i(sx - 31, sy + 8)
	props.append({"type": "picos_sign", "tile": picos_sign_tile})
	add_picos_sign_collision(picos_sign_tile)
	add_picos_market(sx - 11, sy + 6)
	add_picos_church(picos_church_tile.x, picos_church_tile.y)
	add_picos_museum(ozildo_museum_tile.x, ozildo_museum_tile.y)
	add_phase1_diary_pages()
	clear_church_plaza_props()
	add_church_collision(picos_church_tile.x, picos_church_tile.y)


func clear_church_plaza_props() -> void:
	for x in range(picos_church_plaza_tile.x, picos_church_plaza_tile.x + picos_church_plaza_size.x):
		for y in range(picos_church_plaza_tile.y, picos_church_plaza_tile.y + picos_church_plaza_size.y):
			solids.erase(tile_key(x, y))
			road_tiles.erase(tile_key(x, y))
			plaza_tiles[tile_key(x, y)] = true
	props = props.filter(func(prop):
		if not prop.has("tile"):
			return true
		var tile: Vector2i = prop["tile"]
		var inside_plaza: bool = tile.x >= picos_church_plaza_tile.x and tile.x < picos_church_plaza_tile.x + picos_church_plaza_size.x and tile.y >= picos_church_plaza_tile.y and tile.y < picos_church_plaza_tile.y + picos_church_plaza_size.y
		var keep_landmark: bool = prop.get("type", "") in ["church_picos", "picos_sign", "museum_picos"]
		return keep_landmark or not inside_plaza
	)


func add_city_solid(tile: Vector2i) -> void:
	for x in range(tile.x, tile.x + 2):
		for y in range(tile.y, tile.y + 2):
			add_solid(x, y)


func add_picos_sign_collision(tile: Vector2i) -> void:
	var pos := Vector2(tile) * TILE
	if picos_sign_texture:
		var draw_w := 500.0
		var draw_h := draw_w * (picos_sign_texture.get_height() / float(picos_sign_texture.get_width()))
		var target := Rect2(pos + Vector2(-200, -80), Vector2(draw_w, draw_h))
		# Keep the road edge usable while blocking the actual sign, base, and garden art.
		solid_rects.append(Rect2(target.position + Vector2(34, 34), Vector2(target.size.x - 68, target.size.y - 58)))
	else:
		solid_rects.append(Rect2(pos + Vector2(0, 0), Vector2(108, 78)))


func add_picos_museum(sx: int, sy: int) -> void:
	props.append({"type": "museum_picos", "tile": Vector2i(sx, sy)})
	for x in range(ozildo_plaza_tile.x, ozildo_plaza_tile.x + ozildo_plaza_size.x):
		for y in range(ozildo_plaza_tile.y, ozildo_plaza_tile.y + ozildo_plaza_size.y):
			plaza_tiles[tile_key(x, y)] = true
			road_tiles.erase(tile_key(x, y))
	for x in range(sx - 4, sx + 6):
		for y in range(sy - 2, sy + 4):
			add_solid(x, y)


func add_picos_church(sx: int, sy: int) -> void:
	props.append({"type": "church_picos", "tile": Vector2i(sx, sy)})


func add_church_collision(sx: int, sy: int) -> void:
	# The church uses pixel-mask collision in collides_church_sprite().
	return


func add_picos_market(sx: int, sy: int) -> void:
	for row in range(2):
		for col in range(4):
			var tile := Vector2i(sx + col * 2, sy + row * 2)
			props.append({"type": "market_stall", "tile": tile, "variant": (row + col) % 4})
			add_solid(tile.x, tile.y)
	for offset in [Vector2i(-1, 0), Vector2i(8, 0), Vector2i(-1, 3), Vector2i(8, 3), Vector2i(3, -1)]:
		props.append({"type": "produce_crate", "tile": Vector2i(sx, sy) + offset, "variant": abs(offset.x + offset.y) % 3})


func add_phase1_diary_pages() -> void:
	missions.append({
		"id": PAGE_FEIRA_ID,
		"name": "Página na Feira Livre",
		"npc": "Diário das Raízes",
		"item": "Página da Feira Livre",
		"fact": "A Feira Livre de Picos guarda encontros, trabalho e sabores que ajudam a contar a economia e a vida cotidiana da cidade.",
		"tile": Vector2i(picos_district_tile.x - 12, picos_district_tile.y + 11),
		"type": "diary_page",
		"requires": PHASE1_ACCEPTED_ID
	})
	missions.append({
		"id": PAGE_MUSEU_ID,
		"name": "Página no Museu Ozildo Albano",
		"npc": "Diário das Raízes",
		"item": "Página do Museu",
		"fact": "O Museu Ozildo Albano preserva memórias, objetos e registros que ajudam a cidade a reconhecer sua própria história.",
		"tile": ozildo_museum_tile + Vector2i(1, 4),
		"type": "diary_page",
		"requires": PHASE1_ACCEPTED_ID
	})


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


func setup_opening_spawn() -> void:
	opening_phase = "fade"
	opening_time = 0.0
	opening_memory_open = false
	opening_ze_ready = false
	opening_camera_collected = false
	opening_script_active = false
	opening_script_index = 0
	phase1_reward_active = false
	phase1_reward_index = 0
	opening_flash = 0.0
	seu_ze_fan_started_msec = -1
	seu_ze_fan_intro_done = false
	opening_hint = "Toque no ícone para registrar sua primeira memória!"
	update_memory_continue_button()
	player_pos = get_opening_spawn_pos()
	player_dir = "right"
	walk_time = 0.0
	var viewport := get_viewport_rect().size
	camera_pos = player_pos - viewport / 2.0
	camera_pos.x = clampf(camera_pos.x, 0.0, WORLD_W * TILE - viewport.x)
	camera_pos.y = clampf(camera_pos.y, 0.0, WORLD_H * TILE - viewport.y)


func get_opening_spawn_pos() -> Vector2:
	# Primeiro ponto jogável da estrada principal, antes do letreiro de Picos aparecer ao centro da tela.
	return Vector2(2.4 * TILE, 26.5 * TILE)


func get_opening_camera_pos() -> Vector2:
	return get_opening_spawn_pos() + Vector2(138, -8)


func get_seu_ze_pos() -> Vector2:
	return Vector2(picos_church_tile) * TILE + Vector2(140, 132)


func update_opening(delta: float) -> void:
	opening_time += delta
	opening_flash = maxf(0.0, opening_flash - delta * 3.2)
	if opening_memory_open:
		return

	if opening_phase == "fade":
		player_dir = "right"
		walk_time = 0.0
		if opening_time >= 1.25:
			opening_phase = "photo"
			opening_time = 0.0
			opening_hint = "Pegue a câmera no caminho para registrar sua primeira memória."
	elif opening_phase in ["photo", "walk", "meet"]:
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
			move_player(Vector2(move.x * current_speed * delta, 0))
			move_player(Vector2(0, move.y * current_speed * delta))
		else:
			walk_time = 0.0

		if opening_phase == "photo":
			var near_camera := player_pos.distance_to(get_opening_camera_pos()) < 58.0
			opening_hint = "Aperte F para pegar a câmera." if near_camera else "Pegue a câmera no caminho."
		else:
			opening_ze_ready = player_pos.distance_to(get_seu_ze_pos()) < 125.0
			opening_phase = "meet" if opening_ze_ready else "walk"
			opening_hint = "Aperte F para falar com Seu Zé." if opening_ze_ready else "Siga a trilha das abelhas até a porta direita da igreja."

	var viewport := get_viewport_rect().size
	var target := player_pos - viewport / 2.0
	camera_pos = camera_pos.lerp(target, 0.12)
	camera_pos.x = clampf(camera_pos.x, 0.0, WORLD_W * TILE - viewport.x)
	camera_pos.y = clampf(camera_pos.y, 0.0, WORLD_H * TILE - viewport.y)
	place_label.text = "Picos"
	if hint_label:
		hint_label.visible = false
	if hint_panel:
		hint_panel.visible = false

func handle_opening_pointer(screen_pos: Vector2) -> bool:
	if opening_memory_open:
		return false
	if opening_phase == "photo" and get_opening_camera_collect_rect().has_point(screen_pos):
		collect_opening_camera()
		return true
	return false


func interact_opening() -> void:
	if active_dialog:
		advance_or_close_dialog()
		return
	if opening_memory_open:
		return
	if opening_phase == "photo":
		if player_pos.distance_to(get_opening_camera_pos()) < 58.0:
			collect_opening_camera()
		else:
			opening_hint = "Chegue mais perto da câmera para pegar."
		return
	if opening_phase == "meet" and opening_ze_ready:
		start_opening_script()


func collect_opening_camera() -> void:
	opening_camera_collected = true
	take_opening_photo()


func take_opening_photo() -> void:
	opening_memory_open = true
	opening_flash = 1.0
	opening_hint = "Nova Memória adicionada ao Diário de Bordo!"
	play_camera_sound()
	update_touch_controls_visibility()
	update_memory_continue_button()


func close_opening_memory() -> void:
	opening_memory_open = false
	opening_phase = "walk"
	opening_time = 0.0
	opening_hint = "Use as setas ou arraste o dedo para caminhar e explorar a cidade."
	update_touch_controls_visibility()
	update_memory_continue_button()


func play_camera_sound() -> void:
	if not camera_sound_player:
		return
	camera_sound_player.play()
	var playback := camera_sound_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	playback.clear_buffer()
	var frames := 2205
	for i in range(frames):
		var t := float(i) / 22050.0
		var env := maxf(0.0, 1.0 - t / 0.10)
		var wave := 0.16 * env * (1.0 if sin(TAU * 720.0 * t) >= 0.0 else -1.0)
		playback.push_frame(Vector2(wave, wave))


func get_opening_ground_y() -> float:
	return maxf(365.0, get_viewport_rect().size.y * 0.72)


func get_camera_icon_rect() -> Rect2:
	var viewport := get_viewport_rect().size
	var player_screen := player_pos - camera_pos
	var x := clampf(player_screen.x + 18.0, 18.0, viewport.x - 90.0)
	var y := clampf(player_screen.y - 148.0, 70.0, viewport.y - 170.0)
	return Rect2(Vector2(x, y), Vector2(70, 62))


func get_opening_camera_collect_rect() -> Rect2:
	return Rect2(get_opening_camera_pos() - camera_pos + Vector2(-28, -46), Vector2(56, 52))


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
		move_player(Vector2(move.x * current_speed * delta, 0))
		move_player(Vector2(0, move.y * current_speed * delta))
	else:
		walk_time = 0

	var viewport := get_viewport_rect().size
	var target := player_pos - viewport / 2.0
	camera_pos = camera_pos.lerp(target, 0.12)
	camera_pos.x = clamp(camera_pos.x, 0, WORLD_W * TILE - viewport.x)
	camera_pos.y = clamp(camera_pos.y, 0, WORLD_H * TILE - viewport.y)

	place_label.text = "Picos"
	if hint_label:
		hint_label.visible = false
	if hint_panel:
		hint_panel.visible = false


func move_player(delta_pos: Vector2) -> void:
	var next_pos := player_pos + delta_pos
	if not collides(next_pos):
		player_pos = next_pos


func collides(pos: Vector2) -> bool:
	var actor_rect := Rect2(pos + Vector2(-12.0, 8.0), Vector2(24.0, 12.0))
	if collides_church_sprite(actor_rect):
		return true
	for rect in solid_rects:
		if actor_rect.intersects(rect):
			return true
	var left := int(floor((pos.x - 12.0) / TILE))
	var right := int(floor((pos.x + 12.0) / TILE))
	var top := int(floor((pos.y + 8.0) / TILE))
	var bottom := int(floor((pos.y + 20.0) / TILE))
	for x in range(left, right + 1):
		for y in range(top, bottom + 1):
			if solids.has(tile_key(x, y)):
				return true
	return false


func collides_church_sprite(actor_rect: Rect2) -> bool:
	if church_picos_sprite.is_empty() or church_collision_image == null:
		return false
	var church_pos := Vector2(picos_church_tile) * TILE
	var region: Rect2 = church_picos_sprite["region"]
	var draw_w := CHURCH_DRAW_W
	var draw_h := draw_w * (region.size.y / region.size.x)
	var target := Rect2(church_pos + Vector2(CHURCH_BASE_OFFSET.x, CHURCH_BASE_OFFSET.y - draw_h), Vector2(draw_w, draw_h))
	for ix in range(3):
		for iy in range(2):
			var point := actor_rect.position + Vector2(actor_rect.size.x * ix / 2.0, actor_rect.size.y * iy)
			if not target.has_point(point):
				continue
			var uv := Vector2((point.x - target.position.x) / target.size.x, (point.y - target.position.y) / target.size.y)
			var px := clampi(int(region.position.x + uv.x * region.size.x), 0, church_collision_image.get_width() - 1)
			var py := clampi(int(region.position.y + uv.y * region.size.y), 0, church_collision_image.get_height() - 1)
			if church_collision_image.get_pixel(px, py).a > 0.08:
				return true
	return false


func nearest_mission() -> Variant:
	var best: Variant = null
	var best_dist := INF
	for mission in missions:
		if mission.has("requires") and not learned.has(mission["requires"]):
			continue
		var pos: Vector2 = Vector2(mission["tile"]) * TILE
		var dist := player_pos.distance_to(pos)
		if dist < best_dist:
			best = mission
			best_dist = dist
	if best_dist < 116:
		return best
	return null


func near_seu_ze() -> bool:
	return player_pos.distance_to(get_seu_ze_pos()) < 125.0


func interact() -> void:
	if collection_panel.visible:
		return
	if opening_active:
		interact_opening()
		return
	if active_dialog:
		advance_or_close_dialog()
		return
	if near_seu_ze():
		interact_seu_ze_phase1()
		return

	var mission: Variant = nearest_mission()
	if mission == null:
		show_dialog("Picos", "Explore a cidade livremente.", [])
		return
	if learned.has(mission["id"]):
		show_dialog(mission["name"], "%s Item já coletado: %s." % [mission["fact"], mission["item"]], [])
		return
	if String(mission.get("type", "")) == "diary_page":
		collect_diary_page(mission)
		return
	show_mission_intro(mission)


func collect_diary_page(mission: Dictionary) -> void:
	learned[mission["id"]] = true
	save_progress()
	update_hud()
	show_dialog(mission["item"], "%s\n\nLeve esta página de volta para Seu Zé quando encontrar todas." % mission["fact"], [])


func interact_seu_ze_phase1() -> void:
	if not learned.has(PHASE1_ACCEPTED_ID):
		start_opening_script()
		return
	if learned.has(PHASE1_DONE_ID):
		show_dialog("Seu Zé das Lendas", "Você já recuperou o Diário das Raízes. Agora siga olhando Picos com carinho: cada canto ainda tem história para contar.", [])
		return
	if has_all_phase1_pages():
		start_phase1_reward()
		return
	show_dialog("Seu Zé das Lendas", "A Feira Livre costuma ser bem movimentada; procure com atenção por lá! A outra página deve estar perto do Museu Ozildo Albano.", [])


func has_all_phase1_pages() -> bool:
	return learned.has(PAGE_FEIRA_ID) and learned.has(PAGE_MUSEU_ID)


func show_mission_intro(mission: Dictionary) -> void:
	active_mission = mission
	clear_answers()
	var start := make_button("Iniciar desafio")
	start.pressed.connect(func(): show_quiz(mission))
	answer_box.add_child(start)
	open_dialog("Missão - %s" % mission["name"], "Objetivo: %s\n\nO que fazer: leia a pista cultural e responda ao desafio para desbloquear o item \"%s\"." % [mission["objective"], mission["item"]])


func show_quiz(mission: Dictionary) -> void:
	active_mission = mission
	clear_answers()
	for i in range(mission["options"].size()):
		var button := make_button(mission["options"][i])
		button.pressed.connect(func(): answer_mission(mission, i))
		answer_box.add_child(button)
	open_dialog("%s - %s" % [mission["npc"], mission["name"]], mission["question"])


func answer_mission(mission: Dictionary, index: int) -> void:
	if index == mission["answer"]:
		learned[mission["id"]] = true
		save_progress()
		update_hud()
		show_dialog("%s desbloqueado" % mission["item"], mission["fact"], [])
	else:
		show_dialog("Tente de novo", "Observe a paisagem e converse novamente. O conhecimento também é uma trilha.", [])


func show_dialog(title: String, text: String, _buttons: Array) -> void:
	active_mission = null
	clear_answers()
	var button := make_button("Continuar")
	button.pressed.connect(close_dialog)
	answer_box.add_child(button)
	open_dialog(title, text)


func start_opening_script() -> void:
	opening_script_active = true
	opening_script_index = 0
	show_opening_script_line()


func show_opening_script_line() -> void:
	if opening_script_index >= opening_script_lines.size():
		finish_opening_script()
		return
	var line: Dictionary = opening_script_lines[opening_script_index]
	clear_answers()
	var button := make_button("Continuar")
	button.pressed.connect(advance_opening_script)
	answer_box.add_child(button)
	open_dialog(String(line["speaker"]), String(line["text"]))


func advance_opening_script() -> void:
	if not dialog_typewriter_done:
		dialog_typewriter_done = true
		dialog_text.visible_characters = -1
		answer_box.visible = true
		return
	opening_script_index += 1
	show_opening_script_line()


func finish_opening_script() -> void:
	opening_script_active = false
	close_dialog()
	learned[OPENING_MISSION_ID] = true
	learned[PHASE1_ACCEPTED_ID] = true
	save_progress()
	update_hud()
	opening_active = false
	show_dialog("Missão aceita", "Objetivo: recuperar as páginas do Diário das Raízes na Feira Livre e perto do Museu Ozildo Albano.", [])


func start_phase1_reward() -> void:
	phase1_reward_active = true
	phase1_reward_index = 0
	show_phase1_reward_line()


func show_phase1_reward_line() -> void:
	if phase1_reward_index >= phase1_reward_lines.size():
		finish_phase1_reward()
		return
	var line: Dictionary = phase1_reward_lines[phase1_reward_index]
	clear_answers()
	var button := make_button("Continuar")
	button.pressed.connect(advance_phase1_reward)
	answer_box.add_child(button)
	open_dialog(String(line["speaker"]), String(line["text"]))


func advance_phase1_reward() -> void:
	if not dialog_typewriter_done:
		dialog_typewriter_done = true
		dialog_text.visible_characters = -1
		answer_box.visible = true
		return
	phase1_reward_index += 1
	show_phase1_reward_line()


func finish_phase1_reward() -> void:
	phase1_reward_active = false
	close_dialog()
	learned[PHASE1_DONE_ID] = true
	save_progress()
	update_hud()
	show_dialog("Marcador de Memórias desbloqueado", "Item especial recebido: Marcador de Memórias. Caminho liberado para a próxima fase.", [])


func open_dialog(title: String, text: String) -> void:
	active_dialog = true
	dialog_title.text = title
	dialog_full_text = text
	dialog_type_time = 0.0
	dialog_typewriter_done = false
	dialog_text.text = dialog_full_text
	dialog_text.visible_characters = 0
	answer_box.visible = false
	dialog_panel.visible = true
	update_touch_controls_visibility()


func update_dialog_typewriter(delta: float) -> void:
	if not active_dialog or dialog_typewriter_done:
		return
	dialog_type_time += delta
	var target_chars := int(floor(dialog_type_time * 42.0))
	dialog_text.visible_characters = clampi(target_chars, 0, dialog_full_text.length())
	if dialog_text.visible_characters >= dialog_full_text.length():
		dialog_typewriter_done = true
		dialog_text.visible_characters = -1
		answer_box.visible = true


func close_dialog() -> void:
	active_dialog = false
	active_mission = null
	dialog_typewriter_done = true
	dialog_text.visible_characters = -1
	answer_box.visible = true
	dialog_panel.visible = false
	update_touch_controls_visibility()


func advance_or_close_dialog() -> void:
	if opening_script_active:
		advance_opening_script()
		return
	if phase1_reward_active:
		advance_phase1_reward()
		return
	if not dialog_typewriter_done:
		dialog_typewriter_done = true
		dialog_text.visible_characters = -1
		answer_box.visible = true
		return
	close_dialog()


func toggle_collection() -> void:
	render_collection()
	collection_panel.visible = not collection_panel.visible
	if bag_button:
		bag_button.text = "Fechar" if collection_panel.visible else "Mochila"
	update_touch_controls_visibility()


func clear_answers() -> void:
	for child in answer_box.get_children():
		child.queue_free()


func save_progress() -> void:
	var save := FileAccess.open("user://simbora_piaui.save", FileAccess.WRITE)
	save.store_var(learned)
	save.store_var(redeemed)


func load_progress() -> void:
	if FileAccess.file_exists("user://simbora_piaui.save"):
		var save := FileAccess.open("user://simbora_piaui.save", FileAccess.READ)
		var data = save.get_var()
		if typeof(data) == TYPE_DICTIONARY:
			learned = data
		if save.get_position() < save.get_length():
			var redeemed_data = save.get_var()
			if typeof(redeemed_data) == TYPE_DICTIONARY:
				redeemed = redeemed_data


func save_settings() -> void:
	var save := FileAccess.open("user://simbora_settings.save", FileAccess.WRITE)
	save.store_var(settings)


func load_settings() -> void:
	if not FileAccess.file_exists("user://simbora_settings.save"):
		return
	var save := FileAccess.open("user://simbora_settings.save", FileAccess.READ)
	var data = save.get_var()
	if typeof(data) != TYPE_DICTIONARY:
		return
	for key in data:
		if settings.has(key):
			settings[key] = data[key]


func apply_settings() -> void:
	match String(settings["difficulty"]):
		"easy":
			current_speed = 130.0
		"hard":
			current_speed = 172.0
		_:
			current_speed = PLAYER_SPEED
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(maxf(float(settings["music_volume"]) / 100.0, 0.001)))
	if camera_sound_player:
		camera_sound_player.volume_db = linear_to_db(maxf(float(settings["sfx_volume"]) / 100.0, 0.001))
	update_touch_controls_visibility()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings["fullscreen"]) else DisplayServer.WINDOW_MODE_MAXIMIZED)


func update_touch_controls_visibility() -> void:
	if not touch_ui:
		return
	touch_ui.visible = bool(settings["touch_controls"]) and running and not active_dialog and not opening_memory_open and not collection_panel.visible
	if not touch_ui.visible:
		touch_vector = Vector2.ZERO
		touch_buttons.clear()


func update_memory_continue_button() -> void:
	if memory_continue_button:
		memory_continue_button.visible = opening_memory_open
	if bag_button:
		bag_button.visible = not opening_memory_open


func update_hud() -> void:
	if score_label:
		score_label.text = "Saberes %d/%d" % [get_learned_count(), get_total_missions()]
	render_collection()


func get_total_missions() -> int:
	return missions.size() + 1


func get_learned_count() -> int:
	var count := missions.filter(func(mission): return learned.has(mission["id"])).size()
	if learned.has(OPENING_MISSION_ID):
		count += 1
	return count


func render_collection() -> void:
	if not collection_list:
		return
	for child in collection_list.get_children():
		child.queue_free()
	var opening_label := Label.new()
	opening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if learned.has(OPENING_MISSION_ID):
		opening_label.text = "%s\n%s" % [opening_mission["item"], opening_mission["fact"]]
	else:
		opening_label.text = "Item oculto\nExplore %s para desbloquear." % opening_mission["name"]
	collection_list.add_child(opening_label)
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
	hud_layer.layer = 10
	add_child(hud_layer)

	var hud := HBoxContainer.new()
	hud.anchor_right = 1
	hud.offset_left = 10
	hud.offset_top = 10
	hud.offset_right = -10
	hud.add_theme_constant_override("separation", 10)
	hud_layer.add_child(hud)

	place_label = make_label("Picos", 16)
	score_label = make_label("Saberes 0/%d" % get_total_missions(), 16)
	hud.add_child(wrap_panel(place_label, Vector2(240, 40)))
	hud.add_spacer(false)
	hud.add_child(wrap_panel(score_label, Vector2(170, 40)))

	hint_label = make_label("", 16)
	hint_label.visible = false
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel = wrap_panel(hint_label, Vector2(520, 42))
	hint_panel.visible = false
	hint_panel.anchor_left = 0.5
	hint_panel.anchor_top = 1
	hint_panel.anchor_right = 0.5
	hint_panel.anchor_bottom = 1
	hint_panel.offset_left = -260
	hint_panel.offset_top = -78
	hint_panel.offset_right = 260
	hint_panel.offset_bottom = -36
	hud_layer.add_child(hint_panel)

	bag_button = make_button("Mochila")
	bag_button.anchor_left = 1
	bag_button.anchor_right = 1
	bag_button.offset_left = -148
	bag_button.offset_top = 58
	bag_button.offset_right = -10
	bag_button.offset_bottom = 104
	apply_gold_button_style(bag_button, 15)
	bag_button.pressed.connect(toggle_collection)
	hud_layer.add_child(bag_button)

	build_dialog_ui()
	build_collection_ui()
	build_touch_ui()
	build_memory_continue_ui()
	build_start_ui()
	build_menu_modal()


func build_start_ui() -> void:
	start_layer = CanvasLayer.new()
	start_layer.layer = 20
	add_child(start_layer)

	menu_root = Control.new()
	menu_root.anchor_right = 1
	menu_root.anchor_bottom = 1
	menu_root.resized.connect(update_menu_hitboxes)
	start_layer.add_child(menu_root)

	var background := TextureRect.new()
	background.texture = menu_texture
	background.anchor_right = 1
	background.anchor_bottom = 1
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(background)

	create_menu_image_button(Rect2(631, 424, 432, 134), menu_button_jogar_texture, func(button: Button): start_journey(button))
	create_menu_image_button(Rect2(622, 544, 451, 93), menu_button_opcoes_texture, func(_button: Button): show_options_menu())
	create_menu_image_button(Rect2(584, 629, 525, 116), menu_button_marketplace_texture, func(_button: Button): show_marketplace_menu())
	create_character_selector()
	update_menu_hitboxes()


func create_character_selector() -> void:
	character_buttons.clear()
	var button := make_character_card("wardrobe", "VESTIÁRIO")
	button.anchor_left = 1
	button.anchor_top = 1
	button.anchor_right = 1
	button.anchor_bottom = 1
	button.offset_left = -172
	button.offset_top = -190
	button.offset_right = -24
	button.offset_bottom = -24
	menu_root.add_child(button)
	update_character_selection()


func make_character_card(character_id: String, label: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(148, 166)
	button.text = label
	button.icon = make_character_preview_texture(String(settings.get("character", "male")))
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.focus_mode = Control.FOCUS_ALL
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
	var selected := String(settings.get("character", "male"))
	for character_id in character_buttons:
		var button: Button = character_buttons[character_id]
		button.text = "VESTIÁRIO"
		button.icon = make_character_preview_texture(selected)
		button.modulate = Color.WHITE


func toggle_character() -> void:
	var selected := String(settings.get("character", "male"))
	select_character("female" if selected == "male" else "male")


func create_menu_image_button(source_rect: Rect2, texture: Texture2D, callback: Callable) -> void:
	var highlight := Panel.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.visible = false
	highlight.modulate = Color(1, 1, 1, 0)
	highlight.add_theme_stylebox_override("panel", make_menu_selection_style())
	menu_root.add_child(highlight)
	menu_highlights.append(highlight)

	var button := Button.new()
	button.text = ""
	button.icon = texture
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	button.add_theme_stylebox_override("normal", make_transparent_button_style())
	button.add_theme_stylebox_override("hover", make_transparent_button_style())
	button.add_theme_stylebox_override("pressed", make_transparent_button_style())
	button.set_meta("source_rect", source_rect)
	button.set_meta("highlight", highlight)
	button.set_meta("selected", false)
	button.mouse_entered.connect(func(): set_menu_button_selected(button, true))
	button.mouse_exited.connect(func(): set_menu_button_selected(button, false))
	button.focus_entered.connect(func(): set_menu_button_selected(button, true))
	button.focus_exited.connect(func(): set_menu_button_selected(button, false))
	button.button_down.connect(func(): set_menu_button_pressed(button, true))
	button.button_up.connect(func(): set_menu_button_pressed(button, false))
	button.pressed.connect(func(): callback.call(button))
	menu_root.add_child(button)
	menu_hitbox_buttons.append(button)


func update_menu_hitboxes() -> void:
	if not menu_root:
		return
	var viewport_size := menu_root.size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var scale := maxf(viewport_size.x / MENU_IMAGE_SIZE.x, viewport_size.y / MENU_IMAGE_SIZE.y)
	var drawn_size := MENU_IMAGE_SIZE * scale
	var offset := (viewport_size - drawn_size) * 0.5
	for button in menu_hitbox_buttons:
		var source_rect: Rect2 = button.get_meta("source_rect")
		button.position = offset + source_rect.position * scale
		button.size = source_rect.size * scale
		var highlight: Panel = button.get_meta("highlight")
		highlight.position = button.position - Vector2(8, 8) * scale
		highlight.size = button.size + Vector2(16, 16) * scale
		highlight.pivot_offset = highlight.size / 2.0


func set_menu_button_selected(button: Button, selected: bool) -> void:
	button.set_meta("selected", selected)
	var highlight: Panel = button.get_meta("highlight")
	highlight.visible = selected
	if not selected:
		highlight.modulate = Color(1, 1, 1, 0)
		highlight.scale = Vector2.ONE


func set_menu_button_pressed(button: Button, pressed: bool) -> void:
	var highlight: Panel = button.get_meta("highlight")
	highlight.visible = true
	highlight.scale = Vector2(0.985, 0.985) if pressed else Vector2.ONE
	highlight.modulate = Color(1, 0.86, 0.32, 0.95 if pressed else 0.72)


func update_menu_selection_animation() -> void:
	var pulse := (sin(Time.get_ticks_msec() / 135.0) + 1.0) * 0.5
	for button in menu_hitbox_buttons:
		if not bool(button.get_meta("selected")):
			continue
		var highlight: Panel = button.get_meta("highlight")
		highlight.visible = true
		highlight.modulate = Color(1, 0.88, 0.35, 0.48 + pulse * 0.34)
		var grow := 1.0 + pulse * 0.018
		highlight.scale = Vector2(grow, grow)


func start_journey(button: Button = null) -> void:
	if running:
		return
	if button:
		button.disabled = true
	close_menu_modal()
	start_layer.visible = false
	if opening_active:
		setup_opening_spawn()
	running = true
	if opening_music_player and not opening_music_player.playing:
		opening_music_player.play()
	hint_label.visible = false
	if hint_panel:
		hint_panel.visible = false
	update_touch_controls_visibility()


func build_menu_modal() -> void:
	menu_modal = PanelContainer.new()
	menu_modal.visible = false
	menu_modal.anchor_left = 0.5
	menu_modal.anchor_top = 0.5
	menu_modal.anchor_right = 0.5
	menu_modal.anchor_bottom = 0.5
	menu_modal.offset_left = -360
	menu_modal.offset_top = -230
	menu_modal.offset_right = 360
	menu_modal.offset_bottom = 230
	menu_modal.add_theme_stylebox_override("panel", make_panel_style(Color(0.23, 0.11, 0.055, 0.97), Color("#ffc247")))
	start_layer.add_child(menu_modal)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	menu_modal.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	menu_modal_title = make_label("", 26)
	menu_modal_title.add_theme_color_override("font_color", Color("#ffc247"))
	header.add_child(menu_modal_title)
	header.add_spacer(false)
	var close := make_button("Fechar")
	close.pressed.connect(close_menu_modal)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 350)
	box.add_child(scroll)
	menu_modal_body = VBoxContainer.new()
	menu_modal_body.add_theme_constant_override("separation", 10)
	scroll.add_child(menu_modal_body)


func open_menu_modal(title: String) -> void:
	menu_modal_title.text = title
	for child in menu_modal_body.get_children():
		child.queue_free()
	menu_modal.visible = true


func close_menu_modal() -> void:
	if menu_modal:
		menu_modal.visible = false


func show_options_menu() -> void:
	open_menu_modal("Opções")
	add_slider_setting("Volume da música", "music_volume", 0, 100)
	add_slider_setting("Volume dos efeitos", "sfx_volume", 0, 100)
	add_option_setting("Dificuldade", "difficulty", {"Fácil": "easy", "Normal": "normal", "Difícil": "hard"})
	add_check_setting("Controles de toque", "touch_controls")
	add_check_setting("Tela cheia", "fullscreen")

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	menu_modal_body.add_child(actions)
	var reset := make_button("Zerar progresso")
	reset.pressed.connect(func():
		learned.clear()
		redeemed.clear()
		opening_active = true
		setup_opening_spawn()
		save_progress()
		update_hud()
	)
	actions.add_child(reset)
	var defaults := make_button("Padrão")
	defaults.pressed.connect(func():
		settings["music_volume"] = 70.0
		settings["sfx_volume"] = 80.0
		settings["difficulty"] = "normal"
		settings["touch_controls"] = true
		settings["fullscreen"] = false
		save_settings()
		apply_settings()
		show_options_menu()
	)
	actions.add_child(defaults)


func add_slider_setting(title: String, key: String, min_value: float, max_value: float) -> void:
	var row := make_setting_row(title, "%d%%" % int(settings[key]))
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1
	slider.value = float(settings[key])
	slider.custom_minimum_size = Vector2(260, 34)
	slider.value_changed.connect(func(value: float):
		settings[key] = value
		row.get_child(0).get_child(1).text = "%d%%" % int(value)
		save_settings()
		apply_settings()
	)
	row.add_child(slider)


func add_option_setting(title: String, key: String, options: Dictionary) -> void:
	var row := make_setting_row(title, "Configuração padrão de jogo.")
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(180, 40)
	var index := 0
	var selected := 0
	for label in options:
		option.add_item(label)
		option.set_item_metadata(index, options[label])
		if options[label] == settings[key]:
			selected = index
		index += 1
	option.selected = selected
	option.item_selected.connect(func(item_index: int):
		settings[key] = option.get_item_metadata(item_index)
		save_settings()
		apply_settings()
	)
	row.add_child(option)


func add_check_setting(title: String, key: String) -> void:
	var row := make_setting_row(title, "Ligado/desligado.")
	var check := CheckButton.new()
	check.button_pressed = bool(settings[key])
	check.toggled.connect(func(pressed: bool):
		settings[key] = pressed
		save_settings()
		apply_settings()
	)
	row.add_child(check)


func make_setting_row(title: String, description: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	menu_modal_body.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var label := make_label(title, 18)
	label.add_theme_color_override("font_color", Color("#ffe6a7"))
	text_box.add_child(label)
	var detail := make_label(description, 14)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(detail)
	return row


func show_marketplace_menu() -> void:
	open_menu_modal("Marketplace")
	var products := [
		{"id": "mapa", "name": "Mapa dos Parques", "description": "Mostra melhor os pontos culturais no HUD.", "cost": 1},
		{"id": "caderno", "name": "Caderno de Campo", "description": "Organiza os saberes desbloqueados na mochila.", "cost": 3},
		{"id": "passe", "name": "Passe Urbano", "description": "Libera itens cosméticos no vestiário.", "cost": 5}
	]
	for product in products:
		var item_id := String(product["id"])
		var item_name := String(product["name"])
		var item_cost := int(product["cost"])
		var row := make_setting_row(item_name, "%s Custo: %d saber(es)." % [product["description"], item_cost])
		var button := make_button("Resgatado" if redeemed.has(item_id) else ("Resgatar" if learned.size() >= item_cost else "Bloqueado"))
		button.disabled = redeemed.has(item_id)
		button.pressed.connect(func(): redeem_market_item(item_id, item_cost, item_name))
		row.add_child(button)
	menu_modal_body.add_child(make_label("Saberes disponíveis: %d/%d" % [learned.size(), missions.size()], 16))


func redeem_market_item(item_id: String, cost: int, item_name: String) -> void:
	if learned.size() < cost:
		menu_modal_body.add_child(make_label("Faltam %d saber(es) para %s." % [cost - learned.size(), item_name], 16))
		return
	redeemed[item_id] = true
	save_progress()
	show_marketplace_menu()


func show_wardrobe_menu() -> void:
	open_menu_modal("Vestiário")
	for outfit_id in outfits:
		var current_outfit_id: String = outfit_id
		var outfit: Dictionary = outfits[outfit_id]
		var row := make_setting_row(outfit["name"], outfit["description"])
		var swatch := ColorRect.new()
		swatch.color = outfit["color"]
		swatch.custom_minimum_size = Vector2(42, 42)
		row.add_child(swatch)
		var button := make_button("Usando" if settings["outfit"] == current_outfit_id else "Usar")
		button.disabled = settings["outfit"] == current_outfit_id
		button.pressed.connect(func(): select_outfit(current_outfit_id))
		row.add_child(button)


func select_outfit(outfit_id: String) -> void:
	settings["outfit"] = outfit_id
	save_settings()
	show_wardrobe_menu()


func build_dialog_ui() -> void:
	typewriter_font = make_typewriter_font()
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
	dialog_title.add_theme_font_override("font", typewriter_font)
	dialog_title.add_theme_color_override("font_color", Color(1, 0.78, 0.28))
	box.add_child(dialog_title)

	dialog_text = make_label("", 16)
	dialog_text.add_theme_font_override("font", typewriter_font)
	dialog_text.add_theme_constant_override("line_spacing", 4)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(dialog_text)

	answer_box = VBoxContainer.new()
	answer_box.add_theme_constant_override("separation", 8)
	box.add_child(answer_box)


func make_typewriter_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["monospace", "Courier New", "Courier", "DejaVu Sans Mono"])
	return font


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
	touch_ui = Control.new()
	touch_ui.anchor_right = 1
	touch_ui.anchor_bottom = 1
	hud_layer.add_child(touch_ui)

	var dpad := GridContainer.new()
	dpad.columns = 3
	dpad.anchor_top = 1
	dpad.anchor_bottom = 1
	dpad.offset_left = 22
	dpad.offset_top = -166
	dpad.offset_right = 184
	dpad.offset_bottom = -18
	dpad.add_theme_constant_override("h_separation", 5)
	dpad.add_theme_constant_override("v_separation", 5)
	touch_ui.add_child(dpad)

	add_pad_space(dpad)
	add_touch_button(dpad, "up", "▲")
	add_pad_space(dpad)
	add_touch_button(dpad, "left", "◀")
	add_pad_space(dpad)
	add_touch_button(dpad, "right", "▶")
	add_pad_space(dpad)
	add_touch_button(dpad, "down", "▼")
	add_pad_space(dpad)

	var action := make_button("F")
	action.anchor_left = 1
	action.anchor_top = 1
	action.anchor_right = 1
	action.anchor_bottom = 1
	action.offset_left = -104
	action.offset_top = -106
	action.offset_right = -22
	action.offset_bottom = -24
	apply_action_button_style(action)
	action.pressed.connect(interact)
	touch_ui.add_child(action)


func build_memory_continue_ui() -> void:
	memory_continue_button = make_button("Continuar")
	memory_continue_button.visible = false
	memory_continue_button.anchor_left = 1
	memory_continue_button.anchor_top = 1
	memory_continue_button.anchor_right = 1
	memory_continue_button.anchor_bottom = 1
	memory_continue_button.offset_left = -168
	memory_continue_button.offset_top = -72
	memory_continue_button.offset_right = -28
	memory_continue_button.offset_bottom = -24
	apply_gold_button_style(memory_continue_button, 18)
	memory_continue_button.pressed.connect(close_opening_memory)
	hud_layer.add_child(memory_continue_button)


func add_touch_button(parent: GridContainer, action_name: String, text: String) -> void:
	var button := make_button(text)
	button.custom_minimum_size = Vector2(50, 50)
	apply_touch_button_style(button)
	button.button_down.connect(func(): touch_buttons[action_name] = true)
	button.button_up.connect(func(): touch_buttons[action_name] = false)
	parent.add_child(button)


func add_pad_space(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(50, 50)
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


func apply_gold_button_style(button: Button, font_size: int = 16) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#241306"))
	button.add_theme_color_override("font_hover_color", Color("#241306"))
	button.add_theme_color_override("font_pressed_color", Color("#fff7dc"))
	button.add_theme_stylebox_override("normal", make_button_style(Color("#ffc247"), Color("#6b3d21"), 8, Vector2(0, 5)))
	button.add_theme_stylebox_override("hover", make_button_style(Color("#ffd778"), Color("#fff0b5"), 8, Vector2(0, 5)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color("#9b5b26"), Color("#3a1c11"), 8, Vector2(0, 2)))


func apply_touch_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#fff7dc"))
	button.add_theme_color_override("font_hover_color", Color("#fff7dc"))
	button.add_theme_color_override("font_pressed_color", Color("#241306"))
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.16, 0.12, 0.09, 0.78), Color("#f1c96c"), 8, Vector2(0, 4)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.23, 0.17, 0.12, 0.86), Color("#fff0b5"), 8, Vector2(0, 4)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color("#ffc247"), Color("#6b3d21"), 8, Vector2(0, 2)))


func apply_action_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color("#fff7dc"))
	button.add_theme_color_override("font_hover_color", Color("#fff7dc"))
	button.add_theme_color_override("font_pressed_color", Color("#fff7dc"))
	button.add_theme_stylebox_override("normal", make_button_style(Color("#c43d32"), Color("#ffe6a7"), 30, Vector2(0, 5)))
	button.add_theme_stylebox_override("hover", make_button_style(Color("#d85336"), Color("#fff0b5"), 30, Vector2(0, 5)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color("#8f2a20"), Color("#ffe6a7"), 30, Vector2(0, 2)))


func make_button_style(fill: Color, border: Color, radius: int, shadow_offset: Vector2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 1
	style.shadow_offset = shadow_offset
	return style


func make_menu_button(text: String) -> Button:
	var button := make_button(text)
	button.custom_minimum_size = Vector2(360, 58)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_stylebox_override("normal", make_panel_style(Color("#9b5b26"), Color("#3a1c11")))
	button.add_theme_stylebox_override("hover", make_panel_style(Color("#b86f31"), Color("#ffe6a7")))
	button.add_theme_stylebox_override("pressed", make_panel_style(Color("#75421d"), Color("#3a1c11")))
	button.add_theme_color_override("font_color", Color("#241306"))
	return button


func make_transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style

func make_menu_selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.78, 0.22, 0.08)
	style.border_color = Color(1.0, 0.92, 0.48, 0.9)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(1.0, 0.74, 0.18, 0.42)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	return style


func make_panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


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
	draw_church_plaza()
	draw_ozildo_plaza()
	draw_paths()
	draw_props()
	draw_missions()
	draw_opening_seu_ze_on_map()
	draw_player()
	if opening_active:
		draw_opening_map_guides()
	draw_vignette()



func draw_opening_seu_ze_on_map() -> void:
	var pos := get_seu_ze_pos() - camera_pos
	draw_ellipse_shadow(pos + Vector2(0, 17), Vector2(17, 4), 0.16)
	draw_seu_ze_sprite(pos, 118.0)
	if should_show_seu_ze_marker():
		var pulse := sin(Time.get_ticks_msec() / 170.0) * 5.0
		draw_string(ThemeDB.fallback_font, pos + Vector2(-7, -102 + pulse), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#ffc247"))


func should_show_seu_ze_marker() -> bool:
	if opening_active:
		return true
	if not learned.has(PHASE1_ACCEPTED_ID):
		return true
	if learned.has(PHASE1_DONE_ID):
		return false
	return has_all_phase1_pages()


func draw_seu_ze_sprite(pos: Vector2, draw_h: float) -> void:
	if seu_ze_fan_texture != null:
		var frame_index := get_seu_ze_fan_frame(is_seu_ze_visible_on_screen(pos, draw_h))
		var cell_size := Vector2(
			seu_ze_fan_texture.get_width() / float(SEU_ZE_FAN_COLUMNS),
			seu_ze_fan_texture.get_height() / float(SEU_ZE_FAN_ROWS)
		)
		var frame_col := frame_index % SEU_ZE_FAN_COLUMNS
		var frame_row := floori(float(frame_index) / float(SEU_ZE_FAN_COLUMNS))
		var source := Rect2(
			Vector2(
				frame_col * cell_size.x + cell_size.x * SEU_ZE_FAN_CROP_X_RATIO,
				frame_row * cell_size.y
			),
			Vector2(cell_size.x * SEU_ZE_FAN_CROP_WIDTH_RATIO, cell_size.y)
		)
		var draw_w := draw_h * (source.size.x / source.size.y)
		var target := Rect2(pos + Vector2(-draw_w / 2.0, -draw_h + 16.0), Vector2(draw_w, draw_h))
		draw_texture_rect_region(seu_ze_fan_texture, target, source)
		return
	if seu_ze_idle_texture != null:
		var frame_index := 0
		if not active_dialog:
			frame_index = int(Time.get_ticks_msec() / (1000.0 / SEU_ZE_IDLE_FPS)) % SEU_ZE_IDLE_FRAME_COUNT
		var frame_col := frame_index % SEU_ZE_IDLE_COLUMNS
		var frame_row := floori(float(frame_index) / float(SEU_ZE_IDLE_COLUMNS))
		var source := Rect2(
			Vector2(
				float(frame_col) * SEU_ZE_IDLE_FRAME_SIZE.x,
				float(frame_row) * SEU_ZE_IDLE_FRAME_SIZE.y
			),
			SEU_ZE_IDLE_FRAME_SIZE
		)
		var draw_w := draw_h * (SEU_ZE_IDLE_FRAME_SIZE.x / SEU_ZE_IDLE_FRAME_SIZE.y)
		var target := Rect2(pos + Vector2(-draw_w / 2.0, -draw_h + 16.0), Vector2(draw_w, draw_h))
		draw_texture_rect_region(seu_ze_idle_texture, target, source)
		return
	if not seu_ze_sprite.is_empty():
		var region: Rect2 = seu_ze_sprite["region"]
		var draw_w := draw_h * (region.size.x / region.size.y)
		var target := Rect2(pos + Vector2(-draw_w / 2.0, -draw_h + 16.0), Vector2(draw_w, draw_h))
		draw_texture_rect_region(seu_ze_sprite["texture"], target, region)
		return
	draw_npc(pos, "guaribas")


func is_seu_ze_visible_on_screen(pos: Vector2, draw_h: float) -> bool:
	if not running:
		return false
	var viewport := get_viewport_rect().size
	var margin := draw_h * 0.7
	return Rect2(Vector2(-margin, -draw_h - margin), viewport + Vector2(margin * 2.0, draw_h + margin * 2.0)).has_point(pos)


func get_seu_ze_fan_frame(visible_on_screen: bool) -> int:
	if not visible_on_screen:
		return 0 if not seu_ze_fan_intro_done else SEU_ZE_FAN_LOOP_START_FRAME
	var now := Time.get_ticks_msec()
	if seu_ze_fan_started_msec < 0:
		seu_ze_fan_started_msec = now
	var elapsed := float(now - seu_ze_fan_started_msec) / 1000.0

	if not seu_ze_fan_intro_done:
		var intro_frame := int(floor(elapsed * SEU_ZE_FAN_FPS))
		if intro_frame < SEU_ZE_FAN_LOOP_START_FRAME:
			return intro_frame
		seu_ze_fan_intro_done = true
		seu_ze_fan_started_msec = now
		return SEU_ZE_FAN_LOOP_START_FRAME

	var loop_frame_count := SEU_ZE_FAN_FRAME_COUNT - SEU_ZE_FAN_LOOP_START_FRAME
	var loop_elapsed := float(now - seu_ze_fan_started_msec) / 1000.0
	return SEU_ZE_FAN_LOOP_START_FRAME + int(floor(loop_elapsed * SEU_ZE_FAN_FPS)) % loop_frame_count


func draw_opening_map_guides() -> void:
	var viewport := get_viewport_rect().size
	if opening_phase == "fade":
		draw_opening_appear_effect(viewport)
	elif opening_memory_open:
		draw_opening_memory_card(viewport)
	elif opening_phase == "photo":
		draw_opening_camera_collectible()
		draw_opening_hint(opening_hint, viewport)
	elif opening_phase in ["walk", "meet"]:
		draw_bee_path_to_church()
		draw_opening_hint(opening_hint, viewport)
	if opening_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(1, 1, 1, opening_flash), true)


func draw_opening_appear_effect(viewport: Vector2) -> void:
	var screen_pos := player_pos - camera_pos
	var progress := clampf(opening_time / 1.25, 0.0, 1.0)
	for i in range(3):
		var radius := 18.0 + progress * 54.0 + i * 18.0
		draw_arc(screen_pos + Vector2(0, 14), radius, 0, TAU, 40, Color(1.0, 0.76, 0.28, (1.0 - progress) * (0.38 - i * 0.08)), 3.0)
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0, 0, 0, 1.0 - progress), true)


func draw_bee_path_to_church() -> void:
	var start := player_pos.lerp(get_seu_ze_pos(), 0.24)
	var finish := get_seu_ze_pos() + Vector2(-120, -26)
	for i in range(4):
		var t := 0.22 + float(i) * 0.16
		var world := start.lerp(finish, t) + Vector2(0, -92 + sin(opening_time * 2.4 + i) * 7.0)
		var pos := world - camera_pos + Vector2(sin(opening_time * 2.1 + i) * 5.0, 0)
		draw_circle(pos, 4.0, Color(1.0, 0.76, 0.25, 0.48))
		draw_rect(Rect2(pos + Vector2(-1, -3), Vector2(2, 6)), Color(0.23, 0.11, 0.07, 0.32), true)
		draw_circle(pos + Vector2(-3, -4), 3.0, Color(1, 1, 1, 0.24))
		draw_circle(pos + Vector2(3, -4), 3.0, Color(1, 1, 1, 0.24))



func draw_opening() -> void:
	var viewport := get_viewport_rect().size
	draw_opening_sky(viewport)
	draw_opening_mountains(viewport)
	draw_opening_street(viewport)
	draw_opening_props()
	draw_player_at(Vector2(opening_player_x - opening_camera_x, opening_player_y), player_dir, walk_time)
	draw_opening_seu_ze()
	draw_opening_ui(viewport)
	draw_vignette()
	if opening_phase == "fade":
		var alpha := clampf(1.0 - opening_time / 2.4, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(0, 0, 0, alpha), true)
	if opening_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(1, 1, 1, opening_flash), true)


func opening_world_pos(x: float, y: float) -> Vector2:
	return Vector2(x - opening_camera_x, y)


func draw_opening_sky(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color("#70c8ff"), true)
	draw_rect(Rect2(Vector2(0, viewport.y * 0.52), Vector2(viewport.x, viewport.y * 0.48)), Color("#f5cf86"), true)
	draw_opening_cloud(opening_world_pos(170, 92), 1.0)
	draw_opening_cloud(opening_world_pos(780, 76), 0.8)
	draw_opening_cloud(opening_world_pos(1380, 112), 0.95)


func draw_opening_cloud(pos: Vector2, scale: float) -> void:
	var color := Color(1, 1, 1, 0.9)
	draw_circle(pos, 24 * scale, color)
	draw_circle(pos + Vector2(28, -10) * scale, 32 * scale, color)
	draw_circle(pos + Vector2(64, 0) * scale, 24 * scale, color)


func draw_opening_mountains(viewport: Vector2) -> void:
	var base := get_opening_ground_y() - 116.0
	var points := PackedVector2Array()
	points.append(opening_world_pos(0, viewport.y))
	points.append(opening_world_pos(0, base))
	for x in range(0, 2301, 120):
		points.append(opening_world_pos(x + 70, base - 70.0 - sin(float(x) * 0.015) * 30.0))
		points.append(opening_world_pos(x + 140, base))
	points.append(opening_world_pos(2300, viewport.y))
	draw_colored_polygon(points, Color("#5d9b69"))
	draw_rect(Rect2(opening_world_pos(0, base + 20), Vector2(2300, 90)), Color("#3b7d55"), true)


func draw_opening_street(viewport: Vector2) -> void:
	var ground := get_opening_ground_y()
	draw_rect(Rect2(opening_world_pos(0, ground - 18), Vector2(2300, viewport.y - ground + 18)), Color("#d6b16a"), true)
	draw_rect(Rect2(opening_world_pos(0, ground + 18), Vector2(2300, 74)), Color("#7a7c78"), true)
	for x in range(30, 2300, 150):
		draw_rect(Rect2(opening_world_pos(x, ground + 50), Vector2(70, 8)), Color("#e7d69d"), true)


func draw_opening_props() -> void:
	var ground := get_opening_ground_y()
	draw_opening_picos_sign(opening_world_pos(232, ground - 8))
	draw_opening_tree(opening_world_pos(710, ground - 6))
	draw_opening_poster(opening_world_pos(940, ground - 6))
	draw_opening_sleeping_dog(opening_world_pos(1160, ground + 8))
	draw_opening_bees()
	draw_opening_church(opening_world_pos(1600, ground - 12))


func draw_opening_picos_sign(pos: Vector2) -> void:
	if picos_sign_texture:
		var draw_w := 330.0
		var draw_h := draw_w * (picos_sign_texture.get_height() / float(picos_sign_texture.get_width()))
		draw_texture_rect(picos_sign_texture, Rect2(pos + Vector2(-48, -158), Vector2(draw_w, draw_h)), false)
		return
	draw_rect(Rect2(pos + Vector2(34, -70), Vector2(10, 70)), Color("#744325"), true)
	draw_rect(Rect2(pos + Vector2(188, -70), Vector2(10, 70)), Color("#744325"), true)
	draw_rect(Rect2(pos + Vector2(0, -120), Vector2(238, 58)), Color("#ffd45a"), true)
	draw_rect(Rect2(pos + Vector2(0, -120), Vector2(238, 58)), Color("#2c4f87"), false, 5)
	draw_string(ThemeDB.fallback_font, pos + Vector2(64, -82), "PICOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#2167a8"))


func draw_opening_tree(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-14, -98), Vector2(26, 98)), Color("#6d3f24"), true)
	for i in range(8):
		draw_circle(pos + Vector2(cos(i) * 36.0, -118.0 + sin(i * 1.7) * 18.0), 38, Color("#2f7b47"))


func draw_opening_poster(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(0, -142), Vector2(10, 142)), Color("#4b3b31"), true)
	draw_rect(Rect2(pos + Vector2(-42, -122), Vector2(92, 66)), Color("#f2d57c"), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-34, -96), "SAO JOAO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c43d32"))
	draw_rect(Rect2(pos + Vector2(-34, -86), Vector2(54, 6)), Color("#2f78b7"), true)
	draw_colored_polygon([pos + Vector2(18, -56), pos + Vector2(50, -56), pos + Vector2(18, -32)], Color("#8f6a42"))


func draw_opening_sleeping_dog(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-34, -28), Vector2(64, 24)), Color("#c9843d"), true)
	draw_rect(Rect2(pos + Vector2(18, -42), Vector2(28, 24)), Color("#c9843d"), true)
	draw_rect(Rect2(pos + Vector2(38, -36), Vector2(10, 18)), Color("#6b3d21"), true)
	draw_rect(Rect2(pos + Vector2(34, -30), Vector2(4, 4)), Color("#2b1c15"), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-14, -46), "Zzz", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#2b1c15"))


func draw_opening_bees() -> void:
	if opening_phase != "walk":
		return
	var ground := get_opening_ground_y()
	for i in range(4):
		var pos := opening_world_pos(560 + i * 230 + sin(opening_time * 2.4 + i) * 8.0, ground - 174.0 + sin(opening_time * 2.8 + i) * 8.0)
		draw_circle(pos, 4.0, Color(1.0, 0.76, 0.25, 0.45))
		draw_rect(Rect2(pos + Vector2(-1, -3), Vector2(2, 6)), Color(0.23, 0.11, 0.07, 0.32), true)
		draw_circle(pos + Vector2(-3, -4), 3.0, Color(1, 1, 1, 0.24))
		draw_circle(pos + Vector2(3, -4), 3.0, Color(1, 1, 1, 0.24))


func draw_opening_church(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-220, -78), Vector2(520, 92)), Color("#d9bb84"), true)
	draw_rect(Rect2(pos + Vector2(0, -220), Vector2(170, 214)), Color("#f2efe4"), true)
	draw_rect(Rect2(pos + Vector2(-54, -180), Vector2(50, 174)), Color("#f2efe4"), true)
	draw_rect(Rect2(pos + Vector2(174, -180), Vector2(50, 174)), Color("#f2efe4"), true)
	draw_rect(Rect2(pos + Vector2(26, -92), Vector2(54, 86)), Color("#c99b4a"), true)
	draw_colored_polygon([pos + Vector2(0, -220), pos + Vector2(86, -292), pos + Vector2(170, -220)], Color("#d6a948"))
	draw_colored_polygon([pos + Vector2(-60, -180), pos + Vector2(-28, -232), pos + Vector2(4, -180)], Color("#d6a948"))
	draw_colored_polygon([pos + Vector2(168, -180), pos + Vector2(199, -232), pos + Vector2(230, -180)], Color("#d6a948"))
	draw_rect(Rect2(pos + Vector2(-232, -28), Vector2(84, 14)), Color("#744325"), true)


func draw_opening_seu_ze() -> void:
	if opening_phase != "meet" and opening_player_x < 1390.0:
		return
	var ground := get_opening_ground_y()
	var pos := opening_world_pos(1760, ground - 4)
	draw_rect(Rect2(pos + Vector2(-86, -38), Vector2(154, 18)), Color("#744325"), true)
	draw_rect(Rect2(pos + Vector2(-74, -26), Vector2(16, 42)), Color("#744325"), true)
	draw_rect(Rect2(pos + Vector2(42, -26), Vector2(16, 42)), Color("#744325"), true)
	draw_seu_ze_sprite(pos + Vector2(0, -18), 132.0)
	if opening_phase == "meet":
		draw_string(ThemeDB.fallback_font, pos + Vector2(-7, -174 + sin(opening_time * 5.0) * 5.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#ffc247"))


func draw_opening_ui(viewport: Vector2) -> void:
	if opening_memory_open:
		draw_opening_memory_card(viewport)
		return
	if opening_phase in ["photo", "walk", "meet"]:
		draw_opening_hint(opening_hint, viewport)


func draw_opening_camera_collectible() -> void:
	if opening_camera_collected:
		return
	var pos := get_opening_camera_pos() - camera_pos
	var bob := sin(opening_time * 4.0) * 2.5
	draw_ellipse_shadow(pos + Vector2(0, 15), Vector2(15, 4), 0.14)
	if not camera_sprite.is_empty():
		var region: Rect2 = camera_sprite["region"]
		var draw_w := 46.0
		var draw_h := draw_w * (region.size.y / region.size.x)
		var target := Rect2(pos + Vector2(-draw_w / 2.0, -draw_h + bob), Vector2(draw_w, draw_h))
		draw_texture_rect_region(camera_sprite["texture"], target, region)
	else:
		draw_rect(Rect2(pos + Vector2(-19, -28 + bob), Vector2(38, 28)), Color("#ffc247"), true)
		draw_circle(pos + Vector2(0, -14 + bob), 8, Color("#1b150c"))
	if player_pos.distance_to(get_opening_camera_pos()) < 58.0:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-9, -52 + bob), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffc247"))


func draw_camera_icon() -> void:
	var rect := get_camera_icon_rect()
	var pulse := 1.0 + sin(opening_time * 5.0) * 0.06
	var center := rect.get_center()
	if not camera_sprite.is_empty():
		var region: Rect2 = camera_sprite["region"]
		var draw_w := 88.0 * pulse
		var draw_h := draw_w * (region.size.y / region.size.x)
		var target := Rect2(center - Vector2(draw_w, draw_h) / 2.0, Vector2(draw_w, draw_h))
		draw_texture_rect_region(camera_sprite["texture"], target, region)
		return
	draw_rect(Rect2(center - Vector2(31, 20) * pulse, Vector2(62, 44) * pulse), Color("#ffc247"), true)
	draw_circle(center + Vector2(0, 6) * pulse, 14 * pulse, Color("#1b150c"))
	draw_circle(center + Vector2(0, 6) * pulse, 8 * pulse, Color("#7ed4ff"))


func draw_opening_hint(text: String, viewport: Vector2) -> void:
	var font_size := 18
	var rect := get_opening_hint_rect(viewport, text, font_size)
	draw_rect(rect, Color(0.62, 0.38, 0.16, 0.58), true)
	draw_rect(rect, Color("#ffc247"), false, 3.0)
	var lines := wrap_hint_text(text, rect.size.x - 36.0, font_size)
	var line_height := 22.0
	var total_h := lines.size() * line_height
	var start_y := rect.position.y + (rect.size.y - total_h) * 0.5 + 17.0
	for i in range(lines.size()):
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 18.0, start_y + i * line_height), lines[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, font_size, Color("#fff7dc"))


func get_opening_hint_rect(viewport: Vector2, text: String, font_size: int) -> Rect2:
	var width := minf(620.0, viewport.x - 28.0)
	var x := (viewport.x - width) / 2.0
	if touch_ui and touch_ui.visible:
		var left := 304.0
		var right := viewport.x - 228.0
		if right - left >= 260.0:
			width = right - left
			x = left
	var lines := wrap_hint_text(text, width - 36.0, font_size)
	var height := 54.0 if lines.size() <= 1 else 74.0
	var y := viewport.y - height - 34.0
	return Rect2(Vector2(x, y), Vector2(width, height))


func wrap_hint_text(text: String, max_width: float, font_size: int) -> Array[String]:
	var words := text.split(" ")
	var lines: Array[String] = []
	var line := ""
	for word in words:
		var test := word if line.is_empty() else "%s %s" % [line, word]
		if not line.is_empty() and ThemeDB.fallback_font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
			lines.append(line)
			line = word
		else:
			line = test
	if not line.is_empty():
		lines.append(line)
	if lines.size() <= 2:
		return lines
	var collapsed: Array[String] = [lines[0]]
	var rest := ""
	for i in range(1, lines.size()):
		rest = lines[i] if rest.is_empty() else "%s %s" % [rest, lines[i]]
	collapsed.append(rest)
	return collapsed


func draw_opening_memory_card(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.03, 0.06, 0.12, 0.48), true)
	var max_w := minf(viewport.x - 36.0, 1040.0)
	var max_h := viewport.y - 56.0
	var card_w := max_w
	var card_h := card_w * 9.0 / 16.0
	if card_h > max_h:
		card_h = max_h
		card_w = card_h * 16.0 / 9.0
	var rect := Rect2((viewport - Vector2(card_w, card_h)) * 0.5, Vector2(card_w, card_h))
	draw_rect(rect.grow(8.0), Color(0, 0, 0, 0.22), true)
	draw_rect(rect, Color("#ead8ac"), true)
	if memory_polaroid_texture:
		var texture_size := memory_polaroid_texture.get_size()
		var scale := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
		var draw_size := texture_size * scale
		var target := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
		draw_texture_rect(memory_polaroid_texture, target, false)


func world_rect(tile: Vector2i) -> Rect2:
	return Rect2(Vector2(tile) * TILE - camera_pos, Vector2(TILE, TILE))


func world_pos(pos: Vector2) -> Vector2:
	return pos - camera_pos


func draw_ground() -> void:
	for x in range(WORLD_W):
		for y in range(WORLD_H):
			var key := tile_key(x, y)
			var dry := y > 20 or x > 26
			var shade := float(((x * 17 + y * 29) % 7) - 3) * 0.018
			var fill := Color("#2a8fc1") if water.has(key) else (Color("#3d3f43") if road_tiles.has(key) else (Color("#cfc4a6") if plaza_tiles.has(key) else (Color("#b9a05c") if dry else Color("#6ba65a"))))
			var line := Color("#1e6e9d") if water.has(key) else (Color("#24262a") if road_tiles.has(key) else (Color("#968c73") if plaza_tiles.has(key) else (Color("#8f7d42") if dry else Color("#477a3c"))))
			fill = fill.lightened(maxf(shade, 0.0)).darkened(maxf(-shade, 0.0))
			var rect := world_rect(Vector2i(x, y))
			draw_rect(rect, fill)
			if not water.has(key) and not road_tiles.has(key) and not plaza_tiles.has(key) and dry:
				draw_dynamic_dirt_tile(rect, x, y)
			if water.has(key):
				draw_water_tile(rect, x, y)
				draw_water_edge(x, y, rect)
			elif road_tiles.has(key):
				draw_road_tile(rect, x, y)
			elif plaza_tiles.has(key):
				draw_plaza_tile(rect, x, y)
			if not road_tiles.has(key):
				draw_rect(rect.grow(-0.5), Color(line.r, line.g, line.b, 0.28), false, 1.0)
			if not water.has(key) and not plaza_tiles.has(key) and (x * 13 + y * 7) % 9 == 0:
				draw_rect(Rect2(rect.position + Vector2(9, 14), Vector2(6, 6)), Color("#8fc56e") if not dry else Color("#d6bd75"))
				draw_rect(Rect2(rect.position + Vector2(28, 31), Vector2(5, 5)), Color("#527f3d") if not dry else Color("#9b874a"))
			if not water.has(key) and not plaza_tiles.has(key) and (x * 5 + y * 11) % 6 == 0:
				draw_grass_detail(rect.position, dry)
			if water.has(key):
				draw_rect(Rect2(rect.position + Vector2(4, 9), Vector2(25, 3)), Color(1, 1, 1, 0.12))


func draw_dynamic_dirt_tile(rect: Rect2, x: int, y: int) -> void:
	if dynamic_dirt_texture == null:
		return
	var tile_source_size := Vector2(96, 96)
	var max_x := maxf(0.0, dynamic_dirt_texture.get_width() - tile_source_size.x)
	var max_y := maxf(0.0, dynamic_dirt_texture.get_height() - tile_source_size.y)
	var sx := float((x * 137 + y * 47) % int(max_x + 1.0))
	var sy := float((x * 53 + y * 149) % int(max_y + 1.0))
	var source := Rect2(Vector2(sx, sy), tile_source_size)
	draw_texture_rect_region(dynamic_dirt_texture, rect, source, Color(1, 1, 1, 0.42))


func draw_ozildo_plaza() -> void:
	var area := Rect2(Vector2(ozildo_plaza_tile) * TILE - camera_pos, Vector2(ozildo_plaza_size) * TILE)
	draw_rect(area.grow(5.0), Color(0.19, 0.16, 0.11, 0.20), true)
	draw_rect(area, Color("#d7c8a5"), true)
	for x in range(ozildo_plaza_tile.x, ozildo_plaza_tile.x + ozildo_plaza_size.x):
		for y in range(ozildo_plaza_tile.y, ozildo_plaza_tile.y + ozildo_plaza_size.y):
			draw_plaza_tile(world_rect(Vector2i(x, y)), x, y)
	draw_rect(area.grow(-8.0), Color("#8a7654"), false, 3.0)
	draw_rect(area.grow(-14.0), Color(1, 1, 1, 0.10), false, 1.0)

	var entry := Rect2(Vector2(ozildo_museum_tile.x - 1, ozildo_museum_tile.y + 3) * TILE - camera_pos, Vector2(4 * TILE, 5 * TILE))
	draw_rect(entry, Color("#b48a55"), true)
	for y in range(0, 5):
		var line_y := entry.position.y + y * TILE + TILE * 0.5
		draw_line(Vector2(entry.position.x, line_y), Vector2(entry.position.x + entry.size.x, line_y), Color(0.42, 0.27, 0.14, 0.28), 1.0)
	draw_rect(entry, Color("#6f5132"), false, 2.0)

	for garden in [
		Rect2(area.position + Vector2(24, 24), Vector2(92, 36)),
		Rect2(area.position + Vector2(area.size.x - 116, 24), Vector2(92, 36)),
		Rect2(area.position + Vector2(24, area.size.y - 58), Vector2(116, 34)),
		Rect2(area.position + Vector2(area.size.x - 140, area.size.y - 58), Vector2(116, 34))
	]:
		draw_rect(garden, Color("#715137"), true)
		draw_rect(garden.grow(-5.0), Color("#4f873c"), true)
		draw_rect(garden, Color("#e0c17b"), false, 2.0)
		for i in range(3):
			draw_circle(garden.position + Vector2(22 + i * 28, garden.size.y * 0.5), 5.0, Color("#f5d35c"))

	if ozildo_plaza_texture == null:
		return
	var texture_size := ozildo_plaza_texture.get_size()
	var draw_h := area.size.x * (texture_size.y / texture_size.x)
	var draw_size := Vector2(area.size.x, draw_h)
	if draw_h > area.size.y:
		draw_size = Vector2(area.size.y * (texture_size.x / texture_size.y), area.size.y)
	var target := Rect2(area.position + (area.size - draw_size) * 0.5, draw_size)
	draw_texture_rect(ozildo_plaza_texture, target, false, Color(1, 1, 1, 0.16))


func draw_church_plaza() -> void:
	var area := Rect2(Vector2(picos_church_plaza_tile) * TILE - camera_pos, Vector2(picos_church_plaza_size) * TILE)
	for x in range(picos_church_plaza_tile.x, picos_church_plaza_tile.x + picos_church_plaza_size.x):
		for y in range(picos_church_plaza_tile.y, picos_church_plaza_tile.y + picos_church_plaza_size.y):
			draw_plaza_tile(world_rect(Vector2i(x, y)), x, y)
	draw_rect(area, Color(0.45, 0.31, 0.16, 0.14), false, 2.0)

	if church_plaza_texture:
		var art_area := Rect2(Vector2(picos_church_plaza_art_tile) * TILE - camera_pos, Vector2(picos_church_plaza_art_size) * TILE)
		var texture_size := church_plaza_texture.get_size()
		var draw_h := art_area.size.x * (texture_size.y / texture_size.x)
		var draw_size := Vector2(art_area.size.x, draw_h)
		if draw_h > art_area.size.y:
			draw_size = Vector2(art_area.size.y * (texture_size.x / texture_size.y), art_area.size.y)
		var draw_rect := Rect2(art_area.position + (art_area.size - draw_size) * 0.5, draw_size)
		draw_texture_rect(church_plaza_texture, draw_rect, false)
		return

	var t := Time.get_ticks_msec() / 1000.0
	var fountain := area.position + Vector2(area.size.x * 0.5, area.size.y * 0.74)
	for i in range(3):
		var radius := 13.0 + i * 7.0 + sin(t * 3.0 + i) * 1.5
		draw_arc(fountain, radius, 0, TAU, 32, Color(0.55, 0.94, 1.0, 0.38 - i * 0.08), 2.0)
	draw_line(fountain + Vector2(0, -24), fountain + Vector2(sin(t * 5.0) * 4.0, -4), Color(0.75, 1.0, 1.0, 0.56), 2.0)


func draw_water_tile(rect: Rect2, x: int, y: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var base := Color("#087ec8").lightened(float((x * 11 + y * 7) % 5) * 0.025)
	draw_rect(rect, base)
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(TILE, TILE)), Color("#12a7d8"), false, 2)

	for i in range(3):
		var y_pos := rect.position.y + 9 + i * 14 + sin(t * 1.7 + x * 0.7 + y * 0.35 + i) * 2.0
		var points := PackedVector2Array()
		for p in range(5):
			var px := rect.position.x + p * 12
			var py := y_pos + sin(t * 2.2 + (x * TILE + p * 12) * 0.045 + i * 1.8) * 3.0
			points.append(Vector2(px, py))
		draw_polyline(points, Color(0.48, 0.95, 1.0, 0.34), 2.0)

	if (x + y) % 3 == 0:
		draw_rect(Rect2(rect.position + Vector2(9, 7), Vector2(8, 3)), Color(0.75, 1.0, 1.0, 0.22))
	if (x * 2 + y) % 4 == 0:
		draw_rect(Rect2(rect.position + Vector2(30, 31), Vector2(10, 2)), Color(0.03, 0.35, 0.68, 0.18))


func draw_water_edge(x: int, y: int, rect: Rect2) -> void:
	var shore := Color(0.72, 0.84, 0.63, 0.38)
	if not water.has(tile_key(x - 1, y)):
		draw_rect(Rect2(rect.position, Vector2(5, TILE)), shore)
	if not water.has(tile_key(x + 1, y)):
		draw_rect(Rect2(rect.position + Vector2(TILE - 5, 0), Vector2(5, TILE)), shore)
	if not water.has(tile_key(x, y - 1)):
		draw_rect(Rect2(rect.position, Vector2(TILE, 5)), shore)
	if not water.has(tile_key(x, y + 1)):
		draw_rect(Rect2(rect.position + Vector2(0, TILE - 5), Vector2(TILE, 5)), shore)


func draw_plaza_tile(rect: Rect2, x: int, y: int) -> void:
	var grout := Color(0.56, 0.52, 0.43, 0.42)
	draw_line(rect.position + Vector2(0, TILE / 2.0), rect.position + Vector2(TILE, TILE / 2.0), grout, 1)
	draw_line(rect.position + Vector2(TILE / 2.0, 0), rect.position + Vector2(TILE / 2.0, TILE), grout, 1)
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(TILE, 2)), Color(1, 1, 1, 0.10))
	draw_rect(Rect2(rect.position + Vector2(0, TILE - 2), Vector2(TILE, 2)), Color(0.38, 0.34, 0.27, 0.18))
	if (x + y) % 3 == 0:
		draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(5, 5)), Color(0.88, 0.84, 0.70, 0.55))
	if (x * 2 + y) % 5 == 0:
		draw_rect(Rect2(rect.position + Vector2(31, 30), Vector2(7, 3)), Color(0.45, 0.41, 0.34, 0.35))
	if x % 4 == 0 and y % 3 == 0:
		draw_rect(Rect2(rect.position + Vector2(18, 18), Vector2(12, 12)), Color(0.76, 0.72, 0.60, 0.35), false, 1)


func draw_road_tile(rect: Rect2, x: int, y: int) -> void:
	if asphalt_texture:
		draw_texture_rect(asphalt_texture, rect, false)
	else:
		draw_rect(rect, Color("#3b3d40"))
	draw_rect(Rect2(rect.position, Vector2(TILE, 5)), Color("#2d2f33"))
	draw_rect(Rect2(rect.position + Vector2(0, TILE - 5), Vector2(TILE, 5)), Color("#54565a"))
	draw_rect(Rect2(rect.position + Vector2(0, 6), Vector2(TILE, 2)), Color("#f0efdd"))
	draw_rect(Rect2(rect.position + Vector2(0, TILE - 8), Vector2(TILE, 2)), Color("#f0efdd"))
	if x % 2 == 0:
		draw_rect(Rect2(rect.position + Vector2(20, TILE / 2.0 - 2), Vector2(8, 4)), Color("#e2d27b"))
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(TILE, 3)), Color(1, 1, 1, 0.08))
	if (x + y) % 6 == 0:
		draw_rect(Rect2(rect.position + Vector2(8, 8), Vector2(5, 2)), Color(1, 1, 1, 0.10))


func draw_grass_detail(pos: Vector2, dry: bool) -> void:
	var color_a := Color("#739b47") if dry else Color("#3d7e3c")
	var color_b := Color("#c7ad64") if dry else Color("#8fbd64")
	draw_line(pos + Vector2(15, 34), pos + Vector2(18, 27), color_a, 2)
	draw_line(pos + Vector2(20, 34), pos + Vector2(18, 27), color_b, 1)
	draw_rect(Rect2(pos + Vector2(34, 12), Vector2(3, 7)), Color(color_b.r, color_b.g, color_b.b, 0.7))


func draw_paths() -> void:
	var samples := get_path_samples()
	draw_path_layer(samples, 150, Color("#24282d"))
	draw_path_layer(samples, 138, Color("#3d4144"))
	draw_path_borders(samples)
	draw_path_details(samples)


func draw_curve_asphalt_piece(top_left: Vector2, draw_w: float) -> void:
	if asphalt_curve_sprite.is_empty():
		return
	var region: Rect2 = asphalt_curve_sprite["region"]
	var draw_h := draw_w * (region.size.y / region.size.x)
	var target := Rect2(top_left - camera_pos, Vector2(draw_w, draw_h))
	draw_texture_rect_region(asphalt_curve_sprite["texture"], target, region)


func get_path_samples() -> Array[Vector2]:
	var curves := [
		[Vector2(-3, 26.5), Vector2(7, 26.5), Vector2(19, 26.5), Vector2(30, 26.5)],
		[Vector2(30, 26.5), Vector2(35, 26.5), Vector2(42, 27.2), Vector2(50, 27.25)],
		[Vector2(50, 27.25), Vector2(55, 27.25), Vector2(61, 27.25), Vector2(69, 27.25)]
	]
	var samples: Array[Vector2] = []
	for curve_index in range(curves.size()):
		var curve: Array = curves[curve_index]
		var steps := 24 if curve_index == 0 else (38 if curve_index == 1 else 44)
		for i in range(steps + 1):
			if curve_index > 0 and i == 0:
				continue
			var t := i / float(steps)
			samples.append(cubic_bezier(curve[0] * TILE, curve[1] * TILE, curve[2] * TILE, curve[3] * TILE, t))
	return samples


func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var a := p0.lerp(p1, t)
	var b := p1.lerp(p2, t)
	var c := p2.lerp(p3, t)
	var d := a.lerp(b, t)
	var e := b.lerp(c, t)
	return d.lerp(e, t)


func draw_path_layer(points: Array[Vector2], width: float, color: Color) -> void:
	var screen_points := PackedVector2Array()
	for point in points:
		screen_points.append(world_pos(point))
	draw_polyline(screen_points, color, width)


func draw_path_borders(points: Array[Vector2]) -> void:
	var top_edge := PackedVector2Array()
	var bottom_edge := PackedVector2Array()
	for i in range(points.size()):
		var normal := get_path_normal(points, i)
		top_edge.append(world_pos(points[i] + normal * 66.0))
		bottom_edge.append(world_pos(points[i] - normal * 66.0))
	draw_polyline(top_edge, Color("#f0efdd"), 2.0)
	draw_polyline(bottom_edge, Color("#f0efdd"), 2.0)


func get_path_normal(points: Array[Vector2], index: int) -> Vector2:
	var previous: Vector2 = points[maxi(index - 1, 0)]
	var next: Vector2 = points[mini(index + 1, points.size() - 1)]
	var tangent := (next - previous).normalized()
	if tangent == Vector2.ZERO:
		tangent = Vector2.RIGHT
	return Vector2(-tangent.y, tangent.x)


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


func draw_path_details(points: Array[Vector2]) -> void:
	var spacing := 180.0
	var dash_length := 36.0
	var next_dash := 90.0
	var distance := 0.0
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var segment := finish - start
		var segment_len := segment.length()
		if segment_len <= 0.01:
			continue
		var tangent := segment / segment_len
		while next_dash <= distance + segment_len:
			var local_t := (next_dash - distance) / segment_len
			var center := start.lerp(finish, local_t)
			draw_center_lane_dash(center, tangent, dash_length)
			next_dash += spacing
		distance += segment_len


func draw_center_lane_dash(center: Vector2, tangent: Vector2, length: float) -> void:
	var normal := Vector2(-tangent.y, tangent.x)
	var half_len := length * 0.5
	var half_thick := 3.5
	var points := PackedVector2Array([
		world_pos(center - tangent * half_len - normal * half_thick),
		world_pos(center + tangent * half_len - normal * half_thick),
		world_pos(center + tangent * half_len + normal * half_thick),
		world_pos(center - tangent * half_len + normal * half_thick)
	])
	draw_colored_polygon(points, Color("#efe8c9"))


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
			"city_building":
				draw_city_building(pos, prop.get("variant", 0))
			"street_lamp":
				draw_street_lamp(pos)
			"city_bench":
				draw_city_bench(pos)
			"picos_sign":
				draw_picos_sign(pos)
			"museum_picos":
				draw_museum_picos(pos)
			"church_picos":
				draw_church_picos(pos)
			"market_stall":
				draw_market_stall(pos, prop.get("variant", 0))
			"produce_crate":
				draw_produce_crate(pos, prop.get("variant", 0))
			_:
				if tree_sprites.has(prop["type"]):
					draw_tree_sprite(pos, prop["type"])
				else:
					draw_bush(pos)


func draw_tree_sprite(pos: Vector2, type: String) -> void:
	var sprite: Dictionary = tree_sprites[type]
	var region: Rect2 = sprite["region"]
	var tall_tree := type == "buriti"
	var draw_h := 118.0 if tall_tree else 96.0
	var draw_w = minf(68.0 if tall_tree else 104.0, draw_h * (region.size.x / region.size.y))
	draw_ellipse_shadow(pos + Vector2(TILE / 2.0, TILE - 6.0), Vector2(draw_w * 0.34, 8.0))
	var target := Rect2(pos + Vector2(TILE / 2.0 - draw_w / 2.0, TILE - draw_h), Vector2(draw_w, draw_h))
	draw_texture_rect_region(sprite["texture"], target, region)


func draw_ellipse_shadow(center: Vector2, radius: Vector2, alpha: float = 0.18) -> void:
	var points := PackedVector2Array()
	for i in range(18):
		var angle := TAU * i / 18.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0, 0, 0, alpha))


func draw_palm(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(20, 18), Vector2(8, 30)), Color("#70482c"))
	for i in range(6):
		var angle := i * PI / 3.0
		draw_circle(pos + Vector2(24 + cos(angle) * 12, 17 + sin(angle) * 8), 13, Color("#226d3d"))


func draw_cactus(pos: Vector2) -> void:
	if not cactus_sprite.is_empty():
		var region: Rect2 = cactus_sprite["region"]
		var draw_h := 78.0
		var draw_w := minf(66.0, draw_h * (region.size.x / region.size.y))
		draw_ellipse_shadow(pos + Vector2(TILE / 2.0, TILE - 5), Vector2(draw_w * 0.32, 7))
		var target := Rect2(pos + Vector2(TILE / 2.0 - draw_w / 2.0, TILE - draw_h), Vector2(draw_w, draw_h))
		draw_texture_rect_region(cactus_sprite["texture"], target, region)
		return
	draw_rect(Rect2(pos + Vector2(20, 12), Vector2(10, 34)), Color("#2f8148"))
	draw_rect(Rect2(pos + Vector2(12, 24), Vector2(10, 8)), Color("#2f8148"))
	draw_rect(Rect2(pos + Vector2(28, 20), Vector2(10, 8)), Color("#2f8148"))


func draw_bush(pos: Vector2) -> void:
	draw_ellipse_shadow(pos + Vector2(25, 39), Vector2(21, 6))
	draw_circle(pos + Vector2(18, 30), 12, Color("#3f8739"))
	draw_circle(pos + Vector2(30, 28), 14, Color("#3f8739"))
	draw_circle(pos + Vector2(27, 37), 10, Color("#3f8739"))
	draw_circle(pos + Vector2(23, 27), 4, Color("#71b454"))


func draw_rock(pos: Vector2) -> void:
	draw_ellipse_shadow(pos + Vector2(27, 40), Vector2(20, 5))
	draw_colored_polygon([pos + Vector2(8, 38), pos + Vector2(19, 13), pos + Vector2(35, 8), pos + Vector2(44, 39)], Color("#916d55"))
	draw_line(pos + Vector2(19, 14), pos + Vector2(29, 36), Color("#6c5144"), 2)
	draw_line(pos + Vector2(28, 12), pos + Vector2(39, 38), Color("#b78d6e"), 2)


func draw_house(pos: Vector2) -> void:
	draw_ellipse_shadow(pos + Vector2(44, 69), Vector2(48, 9))
	draw_rect(Rect2(pos + Vector2(5, 20), Vector2(78, 48)), Color("#bc7b43"))
	draw_rect(Rect2(pos + Vector2(10, 28), Vector2(22, 14)), Color("#d09252"))
	draw_colored_polygon([pos + Vector2(0, 22), pos + Vector2(44, -8), pos + Vector2(88, 22)], Color("#7b3c2b"))
	draw_line(pos + Vector2(8, 22), pos + Vector2(44, -3), Color("#a24f38"), 3)
	draw_rect(Rect2(pos + Vector2(39, 42), Vector2(14, 26)), Color("#29344c"))


func draw_city_building(pos: Vector2, variant: int) -> void:
	var palettes := [
		[Color("#d7d2bd"), Color("#8593a5"), Color("#4d5d70")],
		[Color("#bfc7cf"), Color("#6c7f93"), Color("#31465c")],
		[Color("#e1c486"), Color("#8d7655"), Color("#35546b")]
	]
	var palette: Array = palettes[variant % palettes.size()]
	var h := 82.0 + float(variant % 3) * 18.0
	var w := 82.0
	draw_ellipse_shadow(pos + Vector2(45, 93), Vector2(48, 8))
	draw_rect(Rect2(pos + Vector2(4, 96 - h), Vector2(w, h)), palette[0])
	draw_rect(Rect2(pos + Vector2(4, 96 - h), Vector2(w, 10)), palette[1])
	for row in range(3):
		for col in range(3):
			var wx := pos.x + 15 + col * 21
			var wy := pos.y + 112 - h + row * 22
			draw_rect(Rect2(Vector2(wx, wy), Vector2(11, 11)), palette[2])
			draw_rect(Rect2(Vector2(wx + 2, wy + 2), Vector2(4, 3)), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(pos + Vector2(36, 70), Vector2(18, 26)), Color("#28364a"))
	draw_line(pos + Vector2(4, 96 - h), pos + Vector2(86, 96 - h), Color(1, 1, 1, 0.28), 2)


func draw_street_lamp(pos: Vector2) -> void:
	draw_ellipse_shadow(pos + Vector2(24, 43), Vector2(11, 4))
	draw_rect(Rect2(pos + Vector2(22, 12), Vector2(4, 31)), Color("#2d3136"))
	draw_rect(Rect2(pos + Vector2(18, 40), Vector2(12, 4)), Color("#24282d"))
	draw_circle(pos + Vector2(24, 10), 7, Color("#ffe8a3"))
	draw_circle(pos + Vector2(24, 10), 11, Color(1, 0.86, 0.43, 0.16))


func draw_city_bench(pos: Vector2) -> void:
	draw_ellipse_shadow(pos + Vector2(24, 38), Vector2(21, 4))
	draw_rect(Rect2(pos + Vector2(8, 24), Vector2(32, 7)), Color("#7d5135"))
	draw_rect(Rect2(pos + Vector2(9, 16), Vector2(30, 6)), Color("#9b6742"))
	draw_rect(Rect2(pos + Vector2(12, 31), Vector2(4, 9)), Color("#35312c"))
	draw_rect(Rect2(pos + Vector2(33, 31), Vector2(4, 9)), Color("#35312c"))


func draw_picos_sign(pos: Vector2) -> void:
	if picos_sign_texture:
		var draw_w: float = 500.0
		var draw_h: float = draw_w * (picos_sign_texture.get_height() / float(picos_sign_texture.get_width()))
		var target := Rect2(pos + Vector2(-200, -80), Vector2(draw_w, draw_h))
		draw_ellipse_shadow(pos + Vector2(48, 100), Vector2(130, 12), 0.10)
		draw_texture_rect(picos_sign_texture, target, false)
		return
	draw_ellipse_shadow(pos + Vector2(54, 78), Vector2(58, 7))
	draw_rect(Rect2(pos + Vector2(18, 34), Vector2(6, 42)), Color("#47301f"))
	draw_rect(Rect2(pos + Vector2(84, 34), Vector2(6, 42)), Color("#47301f"))
	draw_rect(Rect2(pos + Vector2(0, 0), Vector2(108, 42)), Color("#1f2428"))
	draw_rect(Rect2(pos + Vector2(4, 4), Vector2(100, 34)), Color("#30363a"))
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(92, 26)), Color("#141719"), false, 2)
	draw_string(ThemeDB.fallback_font, pos + Vector2(22, 28), "PICOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd84a"))
	draw_rect(Rect2(pos + Vector2(8, 39), Vector2(92, 4)), Color("#ffd84a"))


func draw_market_stall(pos: Vector2, variant: int) -> void:
	var canvas: Color = [Color("#d8423a"), Color("#f2c84b"), Color("#3b8cc8"), Color("#3aa65b")][variant % 4]
	draw_ellipse_shadow(pos + Vector2(24, 43), Vector2(28, 6))
	draw_rect(Rect2(pos + Vector2(6, 24), Vector2(36, 18)), Color("#8b5a36"))
	draw_rect(Rect2(pos + Vector2(3, 14), Vector2(42, 12)), canvas)
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(5 + i * 14, 14), Vector2(7, 12)), canvas.lightened(0.25 if i % 2 == 0 else 0.0))
	draw_rect(Rect2(pos + Vector2(10, 31), Vector2(7, 5)), Color("#78b94c"))
	draw_rect(Rect2(pos + Vector2(22, 30), Vector2(7, 6)), Color("#d95f32"))
	draw_rect(Rect2(pos + Vector2(32, 31), Vector2(6, 5)), Color("#e8d45a"))


func draw_produce_crate(pos: Vector2, variant: int) -> void:
	var colors := [Color("#e45a3a"), Color("#79b947"), Color("#e7c547")]
	draw_ellipse_shadow(pos + Vector2(24, 36), Vector2(16, 4))
	draw_rect(Rect2(pos + Vector2(11, 24), Vector2(27, 14)), Color("#7a5133"))
	draw_rect(Rect2(pos + Vector2(13, 19), Vector2(23, 8)), Color("#9b6742"))
	for i in range(4):
		draw_circle(pos + Vector2(16 + i * 6, 22 + (i % 2) * 4), 3, colors[variant % colors.size()])


func draw_church_picos(pos: Vector2) -> void:
	if church_picos_sprite.is_empty():
		draw_city_building(pos, 1)
		return
	var region: Rect2 = church_picos_sprite["region"]
	var draw_w := CHURCH_DRAW_W
	var draw_h := draw_w * (region.size.y / region.size.x)
	draw_ellipse_shadow(pos + Vector2(56, 70), Vector2(168, 9), 0.13)
	var target := Rect2(pos + Vector2(CHURCH_BASE_OFFSET.x, CHURCH_BASE_OFFSET.y - draw_h), Vector2(draw_w, draw_h))
	draw_texture_rect_region(church_picos_sprite["texture"], target, region)


func draw_museum_picos(pos: Vector2) -> void:
	if museum_picos_sprite.is_empty():
		draw_house(pos)
		return
	var region: Rect2 = museum_picos_sprite["region"]
	var draw_w := 410.0
	var draw_h := draw_w * (region.size.y / region.size.x)
	draw_ellipse_shadow(pos + Vector2(96, 174), Vector2(142, 10), 0.11)
	var target := Rect2(pos + Vector2(-112, -126), Vector2(draw_w, draw_h))
	draw_texture_rect_region(museum_picos_sprite["texture"], target, region)


func draw_missions() -> void:
	for mission in missions:
		if mission.has("requires") and not learned.has(mission["requires"]):
			continue
		if String(mission.get("type", "")) == "diary_page" and learned.has(mission["id"]):
			continue
		var center := Vector2(mission["tile"]) * TILE - camera_pos
		draw_circle(center + Vector2(0, -34), 10 + sin(Time.get_ticks_msec() / 180.0) * 2.0, Color("#ffc247") if learned.has(mission["id"]) else Color("#fff7dc"))
		if String(mission.get("type", "")) == "diary_page":
			draw_diary_page(center)
		else:
			draw_npc(center, mission["id"])


func draw_diary_page(pos: Vector2) -> void:
	var bob := sin(Time.get_ticks_msec() / 240.0) * 3.0
	var paper := Rect2(pos + Vector2(-13, -42 + bob), Vector2(26, 34))
	draw_ellipse_shadow(pos + Vector2(0, -3), Vector2(13, 3), 0.13)
	draw_rect(paper, Color("#f5e6b8"), true)
	draw_rect(paper, Color("#8b6234"), false, 2.0)
	draw_line(paper.position + Vector2(6, 10), paper.position + Vector2(20, 10), Color("#b88945"), 2.0)
	draw_line(paper.position + Vector2(6, 17), paper.position + Vector2(18, 17), Color("#b88945"), 2.0)
	draw_line(paper.position + Vector2(6, 24), paper.position + Vector2(21, 24), Color("#b88945"), 2.0)


func draw_npc(pos: Vector2, id: String) -> void:
	var palettes := {
		"museu_ozildo": [Color("#78442c"), Color("#f2d17a")],
		"igreja_picos": [Color("#54677c"), Color("#eef6ff")],
		"praca_ozildo": [Color("#3a8f57"), Color("#fff7dc")],
		"feira_picos": [Color("#a33e3e"), Color("#ffc247")],
		"guaribas": [Color("#1b6fa8"), Color("#ffd6a0")]
	}
	var palette: Array = palettes[id]
	draw_rect(Rect2(pos + Vector2(-12, -34), Vector2(24, 14)), palette[1])
	draw_rect(Rect2(pos + Vector2(-14, -20), Vector2(28, 32)), palette[0])
	draw_rect(Rect2(pos + Vector2(-16, -38), Vector2(32, 7)), Color("#2a1a15"))


func draw_player() -> void:
	draw_player_at(player_pos - camera_pos, player_dir, walk_time)


func draw_player_at(screen_pos: Vector2, direction: String, walk: float) -> void:
	var moving := walk > 0.0
	draw_ellipse_shadow(screen_pos + Vector2(0, 19), Vector2(10, 2.5), 0.14)

	if hero_walk_sheet:
		var frame_index: int = int(floor(walk * 0.7)) % 4 if moving else 0
		var character_id: String = String(settings.get("character", "male"))
		var source: Rect2 = get_character_source_rect(character_id, direction, frame_index)
		var draw_size: Vector2 = Vector2(66, 90)
		var target: Rect2 = Rect2(screen_pos + Vector2(-draw_size.x / 2.0, -draw_size.y + 18), draw_size)
		draw_texture_rect_region(hero_walk_sheet, target, source)
		return

	draw_rect(Rect2(screen_pos + Vector2(-14, -34), Vector2(28, 34)), Color("#d96b28"), true)
	draw_rect(Rect2(screen_pos + Vector2(-18, -48), Vector2(36, 12)), Color("#f2d17a"), true)


func draw_player_step_cues(pos: Vector2, frame_index: int) -> void:
	var side_axis := Vector2(1, 0) if player_dir in ["up", "down"] else Vector2(0, 1)
	var forward_axis := Vector2.ZERO
	if player_dir == "down":
		forward_axis = Vector2(0, 1)
	elif player_dir == "up":
		forward_axis = Vector2(0, -1)
	elif player_dir == "right":
		forward_axis = Vector2(1, 0)
	else:
		forward_axis = Vector2(-1, 0)
	var phase := 1.0 if frame_index > 2 else -1.0
	var foot_a := pos + Vector2(0, 18) - side_axis * 7 + forward_axis * phase * 4
	var foot_b := pos + Vector2(0, 18) + side_axis * 7 - forward_axis * phase * 4
	draw_ellipse_shadow(foot_a, Vector2(5, 2))
	draw_ellipse_shadow(foot_b, Vector2(5, 2))


func draw_vignette() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0, 0, 0, 0.12), true)
