extends Node2D

## Four-lane rhythm prototype with a menu and a Guitar Hero-style highway.
## The chart is kept as song time + lane, independent from the visuals.

enum Screen { MENU, NAME_ENTRY, GAME, EDITOR, SCORES, NEW_LEVEL, DELETE_CONFIRM }

const LANE_COUNT := 4
const THIS_LOVE_PATH := "res://YTDown.com_YouTube_Maroon-5-This-Love_Media_XPpTgCho5ZA_009_128k.mp3"
const FAR_KID_PATH := "res://YTDown.com_YouTube_You-re-Gonna-Go-Far-Kid_Media_pmZKkb_UAg_009_128k.mp3"
const HERO_PATH := "res://YTDown.com_YouTube_Skillet-Hero-Official-Video_Media_y9x2CHQClTU_009_128k.mp3"
const PAD_TEST_CHART_PATH := "res://levels/pad_test_chart.json"
const DRUM_SAMPLES_PATH := "res://YTDown.com_YouTube_Free-Acoustic-Drum-Pack-50-samples_Media_3UPfwIIxeZ0_009_128k.mp3"
const TRAVEL_TIME := 1.65
const SPAWN_Y := 118.0
const JUDGEMENT_Y := 620.0
const HIGHWAY_TOP_RATIO := 0.68
const PERFECT_WINDOW := 0.060
const GREAT_WINDOW := 0.110
const GOOD_WINDOW := 0.180
const MISS_WINDOW := 0.220
const FAR_KID_FIRST_NOTE := 1.254
const HIT_EFFECT_DURATION := 0.68
const MAX_LIFE := 100.0
const LIFE_DRAIN_PER_SECOND := 0.055
const LIFE_RECOVERY := [2.8, 1.7, 0.7]
const LIFE_DAMAGE_BAD := 4.0
const LIFE_DAMAGE_MISS := 10.0
const SCORES_PATH := "user://beatforge_scores.json"
const CUSTOM_DIFFICULTIES := ["EASY", "NORMAL", "HARD", "EXPERT"]
const DRUM_SAMPLE_STARTS := [0.451, 0.979, 1.357, 1.740]
const DRUM_SAMPLE_LENGTHS := [0.43, 0.26, 0.33, 0.34]
const TAP_SERIAL_PORT := "auto"
const TAP_UDP_PORT := 4242

const LANE_KEYS := ["D", "F", "J", "K"]
const LANE_COLORS := [
	Color("#3B82F6"),
	Color("#8B5CF6"),
	Color("#F97316"),
	Color("#FACC15")
]
const KEY_TO_LANE := {
	KEY_D: 0,
	KEY_LEFT: 0,
	KEY_F: 1,
	KEY_DOWN: 1,
	KEY_J: 2,
	KEY_UP: 2,
	KEY_K: 3,
	KEY_RIGHT: 3
}
const CUSTOM_LEVELS_PATH := "res://levels/custom_levels.json"
const BUILTIN_LEVEL_COUNT := 3
const BRAND_NAME := "PULSORA"
const BRAND_TAGLINE := "NEON RHYTHM LAB"
const COLOR_BACKGROUND := Color("#0F172A")
const COLOR_BLUE := Color("#3B82F6")
const COLOR_GREEN := Color("#22C55E")
const COLOR_YELLOW := Color("#FACC15")
const COLOR_ORANGE := Color("#F97316")
const COLOR_RED := Color("#EF4444")
const COLOR_WHITE := Color("#F8FAFC")
const COLOR_PANEL := Color("#1E293B")
const COLOR_LIGHT := Color("#CBD5E1")
const COLOR_VIOLET := Color("#8B5CF6")

var levels: Array = [
	{
		"title": "THIS LOVE",
		"subtitle": "Maroon 5",
		"difficulty": "NORMAL",
		"rank": 0,
		"bpm": 95.10,
		"bpm_label": "95.10 BPM",
		"length": "03:26",
		"notes": "Intro, versos y coros / 4 carriles",
		"song_path": THIS_LOVE_PATH,
		"duration": 205.311,
		"offset": 0.5050,
		"chart_path": "res://levels/this_love_chart.json"
	},
	{
		"title": "YOU'RE GONNA GO FAR, KID",
		"subtitle": "The Offspring",
		"difficulty": "HARD",
		"rank": 2,
		"bpm": 126.20,
		"bpm_label": "126.20 BPM",
		"length": "02:58",
		"notes": "Contratiempos rapidos / 4 carriles",
		"song_path": FAR_KID_PATH,
		"duration": 178.200,
		"offset": 1.2540,
		"chart_path": "res://levels/far_kid_chart.json"
	},
	{
		"title": "HERO",
		"subtitle": "Skillet",
		"difficulty": "EXPERT",
		"rank": 3,
		"bpm": 142.00,
		"bpm_label": "142.00 BPM",
		"length": "03:17",
		"notes": "Alta densidad / dobles y cortes",
		"song_path": HERO_PATH,
		"duration": 196.812,
		"offset": 1.9740,
		"chart_path": "res://levels/hero_chart.json"
	}
]

var current_screen := Screen.MENU
var selected_level := 0
var menu_time := 0.0
var name_input := ""
var player_name := ""
var scores: Array = []
var custom_levels: Array = []
var new_song_files: Array = []
var new_song_index := 0
var new_song_bpm := "120"
var new_song_offset := "0.000"
var new_level_field := 0
var new_level_difficulty := 1
var delete_action := ""
var tap_udp: PacketPeerUDP
var tap_bridge_pid := -1
var tap_connected := false
var tap_last_seen := -10.0
var editor_time := 0.0
var editor_playing := false
var editor_subdivision := 1
var editor_message := "Chart automatico cargado"
var song_player: AudioStreamPlayer
var current_bpm := 94.83
var current_beat := 60.0 / 94.83
var current_song_offset := 0.3991
var current_song_path := THIS_LOVE_PATH
var current_chart_path := "res://levels/this_love_chart.json"
var song_length := 205.311
var audio_started := false

var chart: Array = []
var active_notes: Array = []
var chart_cursor := 0
var song_time := -3.0
var chart_end := 0.0
var is_paused := false
var level_finished := false
var game_over := false
var life := MAX_LIFE

var score := 0
var combo := 0
var max_combo := 0
var perfects := 0
var greats := 0
var goods := 0
var misses := 0
var judged_notes := 0

var lane_flash := [0.0, 0.0, 0.0, 0.0]
var feedback_text := ""
var feedback_color := Color.WHITE
var feedback_timer := 0.0
var pulse_timer := 0.0
var hit_effects: Array = []
var hit_sounds: Array = []
var streak_announcement_timer := 0.0
var streak_announcement_combo := 0
var streak_tier := 0
var streak_pulse := 0.0
var drum_sample_stream: AudioStream
var miss_sound: AudioStreamWAV
var shake_timer := 0.0
var shake_strength := 0.0
var shake_clock := 0.0
var side_flash_timer := 0.0
var side_flash_color := Color.WHITE
var fallback_font: Font


func _ready() -> void:
	fallback_font = ThemeDB.fallback_font
	_load_custom_levels()
	_add_pad_test_level()
	_load_scores()
	_select_level_data()
	_setup_song()
	_build_song_chart()
	_build_hit_sounds()
	_setup_drum_samples()
	miss_sound = _create_miss_sound()
	_start_tap_input()
	queue_redraw()


func _exit_tree() -> void:
	if tap_bridge_pid > 0:
		OS.kill(tap_bridge_pid)
		tap_bridge_pid = -1
	if tap_udp != null:
		tap_udp.close()
		tap_udp = null


func _start_tap_input() -> void:
	var port := TAP_SERIAL_PORT
	if port == "auto":
		port = _detect_tap_port()
	if port.is_empty():
		return
	tap_udp = PacketPeerUDP.new()
	if tap_udp.bind(TAP_UDP_PORT, "127.0.0.1") != OK:
		tap_udp = null
		return
	var bridge_path := ProjectSettings.globalize_path("res://tools/arduino_pad_bridge.py")
	var python_command := "python3"
	var python_args := PackedStringArray()
	if OS.get_name() == "Windows":
		python_command = "py"
		python_args.append("-3")
	python_args.append(bridge_path)
	python_args.append(port)
	python_args.append(str(TAP_UDP_PORT))
	tap_bridge_pid = OS.create_process(python_command, python_args)
	if tap_bridge_pid < 0:
		tap_udp.close()
		tap_udp = null


func _detect_tap_port() -> String:
	# pyserial discovers COM, ttyACM and ttyUSB ports across supported OSes.
	return "auto"

func _poll_tap_udp() -> void:
	if tap_udp == null:
		return
	while tap_udp.get_available_packet_count() > 0:
		var packet := tap_udp.get_packet().get_string_from_ascii().strip_edges()
		tap_last_seen = Time.get_ticks_msec() / 1000.0
		if packet == "R":
			tap_connected = true
		elif packet.length() == 1 and packet >= "1" and packet <= "4":
			tap_connected = true
			if current_screen == Screen.GAME:
				_press_lane(int(packet) - 1)


func _process(delta: float) -> void:
	_poll_tap_udp()
	if tap_connected and Time.get_ticks_msec() / 1000.0 - tap_last_seen > 2.5:
		tap_connected = false
	if current_screen == Screen.MENU or current_screen == Screen.NAME_ENTRY or current_screen == Screen.SCORES:
		menu_time += delta
	elif current_screen == Screen.EDITOR:
		_update_editor(delta)
	else:
		if not is_paused and not level_finished:
			if song_time < 0.0:
				song_time += delta
				if song_time >= 0.0:
					song_time = 0.0
					_start_song_audio()
			elif audio_started and song_player != null:
				# This compensates the audio mix buffer so the visual line and the
				# audible beat use the same clock.
				if song_player.playing:
					song_time = song_player.get_playback_position() + AudioServer.get_time_since_last_mix()
				else:
					# AudioStreamPlayer stops at the end instead of advancing its clock.
					song_time = maxf(song_time, song_length)
			else:
				song_time += delta
			if song_time >= 0.0 and not _is_pad_test_level():
				life = maxf(0.0, life - delta * LIFE_DRAIN_PER_SECOND)
			_update_song(delta)
			if not level_finished:
				_spawn_notes()
				_update_misses()
			if life <= 0.0 and not level_finished and not _is_pad_test_level():
				_finish_level(false)

	for lane in range(LANE_COUNT):
		lane_flash[lane] = maxf(0.0, lane_flash[lane] - delta)
	_update_hit_effects(delta)
	streak_announcement_timer = maxf(0.0, streak_announcement_timer - delta)
	streak_pulse = maxf(0.0, streak_pulse - delta * 2.4)
	shake_timer = maxf(0.0, shake_timer - delta)
	shake_clock += delta
	side_flash_timer = maxf(0.0, side_flash_timer - delta)
	feedback_timer = maxf(0.0, feedback_timer - delta)
	pulse_timer = maxf(0.0, pulse_timer - delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if current_screen == Screen.EDITOR:
		_handle_editor_input(event)
		return
	if current_screen == Screen.NAME_ENTRY:
		_handle_name_input(event)
		return
	if current_screen == Screen.NEW_LEVEL:
		_handle_new_level_input(event)
		return
	if current_screen == Screen.DELETE_CONFIRM:
		_handle_delete_confirm_input(event)
		return
	if current_screen == Screen.SCORES:
		_handle_scores_input(event)
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode

	if current_screen == Screen.MENU:
		_handle_menu_key(keycode)
		return

	if keycode == KEY_ESCAPE:
		_return_to_menu()
		return
	if keycode == KEY_R:
		_start_level()
		return
	if keycode == KEY_SPACE and not level_finished:
		is_paused = not is_paused
		if song_player != null:
			song_player.stream_paused = is_paused
		return
	if KEY_TO_LANE.has(keycode):
		_press_lane(int(KEY_TO_LANE[keycode]))


func _handle_menu_key(keycode: int) -> void:
	if keycode == KEY_UP or keycode == KEY_W:
		selected_level = maxi(0, selected_level - 1)
	elif keycode == KEY_DOWN or keycode == KEY_S:
		selected_level = mini(levels.size() - 1, selected_level + 1)
	elif keycode == KEY_ENTER or keycode == KEY_SPACE:
		_open_name_entry()
	elif keycode == KEY_E:
		_enter_editor()
	elif keycode == KEY_T:
		current_screen = Screen.SCORES
	elif keycode == KEY_N:
		_open_new_level()
	elif keycode == KEY_X:
		_open_delete_confirmation("song")
	elif keycode == KEY_C:
		_open_delete_confirmation("chart")


func _open_delete_confirmation(action: String) -> void:
	if action == "song" and (selected_level < BUILTIN_LEVEL_COUNT or _is_pad_test_level()):
		return
	delete_action = action
	current_screen = Screen.DELETE_CONFIRM


func _handle_delete_confirm_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	if keycode == KEY_ENTER or keycode == KEY_Y:
		if delete_action == "song":
			_delete_selected_song()
		else:
			_clear_selected_chart()
		delete_action = ""
		current_screen = Screen.MENU
	elif keycode == KEY_ESCAPE or keycode == KEY_N:
		delete_action = ""
		current_screen = Screen.MENU


func _delete_selected_song() -> void:
	if selected_level < BUILTIN_LEVEL_COUNT or selected_level >= levels.size() or _is_pad_test_level():
		return
	var level: Dictionary = levels[selected_level]
	var song_path := str(level.song_path)
	var chart_path := str(level.chart_path)
	for index in range(custom_levels.size() - 1, -1, -1):
		if str(custom_levels[index].song_path) == song_path:
			custom_levels.remove_at(index)
	levels.remove_at(selected_level)
	_remove_project_file(song_path)
	_remove_project_file(chart_path)
	_save_custom_levels()
	_remove_scores_for_level(selected_level)
	selected_level = clampi(selected_level, 0, levels.size() - 1)
	_select_level_data()
	_setup_song()
	_build_song_chart()


func _clear_selected_chart() -> void:
	chart.clear()
	chart_end = song_length
	var file := FileAccess.open(str(levels[selected_level].chart_path), FileAccess.WRITE)
	if file != null:
		file.store_string("[]")
		file.close()


func _remove_project_file(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _remove_scores_for_level(level_index: int) -> void:
	var remaining_scores: Array = []
	for entry in scores:
		var entry_level := int(entry.level)
		if entry_level == level_index:
			continue
		if entry_level > level_index:
			entry.level = entry_level - 1
		remaining_scores.append(entry)
	scores = remaining_scores
	_save_scores()


func _open_name_entry() -> void:
	current_screen = Screen.NAME_ENTRY
	name_input = player_name


func _handle_name_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	if keycode == KEY_ESCAPE:
		current_screen = Screen.MENU
	elif keycode == KEY_BACKSPACE:
		if not name_input.is_empty():
			name_input = name_input.left(name_input.length() - 1)
	elif keycode == KEY_ENTER:
		var clean_name := name_input.strip_edges()
		if not clean_name.is_empty():
			player_name = clean_name.left(12)
			_start_level()
	else:
		if key_event.unicode >= 32 and key_event.unicode <= 126 and name_input.length() < 12:
			name_input += String.chr(key_event.unicode)


func _handle_scores_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	if keycode == KEY_ESCAPE or keycode == KEY_T:
		current_screen = Screen.MENU
	elif keycode == KEY_UP or keycode == KEY_W:
		selected_level = maxi(0, selected_level - 1)
	elif keycode == KEY_DOWN or keycode == KEY_S:
		selected_level = mini(levels.size() - 1, selected_level + 1)


func _enter_editor() -> void:
	_select_level_data()
	_setup_song()
	_build_song_chart()
	current_screen = Screen.EDITOR
	editor_time = current_song_offset
	editor_playing = false
	if song_player != null:
		song_player.stop()
		song_player.stream_paused = false
	editor_message = "Listo para editar"


func _start_level(use_current_chart: bool = false) -> void:
	if not use_current_chart:
		_select_level_data()
		_setup_song()
		_build_song_chart()
	current_screen = Screen.GAME
	if song_player != null:
		song_player.stop()
		song_player.stream_paused = false
	audio_started = false
	song_time = -3.0
	chart_cursor = 0
	active_notes.clear()
	is_paused = false
	level_finished = false
	score = 0
	combo = 0
	max_combo = 0
	perfects = 0
	greats = 0
	goods = 0
	misses = 0
	judged_notes = 0
	life = MAX_LIFE
	game_over = false
	feedback_text = ""
	feedback_timer = 0.0
	hit_effects.clear()
	shake_timer = 0.0
	shake_strength = 0.0
	side_flash_timer = 0.0
	for lane in range(LANE_COUNT):
		lane_flash[lane] = 0.0


func _return_to_menu() -> void:
	current_screen = Screen.MENU
	is_paused = false
	level_finished = false
	active_notes.clear()
	editor_playing = false
	if song_player != null:
		song_player.stop()
		song_player.stream_paused = false
	audio_started = false


func _handle_editor_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		var timeline := _editor_timeline_rect()
		if timeline.has_point(mouse_event.position):
			var time := _snap_editor_time(_editor_time_at(mouse_event.position.x, timeline))
			var lane_height := timeline.size.y / LANE_COUNT
			var lane := int((mouse_event.position.y - timeline.position.y) / lane_height)
			if lane >= 0 and lane < LANE_COUNT:
				if mouse_event.button_index == MOUSE_BUTTON_LEFT:
					_toggle_editor_note(time, lane)
				elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
					_remove_editor_note(time, lane)
				elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
					_set_editor_time(time)
			else:
				_set_editor_time(time)
		return

	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	if keycode == KEY_ESCAPE:
		_return_to_menu()
	elif keycode == KEY_SPACE:
		_toggle_editor_playback()
	elif keycode == KEY_S:
		_save_chart()
	elif keycode == KEY_L:
		if _load_chart_file():
			_apply_hard_mode_accents()
			editor_message = "Chart cargado"
		else:
			editor_message = "Todavia no hay un chart guardado"
	elif keycode == KEY_1:
		editor_subdivision = 1
		editor_message = "Snap: negras"
	elif keycode == KEY_2:
		editor_subdivision = 2
		editor_message = "Snap: corcheas"
	elif keycode == KEY_3:
		editor_subdivision = 4
		editor_message = "Snap: semicorcheas"
	elif key_event.unicode == 91:
		_shift_all_chart_notes(-current_beat / 4.0)
	elif key_event.unicode == 93:
		_shift_all_chart_notes(current_beat / 4.0)
	elif keycode == KEY_ENTER:
		_start_level()


func _update_editor(delta: float) -> void:
	if not editor_playing or song_player == null:
		return
	editor_time = song_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	if not song_player.playing:
		editor_playing = false
		editor_time = minf(editor_time, song_length)
		editor_message = "Cancion terminada"


func _toggle_editor_playback() -> void:
	if song_player == null:
		editor_message = "No hay audio cargado"
		return
	if editor_playing:
		song_player.stream_paused = true
		editor_playing = false
		editor_message = "Pausado en %.2f s" % editor_time
	else:
		if editor_time >= song_length - 0.05:
			editor_time = 0.0
		song_player.play(editor_time)
		song_player.stream_paused = false
		editor_playing = true
		editor_message = "Reproduciendo"


func _set_editor_time(time: float) -> void:
	if editor_playing and song_player != null:
		song_player.stop()
		editor_playing = false
	editor_time = clampf(time, 0.0, song_length)
	editor_message = "Cursor en %.2f s" % editor_time


func _editor_timeline_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(72.0, 188.0, viewport_size.x - 144.0, 300.0)


func _editor_time_at(x: float, timeline: Rect2) -> float:
	var view_length := 12.0
	var view_start := clampf(editor_time - 4.0, 0.0, maxf(0.0, song_length - view_length))
	return view_start + clampf((x - timeline.position.x) / timeline.size.x, 0.0, 1.0) * view_length


func _snap_editor_time(time: float) -> float:
	var step := current_beat / float(editor_subdivision)
	var snapped: float = round((time - current_song_offset) / step) * step + current_song_offset
	return clampf(snapped, current_song_offset, song_length - 0.05)


func _toggle_editor_note(time: float, lane: int) -> void:
	var step := current_beat / float(editor_subdivision)
	for index in range(chart.size()):
		var note: Dictionary = chart[index]
		if int(note.lane) == lane and absf(float(note.time) - time) < step * 0.35:
			chart.remove_at(index)
			editor_message = "Nota borrada"
			return
	chart.append({"time": time, "lane": lane})
	_sort_chart()
	editor_message = "Nota colocada en %.2f s" % time


func _remove_editor_note(time: float, lane: int) -> void:
	var best_index := -1
	var best_distance := INF
	for index in range(chart.size()):
		var note: Dictionary = chart[index]
		if int(note.lane) != lane:
			continue
		var distance := absf(float(note.time) - time)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_index >= 0 and best_distance <= current_beat * 0.55:
		chart.remove_at(best_index)
		editor_message = "Nota borrada"
	else:
		editor_message = "No hay nota cerca"


func _shift_all_chart_notes(amount: float) -> void:
	for index in range(chart.size()):
		var note: Dictionary = chart[index]
		note.time = clampf(float(note.time) + amount, 0.0, song_length - 0.05)
		chart[index] = note
	_sort_chart()
	editor_time = clampf(editor_time + amount, 0.0, song_length)
	editor_message = "Todos los tiles %s %.3f s" % ["adelantados" if amount > 0.0 else "retrasados", absf(amount)]


func _save_chart() -> void:
	var file := FileAccess.open(current_chart_path, FileAccess.WRITE)
	if file == null:
		editor_message = "No se pudo guardar el chart"
		return
	file.store_string(JSON.stringify(chart))
	file.close()
	editor_message = "Chart guardado"


func _load_chart_file() -> bool:
	if not FileAccess.file_exists(current_chart_path):
		return false
	var file := FileAccess.open(current_chart_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return false
	var chart_shift := 0.0
	var first_source_time := -1.0
	if not parsed.is_empty() and parsed[0] is Dictionary:
		first_source_time = float(parsed[0].get("time", 0.0))
	if current_song_path == FAR_KID_PATH and first_source_time >= 0.0 and absf(first_source_time - FAR_KID_FIRST_NOTE) > 0.15:
		chart_shift = FAR_KID_FIRST_NOTE - first_source_time
	chart.clear()
	var loaded_at_time := {}
	for note in parsed:
		if note is Dictionary and note.has("time") and note.has("lane"):
			var source_time := float(note.time)
			var note_time := source_time + chart_shift
			if current_song_path == THIS_LOVE_PATH:
				note_time = 0.5050 + (source_time - 0.3991) * (60.0 / 94.83) / current_beat
			elif current_song_path == FAR_KID_PATH and not is_zero_approx(chart_shift):
				note_time = FAR_KID_FIRST_NOTE + (source_time - first_source_time) * (60.0 / 126.05) / current_beat
			note_time = clampf(note_time, 0.0, song_length)
			var time_key := "%.4f" % note_time
			var notes_at_time: Array = loaded_at_time.get(time_key, [])
			if notes_at_time.size() >= 2:
				continue
			if int(note.lane) in notes_at_time:
				continue
			notes_at_time.append(int(note.lane))
			loaded_at_time[time_key] = notes_at_time
			chart.append({
				"time": note_time,
				"lane": clampi(int(note.lane), 0, LANE_COUNT - 1)
			})
	_sort_chart()
	chart_end = song_length
	return true


func _sort_chart() -> void:
	chart.sort_custom(_sort_chart_notes)


func _sort_chart_notes(first: Dictionary, second: Dictionary) -> bool:
	return float(first.time) < float(second.time)


func _apply_hard_mode_accents() -> void:
	if _is_pad_test_level():
		return
	var rank := int(levels[selected_level].rank)
	if chart.is_empty():
		return
	var additions: Array = []
	var occupied := {}
	for note in chart:
		occupied["%.4f:%d" % [float(note.time), int(note.lane)]] = true
	for index in range(chart.size()):
		var note: Dictionary = chart[index]
		var same_time_count := 0
		for other in chart:
			if is_equal_approx(float(other.time), float(note.time)):
				same_time_count += 1
		if index % (24 if rank == 0 else 12 if rank < 3 else 10) == 0:
			var offbeat_time := float(note.time) + current_beat * 0.5
			var offbeat_lane := (int(note.lane) + 2 + int(index / 12)) % LANE_COUNT
			var offbeat_key := "%.4f:%d" % [offbeat_time, offbeat_lane]
			if offbeat_time < song_length - 0.05 and not occupied.has(offbeat_key):
				occupied[offbeat_key] = true
				additions.append({"time": offbeat_time, "lane": offbeat_lane})
	for note in additions:
		chart.append(note)
	_sort_chart()


func _update_song(delta: float) -> void:
	# The pulse gives the playfield a beat while the project has no song asset yet.
	if song_time >= current_song_offset:
		var beat_position := fmod(song_time - current_song_offset, current_beat)
		if beat_position < delta * 1.5:
			pulse_timer = 0.12

	var finish_time := song_length - 0.05
	if _is_pad_test_level():
		finish_time = chart_end + 1.0
	if song_time >= finish_time and chart_cursor >= chart.size():
		_finish_level(true)


func _finish_level(won: bool) -> void:
	if level_finished:
		return
	level_finished = true
	game_over = not won
	if song_player != null:
		song_player.stop()
		song_player.stream_paused = false
	audio_started = false
	if not _is_pad_test_level():
		_record_score()


func _record_score() -> void:
	if player_name.strip_edges().is_empty():
		return
	var normalized_name := player_name.strip_edges().to_lower()
	for index in range(scores.size()):
		var entry: Dictionary = scores[index]
		if int(entry.level) == selected_level and str(entry.name).to_lower() == normalized_name:
			if score > int(entry.score):
				entry.score = score
				entry.accuracy = _accuracy_percent()
				scores[index] = entry
				_save_scores()
			return
	scores.append({
		"name": player_name.strip_edges().left(12),
		"score": score,
		"accuracy": _accuracy_percent(),
		"level": selected_level
	})
	_scores_sort()
	if scores.size() > 50:
		scores.resize(50)
	_save_scores()


func _scores_sort() -> void:
	scores.sort_custom(_sort_score_entries)


func _sort_score_entries(first: Dictionary, second: Dictionary) -> bool:
	return int(first.score) > int(second.score)


func _load_scores() -> void:
	scores.clear()
	if not FileAccess.file_exists(SCORES_PATH):
		return
	var file := FileAccess.open(SCORES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return
	for entry in parsed:
		if entry is Dictionary and entry.has("name") and entry.has("score") and entry.has("level"):
			scores.append({
				"name": str(entry.name).left(12),
				"score": int(entry.score),
				"accuracy": float(entry.get("accuracy", 0.0)),
				"level": clampi(int(entry.level), 0, levels.size() - 1)
			})
	_scores_sort()


func _save_scores() -> void:
	var file := FileAccess.open(SCORES_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(scores))
	file.close()


func _load_custom_levels() -> void:
	custom_levels.clear()
	if not FileAccess.file_exists(CUSTOM_LEVELS_PATH):
		return
	var file := FileAccess.open(CUSTOM_LEVELS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return
	for entry in parsed:
		if not entry is Dictionary or not entry.has("song_path") or not entry.has("chart_path"):
			continue
		if not FileAccess.file_exists(str(entry.song_path)):
			continue
		var level: Dictionary = entry.duplicate(true)
		levels.append(level)
		custom_levels.append(level)


func _add_pad_test_level() -> void:
	levels.append({
		"title": "PAD TEST",
		"subtitle": "Prueba de cuatro sensores",
		"difficulty": "TEST",
		"rank": 0,
		"bpm": 95.10,
		"bpm_label": "95.10 BPM",
		"length": "00:11",
		"notes": "16 golpes alternados / D F J K",
		"song_path": THIS_LOVE_PATH,
		"duration": 205.311,
		"offset": 0.5050,
		"chart_path": PAD_TEST_CHART_PATH,
		"is_pad_test": true,
		"test_chart_end": 10.5
	})


func _is_pad_test_level() -> bool:
	return selected_level >= 0 and selected_level < levels.size() and bool(levels[selected_level].get("is_pad_test", false))


func _save_custom_levels() -> void:
	var file := FileAccess.open(CUSTOM_LEVELS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(custom_levels))
	file.close()


func _scan_new_song_files() -> void:
	new_song_files.clear()
	var directory := DirAccess.open("res://")
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.to_lower().ends_with(".mp3"):
			var song_path := "res://" + file_name
			var already_added := false
			for level in levels:
				if str(level.song_path) == song_path:
					already_added = true
					break
			if song_path != DRUM_SAMPLES_PATH and not already_added:
				new_song_files.append(song_path)
		file_name = directory.get_next()
	directory.list_dir_end()


func _open_new_level() -> void:
	_scan_new_song_files()
	new_song_index = 0
	new_level_field = 0
	new_song_bpm = "120"
	new_song_offset = "0.000"
	new_level_difficulty = 1
	current_screen = Screen.NEW_LEVEL


func _handle_new_level_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	if keycode == KEY_ESCAPE:
		current_screen = Screen.MENU
	elif keycode == KEY_TAB:
		new_level_field = (new_level_field + 1) % 4
	elif keycode == KEY_UP and new_level_field == 0:
		new_song_index = maxi(0, new_song_index - 1)
	elif keycode == KEY_DOWN and new_level_field == 0:
		new_song_index = mini(new_song_files.size() - 1, new_song_index + 1)
	elif keycode == KEY_LEFT and new_level_field == 3:
		new_level_difficulty = maxi(0, new_level_difficulty - 1)
	elif keycode == KEY_RIGHT and new_level_field == 3:
		new_level_difficulty = mini(CUSTOM_DIFFICULTIES.size() - 1, new_level_difficulty + 1)
	elif keycode == KEY_BACKSPACE and new_level_field > 0:
		if new_level_field == 1 and not new_song_bpm.is_empty():
			new_song_bpm = new_song_bpm.left(new_song_bpm.length() - 1)
		elif new_level_field == 2 and not new_song_offset.is_empty():
			new_song_offset = new_song_offset.left(new_song_offset.length() - 1)
	elif keycode == KEY_ENTER:
		_create_new_level()
	else:
		if key_event.unicode < 32 or key_event.unicode > 126:
			return
		var character := String.chr(key_event.unicode)
		if new_level_field == 1 and new_song_bpm.length() < 6 and (character.is_valid_int() or character == "."):
			new_song_bpm += character
		elif new_level_field == 2 and new_song_offset.length() < 8 and (character.is_valid_int() or character == "." or character == "-"):
			new_song_offset += character


func _create_new_level() -> void:
	if new_song_files.is_empty():
		return
	var bpm := float(new_song_bpm)
	var offset := float(new_song_offset)
	if bpm < 40.0 or bpm > 240.0:
		return
	var song_path: String = new_song_files[new_song_index]
	var audio = load(song_path)
	var duration := 180.0
	if audio is AudioStream:
		duration = maxf(1.0, audio.get_length())
	var base_name := song_path.get_file().get_basename().replace("_", " ").replace("-", " ")
	var slug := song_path.get_file().get_basename().to_lower().replace(" ", "_").replace("-", "_")
	var new_level := {
		"title": base_name.to_upper().left(28),
		"subtitle": "Custom song",
		"difficulty": CUSTOM_DIFFICULTIES[new_level_difficulty],
		"rank": new_level_difficulty,
		"bpm": bpm,
		"bpm_label": "%.2f BPM" % bpm,
		"length": "%02d:%02d" % [int(duration / 60.0), int(fmod(duration, 60.0))],
		"notes": "Chart nuevo / 4 carriles",
		"song_path": song_path,
		"duration": duration,
		"offset": offset,
		"chart_path": "res://levels/" + slug + "_chart.json"
	}
	levels.append(new_level)
	custom_levels.append(new_level)
	_save_custom_levels()
	selected_level = levels.size() - 1
	_select_level_data()
	_setup_song()
	# New levels intentionally start empty so the author places every hit by ear.
	chart.clear()
	chart_end = song_length
	_save_chart()
	current_screen = Screen.EDITOR
	editor_time = current_song_offset
	editor_playing = false
	editor_message = "Nuevo nivel creado"


func _spawn_notes() -> void:
	while chart_cursor < chart.size():
		var chart_note: Dictionary = chart[chart_cursor]
		if float(chart_note.time) > song_time + TRAVEL_TIME:
			break
		active_notes.append({
			"lane": int(chart_note.lane),
			"time": float(chart_note.time),
			"hit": false,
			"missed": false
		})
		chart_cursor += 1


func _update_misses() -> void:
	for index in range(active_notes.size()):
		var note: Dictionary = active_notes[index]
		if note.hit or note.missed:
			continue
		if song_time - float(note.time) > MISS_WINDOW:
			note.missed = true
			active_notes[index] = note
			_register_miss()


func _press_lane(lane: int) -> void:
	if level_finished or is_paused or song_time < -0.05:
		return

	var best_index := -1
	var best_distance := INF
	for index in range(active_notes.size()):
		var note: Dictionary = active_notes[index]
		if note.hit or note.missed or int(note.lane) != lane:
			continue
		var distance: float = absf(song_time - float(note.time))
		if distance <= GOOD_WINDOW and distance < best_distance:
			best_index = index
			best_distance = distance

	lane_flash[lane] = 0.14
	if best_index == -1:
		combo = 0
		if not _is_pad_test_level():
			life = maxf(0.0, life - LIFE_DAMAGE_BAD)
		_set_feedback("BAD", Color("#ff5e6c"))
		_spawn_hit_effect(lane, "BAD", Color("#ff5e6c"))
		_trigger_miss_response()
		_play_miss_sound()
		return

	var note: Dictionary = active_notes[best_index]
	note.hit = true
	active_notes[best_index] = note
	judged_notes += 1
	combo += 1
	max_combo = maxi(max_combo, combo)
	if combo == 8 or combo == 16 or combo == 32 or combo == 64:
		_trigger_streak_celebration(combo)
	var multiplier := _combo_multiplier()

	if best_distance <= PERFECT_WINDOW:
		perfects += 1
		score += int(300.0 * multiplier)
		life = minf(MAX_LIFE, life + LIFE_RECOVERY[0])
		_set_feedback("PERFECT", Color("#fff4a3"))
		_spawn_hit_effect(lane, "PERFECT", Color("#fff4a3"))
		_play_hit_sound(0, lane)
		_trigger_hit_response(Color("#fff4a3"), 6.0)
	elif best_distance <= GREAT_WINDOW:
		greats += 1
		score += int(200.0 * multiplier)
		life = minf(MAX_LIFE, life + LIFE_RECOVERY[1])
		_set_feedback("GREAT", Color("#8fffd6"))
		_spawn_hit_effect(lane, "GREAT", Color("#8fffd6"))
		_play_hit_sound(1, lane)
		_trigger_hit_response(Color("#8fffd6"), 4.5)
	else:
		goods += 1
		score += int(100.0 * multiplier)
		life = minf(MAX_LIFE, life + LIFE_RECOVERY[2])
		_set_feedback("GOOD", Color("#a9c7ff"))
		_spawn_hit_effect(lane, "GOOD", Color("#a9c7ff"))
		_play_hit_sound(2, lane)
		_trigger_hit_response(Color("#a9c7ff"), 3.0)


func _register_miss() -> void:
	misses += 1
	judged_notes += 1
	combo = 0
	streak_announcement_timer = 0.0
	streak_pulse = 0.0
	if not _is_pad_test_level():
		life = maxf(0.0, life - LIFE_DAMAGE_MISS)
	_set_feedback("MISS", Color("#ff5e6c"))
	_trigger_miss_response()
	_play_miss_sound()


func _set_feedback(text: String, color: Color) -> void:
	feedback_text = text
	feedback_color = color
	feedback_timer = 0.55


func _trigger_hit_response(color: Color, strength: float) -> void:
	var tier := _streak_tier_for(combo)
	shake_timer = 0.12 + minf(0.06, float(tier) * 0.015)
	shake_strength = strength + float(tier) * 0.7
	side_flash_timer = 0.30 + float(tier) * 0.05
	side_flash_color = color
	streak_pulse = maxf(streak_pulse, 0.35 + float(tier) * 0.12)


func _trigger_miss_response() -> void:
	shake_timer = 0.06
	shake_strength = 2.0
	side_flash_timer = 0.14
	side_flash_color = Color("#ff5e6c")
	streak_announcement_timer = 0.0
	streak_pulse = 0.0


func _combo_multiplier() -> float:
	var tier := _streak_tier_for(combo)
	return [1.0, 1.25, 1.5, 2.0, 2.5][tier]


func _streak_tier_for(value: int) -> int:
	if value >= 64:
		return 4
	if value >= 32:
		return 3
	if value >= 16:
		return 2
	if value >= 8:
		return 1
	return 0


func _trigger_streak_celebration(value: int) -> void:
	streak_tier = _streak_tier_for(value)
	streak_announcement_combo = value
	streak_announcement_timer = 1.25
	streak_pulse = 1.0
	shake_timer = 0.24 if streak_tier < 3 else 0.34
	shake_strength = 8.0 + float(streak_tier) * 2.5
	side_flash_timer = 0.55
	side_flash_color = [COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET, COLOR_WHITE][streak_tier]
	_play_streak_stinger(streak_tier)


func _spawn_hit_effect(lane: int, text: String, color: Color) -> void:
	hit_effects.append({
		"lane": lane,
		"text": text,
		"color": color,
		"combo": combo,
		"elapsed": 0.0
	})


func _update_hit_effects(delta: float) -> void:
	var index := hit_effects.size() - 1
	while index >= 0:
		var effect: Dictionary = hit_effects[index]
		effect.elapsed = float(effect.elapsed) + delta
		if effect.elapsed >= HIT_EFFECT_DURATION:
			hit_effects.remove_at(index)
		else:
			hit_effects[index] = effect
		index -= 1


func _build_hit_sounds() -> void:
	# Short, low-volume percussive taps keep the feedback clear without fighting
	# the music. They can later be replaced with recorded drum samples.
	hit_sounds = [
		_create_drum_hit(172.0, 0.82, 0.100, 0.30),
		_create_drum_hit(145.0, 0.58, 0.090, 0.25),
		_create_drum_hit(120.0, 0.36, 0.080, 0.21)
	]


func _play_streak_stinger(tier: int) -> void:
	var sample_rate := 22050
	var duration := 0.48 + float(tier) * 0.08
	var sample_count := int(duration * sample_rate)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	var low_frequency: float = [280.0, 330.0, 392.0, 440.0, 523.0][tier]
	var high_frequency: float = [620.0, 740.0, 880.0, 1046.0, 1318.0][tier]
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var progress := time / duration
		var frequency := lerpf(low_frequency, high_frequency, progress)
		var envelope := minf(1.0, progress * 12.0) * pow(1.0 - progress, 1.35)
		var tone := sin(TAU * frequency * time) * 0.72 + sin(TAU * frequency * 1.5 * time) * 0.28
		var sample := int(clampf(tone * envelope * 0.48, -1.0, 1.0) * 26000.0)
		samples[index * 2] = sample & 0xff
		samples[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -7.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _create_drum_hit(frequency: float, brightness: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var sample_count := int(duration * sample_rate)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var progress := time / duration
		var kick := sin(TAU * lerpf(frequency, 62.0, progress) * time) * exp(-time * 42.0)
		var rim := sin(TAU * (frequency * 2.4) * time) * exp(-time * 78.0) * brightness
		var noise := sin(float(index) * 12.731) * exp(-time * 105.0) * brightness * 0.22
		var sample := int(clampf((kick * 0.68 + rim * 0.24 + noise) * volume, -1.0, 1.0) * 28000.0)
		samples[index * 2] = sample & 0xff
		samples[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	return stream


func _play_hit_sound(grade: int, lane: int) -> void:
	if drum_sample_stream != null and lane >= 0 and lane < DRUM_SAMPLE_STARTS.size():
		var sample_player := AudioStreamPlayer.new()
		sample_player.stream = drum_sample_stream
		sample_player.volume_db = [-6.0, -8.0, -10.0][grade]
		add_child(sample_player)
		sample_player.play(DRUM_SAMPLE_STARTS[lane])
		var stop_time: float = DRUM_SAMPLE_LENGTHS[lane] + 0.03
		get_tree().create_timer(stop_time).timeout.connect(_stop_sample_player.bind(sample_player))
		return
	if grade < 0 or grade >= hit_sounds.size():
		return
	var player := AudioStreamPlayer.new()
	player.stream = hit_sounds[grade]
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _create_miss_sound() -> AudioStreamWAV:
	var sample_rate := 44100
	var duration := 0.14
	var sample_count := int(duration * sample_rate)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var progress := time / duration
		var muted_kick := sin(TAU * lerpf(118.0, 68.0, progress) * time) * exp(-time * 34.0)
		var low_rattle := sin(TAU * 91.0 * time) * exp(-time * 58.0)
		var sample := int(clampf(muted_kick * 0.42 + low_rattle * 0.12, -1.0, 1.0) * 25000.0)
		samples[index * 2] = sample & 0xff
		samples[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	return stream


func _play_miss_sound() -> void:
	if miss_sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = miss_sound
	player.volume_db = -5.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _stop_sample_player(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()
		player.queue_free()


func _select_level_data() -> void:
	var level: Dictionary = levels[selected_level]
	current_bpm = float(level.bpm)
	current_beat = 60.0 / current_bpm
	current_song_offset = float(level.offset)
	current_song_path = str(level.song_path)
	current_chart_path = str(level.chart_path)
	song_length = float(level.duration)


func _setup_song() -> void:
	var loaded_song = load(current_song_path)
	if loaded_song is AudioStream:
		if song_player == null:
			song_player = AudioStreamPlayer.new()
			add_child(song_player)
		song_player.stop()
		song_player.stream = loaded_song
		song_length = maxf(1.0, song_player.stream.get_length())
	else:
		push_warning("No se encontro la cancion en " + current_song_path + ". Se usara el reloj interno.")


func _setup_drum_samples() -> void:
	var loaded_samples = load(DRUM_SAMPLES_PATH)
	if loaded_samples is AudioStream:
		drum_sample_stream = loaded_samples
	else:
		push_warning("No se encontro el pack de bateria. Se usaran sonidos sinteticos.")


func _start_song_audio() -> void:
	if song_player == null:
		audio_started = false
		return
	song_player.play()
	audio_started = true


func _build_song_chart() -> void:
	chart.clear()
	# Initial chart for This Love. The section changes leave space in the intro,
	# add off-beats in verses, and use chords in the choruses.
	var total_beats := int((song_length - current_song_offset) / current_beat)
	for beat_index in range(total_beats):
		var beat_time := current_song_offset + float(beat_index) * current_beat
		var bar := int(beat_index / 4)
		if bar < 4:
			if beat_index % 2 == 0:
				_add_chart_note(beat_time, int(beat_index / 2) % LANE_COUNT)
		elif bar < 16:
			_add_chart_note(beat_time, (beat_index + bar) % LANE_COUNT)
			if beat_index % 4 == 3:
				_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 1) % LANE_COUNT)
		elif bar < 40:
			var chord: Array = [[0, 2], [1, 3], [0, 2], [1, 3]][beat_index % 4]
			for lane in chord:
				_add_chart_note(beat_time, int(lane))
			if beat_index % 2 == 1:
				_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 2) % LANE_COUNT)
		elif bar < 52:
			_add_chart_note(beat_time, (beat_index * 3 + bar) % LANE_COUNT)
			if beat_index % 4 == 1:
				_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 3) % LANE_COUNT)
		elif bar < 68:
			var chorus_chord: Array = [[0, 2], [1], [3], [0, 2]][beat_index % 4]
			for lane in chorus_chord:
				_add_chart_note(beat_time, int(lane))
			if beat_index % 2 == 0:
				_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 1) % LANE_COUNT)
		elif bar < 76:
			if beat_index % 2 == 0:
				_add_chart_note(beat_time, (int(beat_index / 2) + 1) % LANE_COUNT)
		else:
			_add_chart_note(beat_time, (beat_index + 2) % LANE_COUNT)
			if beat_index % 2 == 1:
				_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 3) % LANE_COUNT)

		var rank := int(levels[selected_level].rank)
		if rank >= 2 and bar >= 4 and beat_index % 2 == 0:
			_add_chart_note(beat_time + current_beat * 0.5, (beat_index + 2) % LANE_COUNT)
		if rank >= 3 and bar >= 8:
			_add_chart_note(beat_time + current_beat * 0.25, (beat_index + 1) % LANE_COUNT)
			if beat_index % 2 == 1:
				_add_chart_note(beat_time + current_beat * 0.75, (beat_index + 3) % LANE_COUNT)

	chart_end = song_length
	if _load_chart_file():
		editor_message = "Chart guardado cargado"
	if _is_pad_test_level():
		chart_end = float(levels[selected_level].test_chart_end)
	_apply_hard_mode_accents()


func _add_chart_note(time: float, lane: int) -> void:
	if time < song_length - 0.20:
		chart.append({"time": time, "lane": lane})


func _draw() -> void:
	if current_screen == Screen.MENU:
		_draw_menu()
	elif current_screen == Screen.NAME_ENTRY:
		_draw_name_entry()
	elif current_screen == Screen.NEW_LEVEL:
		_draw_new_level()
	elif current_screen == Screen.DELETE_CONFIRM:
		_draw_delete_confirmation()
	elif current_screen == Screen.EDITOR:
		_draw_editor()
	elif current_screen == Screen.SCORES:
		_draw_scores()
	else:
		var shake_amount := shake_timer / 0.12
		var shake := Vector2(
			sin(shake_clock * 91.0) * shake_strength * shake_amount,
			cos(shake_clock * 117.0) * shake_strength * shake_amount
		)
		draw_set_transform(shake, 0.0, Vector2.ONE)
		_draw_game()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_brand(position: Vector2, compact: bool) -> void:
	var radius := 18.0 if compact else 23.0
	draw_circle(position, radius + 5.0, Color(COLOR_VIOLET, 0.12))
	draw_arc(position, radius, -PI * 0.82, PI * 0.82, 24, COLOR_BLUE, 3.0)
	draw_arc(position, radius - 6.0, PI * 0.18, TAU * 0.82, 20, COLOR_GREEN, 2.0)
	draw_line(position + Vector2(-radius * 0.72, 0.0), position + Vector2(radius * 0.72, 0.0), COLOR_YELLOW, 2.0)
	draw_circle(position, 5.0, COLOR_ORANGE)
	var text_position := position + Vector2(radius + 15.0, 7.0)
	draw_string(fallback_font, text_position, BRAND_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28 if not compact else 22, COLOR_WHITE)
	if not compact:
		draw_string(fallback_font, text_position + Vector2(1.0, 22.0), BRAND_TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, COLOR_LIGHT)


func _draw_action_button(rect: Rect2, label: String, accent: Color) -> void:
	draw_rect(rect, Color("#111C34"))
	draw_rect(rect, Color(accent, 0.70), false, 2.0)
	draw_circle(rect.position + Vector2(15.0, rect.size.y * 0.5), 3.0, accent)
	draw_string(fallback_font, rect.position + Vector2(27.0, rect.size.y * 0.5 + 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 34.0, 13, COLOR_WHITE)


func _draw_menu() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	_draw_brand(Vector2(66.0, 48.0), false)

	draw_string(fallback_font, Vector2(66.0, 168.0), "SELECCION DE NIVEL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COLOR_WHITE)
	draw_string(fallback_font, Vector2(66.0, 195.0), "Elige una pista para comenzar", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_LIGHT)

	var card_size := Vector2(minf(700.0, viewport_size.x - 132.0), 210.0)
	var card_position := Vector2((viewport_size.x - card_size.x) * 0.5, 235.0)
	var card := Rect2(card_position, card_size)
	draw_rect(card, COLOR_PANEL)
	draw_rect(card, COLOR_BLUE, false, 2.0)
	draw_rect(Rect2(card_position, Vector2(7.0, card_size.y)), LANE_COLORS[selected_level % LANE_COUNT])

	var level: Dictionary = levels[selected_level]
	draw_string(fallback_font, card_position + Vector2(34.0, 50.0), "%02d" % (selected_level + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COLOR_LIGHT)
	draw_string(fallback_font, card_position + Vector2(92.0, 51.0), str(level.title), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 27, COLOR_WHITE)
	draw_string(fallback_font, card_position + Vector2(92.0, 78.0), str(level.subtitle), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_LIGHT)
	draw_string(fallback_font, card_position + Vector2(34.0, 132.0), "DIFICULTAD  " + str(level.difficulty), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_GREEN)
	draw_string(fallback_font, card_position + Vector2(220.0, 132.0), str(level.bpm_label), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_YELLOW)
	draw_string(fallback_font, card_position + Vector2(350.0, 132.0), str(level.length), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_LIGHT)
	draw_string(fallback_font, card_position + Vector2(34.0, 174.0), str(level.notes), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_LIGHT)
	draw_string(fallback_font, card_position + Vector2(card_size.x - 260.0, 174.0), "ENTER  JUGAR    E  EDITOR", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, COLOR_WHITE)
	var button_y := card_position.y + card_size.y + 24.0
	var button_width := (card_size.x - 18.0) / 4.0
	_draw_action_button(Rect2(card_position.x, button_y, button_width, 42.0), "ENTER  JUGAR", COLOR_GREEN)
	_draw_action_button(Rect2(card_position.x + button_width + 6.0, button_y, button_width, 42.0), "E  EDITAR", COLOR_VIOLET)
	_draw_action_button(Rect2(card_position.x + (button_width + 6.0) * 2.0, button_y, button_width, 42.0), "N  NUEVO", COLOR_ORANGE)
	_draw_action_button(Rect2(card_position.x + (button_width + 6.0) * 3.0, button_y, button_width, 42.0), "T  TABLA", COLOR_BLUE)

	draw_string(fallback_font, Vector2(66.0, viewport_size.y - 46.0), "ARRIBA / ABAJO seleccionar    ENTER jugar    E editor    N nuevo    X borrar cancion    C borrar chart    T tabla", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))
	draw_string(fallback_font, Vector2(viewport_size.x - 260.0, viewport_size.y - 46.0), "NIVEL  %02d / %02d" % [selected_level + 1, levels.size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#6678aa"))
	if tap_connected:
		draw_circle(Vector2(viewport_size.x - 380.0, viewport_size.y - 51.0), 5.0, COLOR_GREEN)
		draw_string(fallback_font, Vector2(viewport_size.x - 370.0, viewport_size.y - 46.0), "PAD ARDUINO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_GREEN)


func _draw_name_entry() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	var level: Dictionary = levels[selected_level]
	_draw_brand(Vector2(66.0, 48.0), false)
	draw_string(fallback_font, Vector2(66.0, 168.0), "PREPARA TU PARTIDA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_LIGHT)
	var panel := Rect2((viewport_size.x - 620.0) * 0.5, 190.0, 620.0, 265.0)
	draw_rect(panel, Color("#101a36"))
	draw_rect(panel, Color("#806a45"), false, 2.0)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 48.0), "NOMBRE DEL JUGADOR", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 18, Color("#d8e2ff"))
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 83.0), str(level.title), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 16, Color("#ffc857"))
	var typed_name := name_input
	if int(menu_time * 2.0) % 2 == 0:
		typed_name += "_"
	draw_rect(Rect2(panel.position.x + 95.0, panel.position.y + 115.0, panel.size.x - 190.0, 52.0), Color("#090e20"))
	draw_string(fallback_font, Vector2(panel.position.x + 105.0, panel.position.y + 150.0), typed_name, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 210.0, 24, Color.WHITE)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 215.0), "ENTER comenzar    BACKSPACE borrar    ESC cancelar", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 14, Color("#a9b8df"))
	draw_string(fallback_font, Vector2(66.0, viewport_size.y - 46.0), "Escribe hasta 12 caracteres", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))


func _draw_new_level() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	_draw_brand(Vector2(66.0, 48.0), false)
	draw_string(fallback_font, Vector2(66.0, 168.0), "NUEVO NIVEL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_LIGHT)
	var panel := Rect2((viewport_size.x - 780.0) * 0.5, 150.0, 780.0, 390.0)
	draw_rect(panel, Color("#101a36"))
	draw_rect(panel, Color("#806a45"), false, 2.0)
	if new_song_files.is_empty():
		draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 105.0), "No hay MP3 nuevos", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 27, Color("#ffcf78"))
		draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 155.0), "Copia una cancion en la carpeta del proyecto y vuelve a abrir esta pantalla", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 14, Color("#a9b8df"))
	else:
		draw_string(fallback_font, panel.position + Vector2(34.0, 48.0), "CANCION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#a9b8df"))
		draw_string(fallback_font, panel.position + Vector2(34.0, 83.0), str(new_song_files[new_song_index]).get_file(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 18, Color.WHITE)
		var bpm_color := Color("#ffc857") if new_level_field == 1 else Color("#a9b8df")
		var offset_color := Color("#ffc857") if new_level_field == 2 else Color("#a9b8df")
		var difficulty_color := Color("#ffc857") if new_level_field == 3 else Color("#a9b8df")
		draw_string(fallback_font, panel.position + Vector2(34.0, 145.0), "BPM  " + new_song_bpm, HORIZONTAL_ALIGNMENT_LEFT, 280.0, 20, bpm_color)
		draw_string(fallback_font, panel.position + Vector2(360.0, 145.0), "OFFSET  " + new_song_offset + " s", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 20, offset_color)
		draw_string(fallback_font, panel.position + Vector2(34.0, 198.0), "DIFICULTAD  " + CUSTOM_DIFFICULTIES[new_level_difficulty], HORIZONTAL_ALIGNMENT_LEFT, 330.0, 20, difficulty_color)
		draw_string(fallback_font, panel.position + Vector2(34.0, 238.0), "El nivel se creara con el chart completamente vacio", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 14, Color("#778bbd"))
		draw_string(fallback_font, panel.position + Vector2(34.0, 286.0), "TAB campo    ARRIBA/ABAJO cancion    IZQ/DER dificultad", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 14, Color("#8296c9"))
		draw_string(fallback_font, panel.position + Vector2(34.0, 306.0), "ENTER crear y abrir editor    ESC cancelar", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 16, Color("#8fffd6"))
	draw_string(fallback_font, Vector2(66.0, viewport_size.y - 46.0), "El BPM define el snap del editor; el offset marca el primer golpe", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))


func _draw_delete_confirmation() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	var level: Dictionary = levels[selected_level]
	var panel := Rect2((viewport_size.x - 680.0) * 0.5, 190.0, 680.0, 250.0)
	draw_rect(panel, Color("#101a36"))
	draw_rect(panel, Color("#ff5e6c"), false, 2.0)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 52.0), "CONFIRMAR ELIMINACION", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 22, Color("#f2f5ff"))
	if delete_action == "song":
		draw_string(fallback_font, Vector2(panel.position.x + 35.0, panel.position.y + 105.0), "Se borrara la cancion y todo su chart:", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 70.0, 16, Color("#ffcf78"))
	else:
		draw_string(fallback_font, Vector2(panel.position.x + 35.0, panel.position.y + 105.0), "Se borraran todas las notas del chart:", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 70.0, 16, Color("#ffcf78"))
	draw_string(fallback_font, Vector2(panel.position.x + 35.0, panel.position.y + 140.0), str(level.title), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 70.0, 20, Color.WHITE)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 205.0), "ENTER o Y confirmar    ESC o N cancelar", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 15, Color("#a9b8df"))
	draw_string(fallback_font, Vector2(66.0, viewport_size.y - 46.0), "La accion no se puede deshacer", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#ff5e6c"))


func _draw_scores() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	var level: Dictionary = levels[selected_level]
	_draw_brand(Vector2(66.0, 48.0), false)
	draw_string(fallback_font, Vector2(66.0, 168.0), "TABLA DE PUNTUACIONES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_LIGHT)
	draw_string(fallback_font, Vector2(66.0, 154.0), "ARRIBA / ABAJO cambia de nivel", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#778bbd"))
	draw_string(fallback_font, Vector2(viewport_size.x - 280.0, 154.0), str(level.title), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#ffc857"))

	var level_scores: Array = []
	for entry in scores:
		if int(entry.level) == selected_level:
			level_scores.append(entry)
	level_scores.sort_custom(_sort_score_entries)
	var panel := Rect2((viewport_size.x - 760.0) * 0.5, 180.0, 760.0, 390.0)
	draw_rect(panel, Color("#101a36"))
	draw_rect(panel, Color("#536aa5"), false, 2.0)
	for row in range(10):
		var y := panel.position.y + 42.0 + row * 32.0
		if row % 2 == 0:
			draw_rect(Rect2(panel.position.x + 2.0, y - 23.0, panel.size.x - 4.0, 32.0), Color(0.20, 0.25, 0.42, 0.18))
		if row < level_scores.size():
			var entry: Dictionary = level_scores[row]
			draw_string(fallback_font, Vector2(panel.position.x + 28.0, y), "%02d" % (row + 1), HORIZONTAL_ALIGNMENT_LEFT, 35.0, 16, Color("#7f94ca"))
			draw_string(fallback_font, Vector2(panel.position.x + 90.0, y), str(entry.name), HORIZONTAL_ALIGNMENT_LEFT, 310.0, 17, Color.WHITE)
			draw_string(fallback_font, Vector2(panel.position.x + 470.0, y), "%07d" % int(entry.score), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 17, Color("#ffc857"))
			draw_string(fallback_font, Vector2(panel.position.x + 620.0, y), "%.1f%%" % float(entry.accuracy), HORIZONTAL_ALIGNMENT_LEFT, 90.0, 15, Color("#8fffd6"))
		else:
			draw_string(fallback_font, Vector2(panel.position.x + 90.0, y), "--", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#536383"))
	draw_string(fallback_font, Vector2(66.0, viewport_size.y - 46.0), "T o ESC volver al menu", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))


func _draw_editor() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_animated_background(viewport_size, menu_time)
	_draw_brand(Vector2(48.0, 34.0), true)
	draw_string(fallback_font, Vector2(180.0, 42.0), "LEVEL EDITOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, COLOR_WHITE)
	var editor_level: Dictionary = levels[selected_level]
	draw_string(fallback_font, Vector2(36.0, 64.0), str(editor_level.title) + "  /  " + str(editor_level.bpm_label), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8296c9"))

	var timeline := _editor_timeline_rect()
	draw_rect(timeline, Color("#0b1227"))
	draw_rect(timeline, Color("#536aa5"), false, 2.0)
	var lane_height := timeline.size.y / LANE_COUNT
	for lane in range(LANE_COUNT):
		var row := Rect2(timeline.position.x, timeline.position.y + lane * lane_height, timeline.size.x, lane_height)
		if lane % 2 == 0:
			draw_rect(row, Color(0.10, 0.16, 0.31, 0.32))
		draw_line(row.position, Vector2(row.end.x, row.position.y), Color("#26385f"), 1.0)
		draw_string(fallback_font, row.position + Vector2(12.0, lane_height * 0.5 + 6.0), LANE_KEYS[lane], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, LANE_COLORS[lane])

	var view_length := 12.0
	var view_start := clampf(editor_time - 4.0, 0.0, maxf(0.0, song_length - view_length))
	var first_beat := int(floor((view_start - current_song_offset) / current_beat)) - 1
	var last_beat := int(ceil((view_start + view_length - current_song_offset) / current_beat)) + 1
	for beat_index in range(first_beat, last_beat + 1):
		var beat_time := current_song_offset + float(beat_index) * current_beat
		if beat_time < 0.0 or beat_time > song_length:
			continue
		var x := timeline.position.x + (beat_time - view_start) / view_length * timeline.size.x
		var strong := beat_index % 4 == 0
		draw_line(Vector2(x, timeline.position.y), Vector2(x, timeline.end.y), Color(0.62, 0.72, 0.94, 0.36 if strong else 0.16), 2.0 if strong else 1.0)
		if strong:
			draw_string(fallback_font, Vector2(x + 5.0, timeline.position.y - 8.0), "BAR %02d" % int(beat_index / 4 + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8296c9"))

	for note in chart:
		var note_time: float = float(note.time)
		if note_time < view_start - current_beat or note_time > view_start + view_length + current_beat:
			continue
		var note_x := timeline.position.x + (note_time - view_start) / view_length * timeline.size.x
		var lane := int(note.lane)
		var note_y := timeline.position.y + lane_height * (lane + 0.5)
		draw_rect(Rect2(note_x - 6.0, note_y - 15.0, 12.0, 30.0), LANE_COLORS[lane])
		draw_rect(Rect2(note_x - 3.0, note_y - 11.0, 6.0, 22.0), Color(1, 1, 1, 0.44))

	var cursor_x := timeline.position.x + (editor_time - view_start) / view_length * timeline.size.x
	draw_line(Vector2(cursor_x, timeline.position.y - 18.0), Vector2(cursor_x, timeline.end.y + 5.0), Color("#fff4a3"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cursor_x - 7.0, timeline.position.y - 18.0),
		Vector2(cursor_x + 7.0, timeline.position.y - 18.0),
		Vector2(cursor_x, timeline.position.y - 7.0)
	]), Color("#fff4a3"))

	draw_string(fallback_font, Vector2(72.0, 126.0), "TIMELINE  %.2f s / %.2f s" % [editor_time, song_length], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#d8e2ff"))
	draw_string(fallback_font, Vector2(viewport_size.x - 320.0, 126.0), "NOTAS  %03d" % chart.size(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#8fffd6"))
	draw_string(fallback_font, Vector2(72.0, 530.0), "Click izquierdo: colocar/quitar    Click derecho: borrar    Click central: mover cursor", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#a9b8df"))
	draw_string(fallback_font, Vector2(72.0, 562.0), "ESPACIO %s    1 negras    2 corcheas    3 semicorcheas" % ("PAUSAR" if editor_playing else "REPRODUCIR"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))
	draw_string(fallback_font, Vector2(72.0, 588.0), "S guardar    L cargar    [ retrasar    ] adelantar    ENTER probar    ESC menu", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8296c9"))
	draw_string(fallback_font, Vector2(72.0, 635.0), editor_message, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#ffc857"))
	_draw_action_button(Rect2(72.0, 652.0, 160.0, 38.0), "ESPACIO  PLAY", COLOR_GREEN)
	_draw_action_button(Rect2(242.0, 652.0, 160.0, 38.0), "S  GUARDAR", COLOR_BLUE)
	_draw_action_button(Rect2(412.0, 652.0, 190.0, 38.0), "[ ]  MOVER TILES", COLOR_ORANGE)
	_draw_action_button(Rect2(612.0, 652.0, 190.0, 38.0), "ENTER  PROBAR", COLOR_VIOLET)


func _draw_game() -> void:
	var viewport_size := get_viewport_rect().size
	var field_width := minf(760.0, viewport_size.x - 48.0)
	var field_left := (viewport_size.x - field_width) * 0.5
	var top_width := field_width * HIGHWAY_TOP_RATIO
	var highway_bottom := JUDGEMENT_Y + 36.0

	_draw_animated_background(viewport_size, maxf(0.0, song_time))
	_draw_side_flash(viewport_size)
	_draw_header(viewport_size)

	# The highway narrows toward the stage, leaving the upper area free for a
	# future animated video or character backdrop.
	var highway := PackedVector2Array([
		Vector2(field_left + (field_width - top_width) * 0.5, SPAWN_Y),
		Vector2(field_left + (field_width + top_width) * 0.5, SPAWN_Y),
		Vector2(field_left + field_width, highway_bottom),
		Vector2(field_left, highway_bottom)
	])
	draw_colored_polygon(highway, Color("#0B1224"))
	_draw_streak_aura(viewport_size, field_left, field_width)
	var current_tier := _streak_tier_for(combo)
	var streak_color: Color = [COLOR_BLUE, COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET][current_tier]
	var streak_energy := clampf(float(combo) / 64.0, 0.0, 1.0)

	for row in range(9):
		var progress := float(row) / 8.0
		var y := lerpf(SPAWN_Y, highway_bottom, progress)
		var width_at := lerpf(top_width, field_width, progress)
		var left_at := field_left + (field_width - width_at) * 0.5
		var grid_alpha := 0.32 + streak_energy * 0.22
		draw_line(Vector2(left_at, y), Vector2(left_at + width_at, y), Color(streak_color, grid_alpha), 1.0 + streak_energy)

	for lane in range(1, LANE_COUNT):
		var top_x := field_left + (field_width - top_width) * 0.5 + top_width * float(lane) / LANE_COUNT
		var bottom_x := field_left + field_width * float(lane) / LANE_COUNT
		draw_line(Vector2(top_x, SPAWN_Y), Vector2(bottom_x, highway_bottom), Color("#334B78"), 2.0)

	var left_top := field_left + (field_width - top_width) * 0.5
	var right_top := left_top + top_width
	draw_line(Vector2(left_top, SPAWN_Y), Vector2(field_left, highway_bottom), COLOR_BLUE.lerp(streak_color, streak_energy), 3.0 + streak_energy * 2.0)
	draw_line(Vector2(right_top, SPAWN_Y), Vector2(field_left + field_width, highway_bottom), COLOR_VIOLET.lerp(streak_color, streak_energy), 3.0 + streak_energy * 2.0)

	# Notes use the same perspective interpolation as the highway lines.
	for note in active_notes:
		if note.hit or note.missed:
			continue
		var note_time: float = float(note.time)
		var progress := 1.0 - (note_time - song_time) / TRAVEL_TIME
		var y := lerpf(SPAWN_Y, JUDGEMENT_Y, progress)
		if y < SPAWN_Y - 35.0 or y > viewport_size.y + 30.0:
			continue
		var lane := int(note.lane)
		var width_at := lerpf(top_width, field_width, clampf(progress, 0.0, 1.0))
		var lane_width := width_at / LANE_COUNT
		var center_x := field_left + (field_width - width_at) * 0.5 + lane_width * (lane + 0.5)
		var note_width := lane_width * 0.72
		var note_height := lerpf(10.0, 26.0, clampf(progress, 0.0, 1.0))
		var gem := PackedVector2Array([
			Vector2(center_x - note_width * 0.5, y),
			Vector2(center_x - note_width * 0.30, y - note_height * 0.5),
			Vector2(center_x + note_width * 0.30, y - note_height * 0.5),
			Vector2(center_x + note_width * 0.5, y),
			Vector2(center_x + note_width * 0.30, y + note_height * 0.5),
			Vector2(center_x - note_width * 0.30, y + note_height * 0.5)
		])
		var shadow_gem := PackedVector2Array()
		for point in gem:
			shadow_gem.append(point + Vector2(0.0, 4.0))
		draw_colored_polygon(shadow_gem, Color(0, 0, 0, 0.40))
		draw_colored_polygon(gem, LANE_COLORS[lane])
		if current_tier > 0:
			for edge in range(gem.size()):
				draw_line(gem[edge], gem[(edge + 1) % gem.size()], Color(streak_color, 0.36 + streak_energy * 0.54), 1.0 + current_tier * 0.45)
		draw_line(Vector2(center_x - note_width * 0.28, y - note_height * 0.25), Vector2(center_x + note_width * 0.28, y - note_height * 0.25), Color(1, 1, 1, 0.60), 2.0)

	# Receptors sit at the wide end of the highway.
	var receptor_lane_width := field_width / LANE_COUNT
	draw_rect(Rect2(field_left - 22.0, JUDGEMENT_Y - 25.0, field_width + 44.0, 74.0), COLOR_PANEL)
	draw_rect(Rect2(field_left - 22.0, JUDGEMENT_Y - 25.0, field_width + 44.0, 74.0), COLOR_VIOLET, false, 2.0)
	draw_line(Vector2(field_left - 8.0, JUDGEMENT_Y + 28.0), Vector2(field_left + field_width + 8.0, JUDGEMENT_Y + 28.0), Color("#334155"), 2.0)
	var line_color := COLOR_WHITE if pulse_timer > 0.0 else COLOR_BLUE
	draw_line(Vector2(field_left - 10.0, JUDGEMENT_Y), Vector2(field_left + field_width + 10.0, JUDGEMENT_Y), line_color, 3.0)
	for lane in range(LANE_COUNT):
		var center_x := field_left + receptor_lane_width * (lane + 0.5)
		var press_amount: float = lane_flash[lane] / 0.14
		var radius := minf(29.0, receptor_lane_width * 0.30) + press_amount * (8.0 + current_tier * 2.0)
		var receptor_color: Color = LANE_COLORS[lane]
		if lane_flash[lane] <= 0.0:
			receptor_color = Color(receptor_color, 0.38 + streak_energy * 0.22)
		draw_circle(Vector2(center_x, JUDGEMENT_Y), radius + 12.0 + streak_energy * 10.0, Color(receptor_color, 0.05 + streak_energy * 0.10 + press_amount * 0.10))
		draw_circle(Vector2(center_x, JUDGEMENT_Y), radius, Color(0.03, 0.07, 0.16, 0.95))
		draw_arc(Vector2(center_x, JUDGEMENT_Y), radius, 0.0, TAU, 28, receptor_color, 4.0)
		if current_tier > 0:
			var arc_start := fmod(shake_clock * (0.7 + current_tier * 0.22) + lane * 1.2, TAU)
			draw_arc(Vector2(center_x, JUDGEMENT_Y), radius + 7.0, arc_start, arc_start + PI * 0.65, 18, Color(streak_color, 0.52 + streak_energy * 0.35), 2.0)
		draw_circle(Vector2(center_x, JUDGEMENT_Y), radius * 0.30, receptor_color)
		draw_string(fallback_font, Vector2(center_x - receptor_lane_width * 0.5, JUDGEMENT_Y + 56.0), LANE_KEYS[lane], HORIZONTAL_ALIGNMENT_CENTER, receptor_lane_width, 17, COLOR_WHITE)
	_draw_hit_effects(field_left, field_width)

	if song_time < 0.0:
		var countdown := str(ceil(-song_time))
		if song_time > -0.15:
			countdown = "GO"
		draw_string(fallback_font, Vector2(field_left, 370.0), countdown, HORIZONTAL_ALIGNMENT_CENTER, field_width, 56, Color.WHITE)
	elif feedback_timer > 0.0:
		var feedback_size := 24 + int(feedback_timer * 8.0)
		draw_string(fallback_font, Vector2(field_left, 520.0), feedback_text, HORIZONTAL_ALIGNMENT_CENTER, field_width, feedback_size, feedback_color)

	if is_paused:
		draw_rect(Rect2(field_left, SPAWN_Y, field_width, highway_bottom - SPAWN_Y), Color(0.02, 0.03, 0.08, 0.84))
		draw_string(fallback_font, Vector2(field_left, 360.0), "PAUSA", HORIZONTAL_ALIGNMENT_CENTER, field_width, 42, Color.WHITE)
		draw_string(fallback_font, Vector2(field_left, 397.0), "ESPACIO para continuar", HORIZONTAL_ALIGNMENT_CENTER, field_width, 16, Color("#a9b8df"))

	if level_finished:
		_draw_results(field_left, field_width)
	elif streak_announcement_timer > 0.0 and not is_paused:
		_draw_streak_announcement(viewport_size)


func _draw_streak_aura(viewport_size: Vector2, field_left: float, field_width: float) -> void:
	if combo < 4 and streak_pulse <= 0.0:
		return
	var tier := _streak_tier_for(combo)
	var energy := maxf(clampf(float(combo) / 64.0, 0.0, 1.0), streak_pulse * 0.65)
	var color: Color = [COLOR_BLUE, COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET][tier]
	var orbit_time := shake_clock * (0.12 + energy * 0.10)
	for side in range(2):
		var x := field_left - 30.0 if side == 0 else field_left + field_width + 30.0
		var center := Vector2(x, viewport_size.y * 0.56)
		for ring in range(3):
			var radius := 25.0 + ring * 14.0 + sin(orbit_time + ring) * (2.0 + streak_pulse * 4.0)
			draw_arc(center, radius, orbit_time + ring * 1.7, orbit_time + ring * 1.7 + PI * 1.45, 28, Color(color, 0.16 + energy * 0.30), 1.5 + energy * 2.0)
		for mote in range(4):
			var angle := orbit_time * (1.0 if mote % 2 == 0 else -1.0) + float(mote) * TAU / 4.0
			var point := center + Vector2.from_angle(angle) * (58.0 + 5.0 * sin(orbit_time * 2.0 + mote))
			draw_circle(point, 2.0 + energy * 2.5, Color(color, 0.35 + energy * 0.55))


func _draw_streak_announcement(viewport_size: Vector2) -> void:
	var alpha := minf(1.0, streak_announcement_timer / 0.20)
	var tier_titles := ["", "LA LLAMA DESPIERTA", "RITUAL ENCADENADO", "MAMBO MISTICO", "LEYENDA VIVA"]
	var tier_colors: Array = [COLOR_GREEN, COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET]
	var color: Color = tier_colors[streak_tier]
	var panel_width := minf(650.0, viewport_size.x - 64.0)
	var panel := Rect2((viewport_size.x - panel_width) * 0.5, viewport_size.y * 0.37, panel_width, 104.0)
	draw_rect(panel, Color(COLOR_BACKGROUND, 0.86 * alpha))
	draw_rect(panel, Color(color, 0.72 * alpha), false, 2.0)
	draw_line(panel.position + Vector2(22.0, 8.0), Vector2(panel.end.x - 22.0, panel.position.y + 8.0), Color(COLOR_YELLOW, alpha * 0.8), 2.0)
	draw_line(Vector2(panel.position.x + 22.0, panel.end.y - 8.0), panel.end - Vector2(22.0, 8.0), Color(COLOR_VIOLET, alpha * 0.8), 2.0)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 43.0), "RACHA  x%d" % streak_announcement_combo, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 18, Color(COLOR_YELLOW, alpha))
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 78.0), tier_titles[streak_tier], HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 30, Color(color, alpha))
	var flare := 0.3 + streak_pulse * 0.7
	for side in range(2):
		var x := panel.position.x + 30.0 if side == 0 else panel.end.x - 30.0
		var y := panel.position.y + panel.size.y * 0.5
		draw_circle(Vector2(x, y), 4.0 + flare * 5.0, Color(color, alpha * 0.28))
		draw_arc(Vector2(x, y), 12.0 + flare * 8.0, shake_clock, shake_clock + TAU * 0.75, 20, Color(color, alpha), 2.0)


func _draw_hit_effects(field_left: float, field_width: float) -> void:
	var lane_width := field_width / LANE_COUNT
	for effect in hit_effects:
		var progress: float = float(effect.elapsed) / HIT_EFFECT_DURATION
		var alpha := 1.0 - progress
		var lane := int(effect.lane)
		var tier := _streak_tier_for(int(effect.get("combo", 0)))
		var center := Vector2(field_left + lane_width * (lane + 0.5), JUDGEMENT_Y)
		var radius := 28.0 + progress * (82.0 + tier * 14.0)
		var color: Color = effect.color
		if tier > 0:
			color = color.lerp([COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET][mini(tier - 1, 3)], 0.25 + float(tier) * 0.10)
		draw_arc(center, radius, 0.0, TAU, 36, Color(color, alpha), 4.0 - progress * 2.0 + tier * 0.4)
		if tier >= 2:
			draw_arc(center, radius * 0.72, -progress * TAU, -progress * TAU + PI * 1.3, 32, Color(color, alpha * 0.78), 2.0)
		draw_circle(center, 8.0 + (1.0 - progress) * 12.0, Color(color, alpha * 0.28))
		var ray_count := 8 + tier * 4
		for ray in range(ray_count):
			var angle := TAU * float(ray) / float(ray_count) + progress * 0.18
			var ray_start := center + Vector2.from_angle(angle) * (radius * 0.72)
			var ray_end := center + Vector2.from_angle(angle) * (radius + 13.0 + tier * 4.0)
			draw_line(ray_start, ray_end, Color(color, alpha * 0.72), 2.0 + tier * 0.35)
			if tier >= 2 and ray % 2 == 0:
				draw_circle(ray_end, 1.5 + alpha * 1.5, Color(COLOR_WHITE, alpha * 0.85))
		var text_y := JUDGEMENT_Y - 48.0 - progress * 32.0
		var text_size := 14 + int((1.0 - progress) * 5.0)
		draw_string(fallback_font, Vector2(center.x - lane_width * 0.5, text_y), str(effect.text), HORIZONTAL_ALIGNMENT_CENTER, lane_width, text_size, Color(color, alpha))


func _draw_side_flash(viewport_size: Vector2) -> void:
	if side_flash_timer <= 0.0:
		return
	var alpha := side_flash_timer / 0.30 * 0.24
	var color := Color(side_flash_color, alpha)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 90.0),
		Vector2(42.0, 90.0),
		Vector2(78.0, viewport_size.y),
		Vector2(0.0, viewport_size.y)
	]), color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(viewport_size.x, 90.0),
		Vector2(viewport_size.x - 42.0, 90.0),
		Vector2(viewport_size.x - 78.0, viewport_size.y),
		Vector2(viewport_size.x, viewport_size.y)
	]), color)


func _draw_animated_background(viewport_size: Vector2, animation_time: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), COLOR_BACKGROUND)
	draw_rect(Rect2(0.0, 100.0, viewport_size.x, viewport_size.y - 100.0), Color("#111D35"))
	var pulse := 0.5 + 0.5 * sin(animation_time * 2.0)
	var center := Vector2(viewport_size.x * 0.72, viewport_size.y * 0.28)
	draw_circle(center, 210.0 + pulse * 18.0, Color(COLOR_VIOLET, 0.035))
	draw_circle(center, 125.0 + pulse * 10.0, Color(COLOR_BLUE, 0.045))
	for ring in range(3):
		var radius := 74.0 + ring * 27.0 + pulse * (3.0 + ring)
		var rotation := animation_time * (0.06 if ring % 2 == 0 else -0.045)
		draw_arc(center, radius, rotation, rotation + PI * (1.48 if ring % 2 == 0 else 1.22), 48, Color(COLOR_YELLOW if ring == 1 else COLOR_VIOLET, 0.09 + pulse * 0.025), 1.0 + ring * 0.35)
	for mark in range(12):
		var angle := TAU * float(mark) / 12.0 + animation_time * 0.035
		var inner := center + Vector2.from_angle(angle) * 78.0
		var outer := center + Vector2.from_angle(angle) * 89.0
		draw_line(inner, outer, Color(COLOR_ORANGE, 0.14), 1.0)
	for x in range(0, int(viewport_size.x) + 1, 48):
		draw_line(Vector2(x, 100.0), Vector2(x, viewport_size.y), Color(0.20, 0.32, 0.52, 0.10), 1.0)
	for y in range(116, int(viewport_size.y), 48):
		draw_line(Vector2(0.0, y), Vector2(viewport_size.x, y), Color(0.20, 0.32, 0.52, 0.10), 1.0)
	for index in range(7):
		var x := 36.0 + index * 180.0
		var height := 20.0 + fmod(animation_time * (8.0 + index), 42.0)
		draw_line(Vector2(x, viewport_size.y - 36.0), Vector2(x, viewport_size.y - 36.0 - height), Color(COLOR_BLUE, 0.18), 3.0)
		if index % 2 == 0:
			draw_circle(Vector2(x, viewport_size.y - 36.0 - height), 3.0, Color(COLOR_GREEN, 0.60))


func _draw_header(viewport_size: Vector2) -> void:
	_draw_brand(Vector2(48.0, 34.0), true)
	var game_level: Dictionary = levels[selected_level]
	draw_string(fallback_font, Vector2(36.0, 62.0), str(game_level.title) + "  /  " + str(game_level.bpm_label), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_LIGHT)
	var accuracy := _accuracy_percent()
	var streak_colors: Array = [COLOR_LIGHT, COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_VIOLET]
	var current_tier := _streak_tier_for(combo)
	draw_string(fallback_font, Vector2(viewport_size.x - 265.0, 36.0), "SCORE %07d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COLOR_WHITE)
	draw_string(fallback_font, Vector2(viewport_size.x - 265.0, 59.0), "%d COMBO  x%.2f  %.1f%%" % [combo, _combo_multiplier(), accuracy], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, streak_colors[current_tier])
	var meter := Rect2(viewport_size.x * 0.5 - 108.0, 92.0, 216.0, 5.0)
	draw_rect(meter, Color(COLOR_PANEL, 0.9))
	draw_rect(Rect2(meter.position, Vector2(meter.size.x * clampf(float(combo) / 64.0, 0.0, 1.0), meter.size.y)), streak_colors[current_tier])
	for milestone in [8, 16, 32, 64]:
		var tick_x := meter.position.x + meter.size.x * float(milestone) / 64.0
		draw_line(Vector2(tick_x, meter.position.y - 3.0), Vector2(tick_x, meter.end.y + 3.0), COLOR_WHITE, 1.0)
	draw_string(fallback_font, Vector2(viewport_size.x - 265.0, 80.0), "VIDA %03d" % int(life), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, COLOR_GREEN)
	draw_rect(Rect2(viewport_size.x - 215.0, 70.0, 180.0, 12.0), Color("#0B1224"))
	var life_color := COLOR_GREEN if life > 35.0 else COLOR_RED
	draw_rect(Rect2(viewport_size.x - 215.0, 70.0, 180.0 * life / MAX_LIFE, 12.0), life_color)
	draw_rect(Rect2(viewport_size.x - 215.0, 70.0, 180.0, 12.0), COLOR_LIGHT, false, 1.0)
	draw_string(fallback_font, Vector2(34.0, viewport_size.y - 24.0), "D F J K / FLECHAS tocar    ESPACIO pausa    ESC menu    R reiniciar", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_LIGHT)


func _draw_results(field_left: float, field_width: float) -> void:
	var panel := Rect2(field_left + 90.0, 205.0, field_width - 180.0, 290.0)
	draw_rect(panel, COLOR_PANEL)
	draw_rect(panel, COLOR_BLUE, false, 2.0)
	var result_title := "GAME OVER" if game_over else "NIVEL COMPLETADO"
	var result_color := COLOR_RED if game_over else COLOR_GREEN
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 54.0), result_title, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 30, result_color)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 82.0), str(player_name), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 14, COLOR_LIGHT)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 102.0), "SCORE  %07d" % score, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 24, COLOR_YELLOW)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 143.0), "PERFECT %d    GREAT %d    GOOD %d    MISS %d" % [perfects, greats, goods, misses], HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 15, COLOR_LIGHT)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 185.0), "MAX COMBO  %d    ACCURACY  %.1f%%" % [max_combo, _accuracy_percent()], HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 17, COLOR_WHITE)
	draw_string(fallback_font, Vector2(panel.position.x, panel.position.y + 238.0), "R reiniciar    ESC menu", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 16, COLOR_GREEN)


func _accuracy_percent() -> float:
	if judged_notes == 0:
		return 100.0
	var weighted := perfects * 300.0 + greats * 200.0 + goods * 100.0
	return weighted / (judged_notes * 300.0) * 100.0
