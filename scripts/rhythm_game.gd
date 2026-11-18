extends Node2D

## Four-lane rhythm prototype with a menu and a Guitar Hero-style highway.
## The chart is kept as song time + lane, independent from the visuals.

enum Screen { MENU, NAME_ENTRY, GAME, EDITOR, SCORES, NEW_LEVEL, DELETE_CONFIRM }

const LANE_COUNT := 4
const FAR_KID_PATH := "res://YTDown.com_YouTube_You-re-Gonna-Go-Far-Kid_Media_pmZKkb_UAg_009_128k.mp3"
const PAD_TEST_CHART_PATH := "res://levels/pad_test_chart.json"
const DRUM_SAMPLES_PATH := "res://YTDown.com_YouTube_Free-Acoustic-Drum-Pack-50-samples_Media_3UPfwIIxeZ0_009_128k.mp3"
const TRAVEL_TIME := 1.65
const SPAWN_Y := 104.0
const JUDGEMENT_Y := 620.0
const HIGHWAY_TOP_RATIO := 0.50
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
const SETTINGS_PATH := "user://pulsora_settings.json"
const CLOCK_SNAP_THRESHOLD := 0.09
const CLOCK_SMOOTHING := 0.18
const SHORT_LENGTH := 120.0
const SHORT_MIN_SONG := 135.0
const SHORT_FADE := 4.0

const LANE_KEYS := ["D", "F", "J", "K"]
const LANE_COLORS := [
	Color("#38BDF8"),
	Color("#C084FC"),
	Color("#FB7185"),
	Color("#FACC15")
]
const TIER_COLORS := [
	Color("#38BDF8"),
	Color("#34D399"),
	Color("#FACC15"),
	Color("#FB923C"),
	Color("#E879F9")
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
const BUILTIN_LEVEL_COUNT := 1
const BRAND_NAME := "PULSORA"
const BRAND_TAGLINE := "NEON RHYTHM LAB"
const COLOR_BACKGROUND := Color("#060914")
const COLOR_BLUE := Color("#3B82F6")
const COLOR_GREEN := Color("#22C55E")
const COLOR_YELLOW := Color("#FACC15")
const COLOR_ORANGE := Color("#F97316")
const COLOR_RED := Color("#EF4444")
const COLOR_WHITE := Color("#F8FAFC")
const COLOR_PANEL := Color("#0E1530")
const COLOR_ACCENT := Color("#22D3EE")
const COLOR_PINK := Color("#F472B6")
const COLOR_MUTED := Color("#7C8DB5")
const COLOR_LIGHT := Color("#CBD5E1")
const COLOR_VIOLET := Color("#8B5CF6")

var levels: Array = [
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
var tap_flash := [0.0, 0.0, 0.0, 0.0]
var tap_counts := [0, 0, 0, 0]
var editor_time := 0.0
var editor_playing := false
var editor_subdivision := 1
var editor_message := "Chart automatico cargado"
var song_player: AudioStreamPlayer
var current_bpm := 94.83
var current_beat := 60.0 / 94.83
var current_song_offset := 0.3991
var current_song_path := FAR_KID_PATH
var current_chart_path := "res://levels/far_kid_chart.json"
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
var sync_calibration := 0.0
var clock_stamp_usec := 0
var autoplay := false
var play_short := false
var run_short := false
var audio_start_pos := 0.0
var autoplay_pressed := {}
var g_left := 0.0
var g_width := 0.0
var g_top_w := 0.0
var g_bottom := 0.0


func _ready() -> void:
	fallback_font = _make_font()
	_load_settings()
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
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		play_short = "--short" in OS.get_cmdline_user_args()
		print("AUDIO output_latency=%.1fms mix_rate=%d" % [AudioServer.get_output_latency() * 1000.0, int(AudioServer.get_mix_rate())])
		player_name = "BOT"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--level="):
				selected_level = clampi(int(arg.substr(8)), 0, levels.size() - 1)
		_start_level()
	queue_redraw()


func _exit_tree() -> void:
	if autoplay:
		print("AUTOPLAY level=%s song_time=%.1f notes=%d score=%d perfect=%d great=%d good=%d miss=%d maxcombo=%d" % [str(levels[selected_level].title), song_time, chart.size(), score, perfects, greats, goods, misses, max_combo])
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
	python_args.append(str(OS.get_process_id()))
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
			tap_flash[int(packet) - 1] = 0.35
			tap_counts[int(packet) - 1] += 1
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
				if song_player.playing:
					_advance_song_clock(delta)
				else:
					# AudioStreamPlayer stops at the end instead of advancing its clock.
					song_time = maxf(song_time, song_length)
			else:
				song_time += delta
			clock_stamp_usec = Time.get_ticks_usec()
			if autoplay:
				_run_autoplay()
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
		tap_flash[lane] = maxf(0.0, tap_flash[lane] - delta)
	_update_hit_effects(delta)
	streak_announcement_timer = maxf(0.0, streak_announcement_timer - delta)
	streak_pulse = maxf(0.0, streak_pulse - delta * 2.4)
	shake_timer = maxf(0.0, shake_timer - delta)
	shake_clock += delta
	side_flash_timer = maxf(0.0, side_flash_timer - delta)
	feedback_timer = maxf(0.0, feedback_timer - delta)
	pulse_timer = maxf(0.0, pulse_timer - delta)
	queue_redraw()


func _make_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI Semibold", "Segoe UI", "Arial", "Noto Sans", "DejaVu Sans"])
	font.font_weight = 600
	return font


func _raw_audio_time() -> float:
	# Position + time since the last mix, minus the output latency, is the moment
	# the listener actually hears the current sample.
	return song_player.get_playback_position() - audio_start_pos + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() - sync_calibration


func _advance_song_clock(delta: float) -> void:
	# The audio position only updates once per mix chunk, so raw readings jitter.
	# Advance with the frame delta and gently steer toward the audio clock; snap
	# only when the two disagree a lot (seek, stall, first frames).
	var target := _raw_audio_time()
	var predicted := song_time + delta
	var diff := target - predicted
	if absf(diff) > CLOCK_SNAP_THRESHOLD:
		song_time = target
	else:
		song_time = predicted + diff * CLOCK_SMOOTHING


func _press_time() -> float:
	# Timestamp a key press at the moment it happened, not at the last frame.
	var elapsed := float(Time.get_ticks_usec() - clock_stamp_usec) / 1000000.0
	return song_time + clampf(elapsed, 0.0, 0.05)


func _adjust_calibration(amount: float) -> void:
	sync_calibration = clampf(sync_calibration + amount, -0.300, 0.300)
	_save_settings()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		sync_calibration = clampf(float(parsed.get("sync_calibration", 0.0)), -0.300, 0.300)


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"sync_calibration": sync_calibration}))
	file.close()


func _run_autoplay() -> void:
	# Test bot: presses each note when its time arrives (command line: -- --autoplay).
	for note in active_notes:
		if note.hit or note.missed:
			continue
		var key := "%.4f:%d" % [float(note.time), int(note.lane)]
		if song_time >= float(note.time) and not autoplay_pressed.has(key):
			autoplay_pressed[key] = true
			_press_lane(int(note.lane))


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
		_start_level(false, not run_short)
		return
	if keycode == KEY_SPACE and not level_finished:
		is_paused = not is_paused
		if song_player != null:
			song_player.stream_paused = is_paused
		return
	if is_paused and (keycode == KEY_LEFT or keycode == KEY_RIGHT):
		_adjust_calibration(-0.005 if keycode == KEY_LEFT else 0.005)
		return
	if KEY_TO_LANE.has(keycode):
		_press_lane(int(KEY_TO_LANE[keycode]))


func _handle_menu_key(keycode: int) -> void:
	if keycode == KEY_UP or keycode == KEY_W:
		selected_level = maxi(0, selected_level - 1)
	elif keycode == KEY_DOWN or keycode == KEY_S:
		selected_level = mini(levels.size() - 1, selected_level + 1)
	elif keycode == KEY_TAB:
		play_short = not play_short
	elif keycode == KEY_LEFT:
		_adjust_calibration(-0.005)
	elif keycode == KEY_RIGHT:
		_adjust_calibration(0.005)
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
	if keycode == KEY_TAB:
		play_short = not play_short
	elif keycode == KEY_ESCAPE or keycode == KEY_T:
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


func _short_available(level: Dictionary) -> bool:
	return not bool(level.get("is_pad_test", false)) and float(level.duration) >= SHORT_MIN_SONG


func _apply_short_cut() -> void:
	# Pick the busiest 2-minute window, starting on a bar line, and rebase the
	# chart so the game clock starts at 0 at the beginning of that window.
	var bar := current_beat * 4.0
	var first := fposmod(current_song_offset, bar)
	var max_start := song_length - SHORT_LENGTH
	var best_start := 0.0
	var best_count := -1
	var candidate := first
	while candidate <= max_start + 0.001:
		var count := 0
		for note in chart:
			var note_time := float(note.time)
			if note_time >= candidate and note_time < candidate + SHORT_LENGTH:
				count += 1
		if count > best_count:
			best_count = count
			best_start = candidate
		candidate += bar
	var shifted: Array = []
	for note in chart:
		var note_time := float(note.time)
		if note_time >= best_start and note_time < best_start + SHORT_LENGTH - 0.5:
			shifted.append({"time": note_time - best_start, "lane": int(note.lane)})
	if autoplay:
		print("SHORT window start=%.2fs notes=%d of %d" % [best_start, shifted.size(), chart.size()])
	chart = shifted
	audio_start_pos = best_start
	current_song_offset -= best_start
	song_length = SHORT_LENGTH
	chart_end = song_length


func _start_level(use_current_chart: bool = false, force_full: bool = false) -> void:
	if not use_current_chart:
		_select_level_data()
		_setup_song()
		_build_song_chart()
	run_short = play_short and not force_full and _short_available(levels[selected_level])
	audio_start_pos = 0.0
	if run_short:
		_apply_short_cut()
	current_screen = Screen.GAME
	if song_player != null:
		song_player.stop()
		song_player.stream_paused = false
		song_player.volume_db = 0.0
	audio_started = false
	autoplay_pressed.clear()
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
		_start_level(false, true)


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
			if current_song_path == FAR_KID_PATH and not is_zero_approx(chart_shift):
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
	if _is_pad_test_level() or not bool(levels[selected_level].get("accents", false)):
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
	if run_short and audio_started and song_player != null and song_time > song_length - SHORT_FADE:
		song_player.volume_db = linear_to_db(clampf((song_length - song_time) / SHORT_FADE, 0.02, 1.0))
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
	if autoplay:
		return
	if player_name.strip_edges().is_empty():
		return
	var normalized_name := player_name.strip_edges().to_lower()
	for index in range(scores.size()):
		var entry: Dictionary = scores[index]
		if int(entry.level) == selected_level and bool(entry.get("short", false)) == run_short and str(entry.name).to_lower() == normalized_name:
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
		"short": run_short,
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
				"short": bool(entry.get("short", false)),
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
		"bpm": 126.20,
		"bpm_label": "126.20 BPM",
		"length": "00:11",
		"notes": "16 golpes alternados / D F J K",
		"song_path": FAR_KID_PATH,
		"duration": 178.200,
		"offset": 1.2540,
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
	# Drop notes that already left the screen so per-frame loops stay short.
	while not active_notes.is_empty():
		var oldest: Dictionary = active_notes[0]
		if (oldest.hit or oldest.missed) and song_time - float(oldest.time) > 0.6:
			active_notes.remove_at(0)
		else:
			break


func _press_lane(lane: int) -> void:
	if level_finished or is_paused or song_time < -0.05:
		return

	var best_index := -1
	var best_distance := INF
	var press_time := _press_time()
	for index in range(active_notes.size()):
		var note: Dictionary = active_notes[index]
		if note.hit or note.missed or int(note.lane) != lane:
			continue
		var distance: float = absf(press_time - float(note.time))
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
	if autoplay:
		print("MISS at song_time=%.3f" % song_time)
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
	song_player.volume_db = 0.0
	song_player.play(audio_start_pos)
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


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

func _t(pos: Vector2, text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(fallback_font, pos + Vector2(0.0, 2.0), text, align, width, size, Color(0.0, 0.0, 0.0, color.a * 0.55))
	draw_string(fallback_font, pos, text, align, width, size, color)


func _text_width(text: String, size: int) -> float:
	return fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


func _rrect_points(rect: Rect2, radius: float, segments: int = 5) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.42)
	var points := PackedVector2Array()
	if r < 0.8:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var centers := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r)
	]
	for corner in range(4):
		var center: Vector2 = centers[corner]
		var start_angle := -PI * 0.5 + PI * 0.5 * float(corner)
		for step in range(segments + 1):
			points.append(center + Vector2.from_angle(start_angle + PI * 0.5 * float(step) / float(segments)) * r)
	return points


func _rrect(rect: Rect2, radius: float, color: Color) -> void:
	draw_colored_polygon(_rrect_points(rect, radius), color)


func _rrect_line(rect: Rect2, radius: float, color: Color, width: float = 2.0) -> void:
	var points := _rrect_points(rect, radius)
	points.append(points[0])
	draw_polyline(points, color, width, true)


func _vgrad(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom])
	)


func _glow(center: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	for layer in range(12):
		var k := float(layer) / 11.0
		draw_circle(center, radius * (1.0 - k * 0.85), Color(color, strength * 0.016 * (1.0 + k * 1.5)))


func _panel(rect: Rect2, accent: Color, radius: float = 14.0) -> void:
	_rrect(Rect2(rect.position + Vector2(0.0, 5.0), rect.size), radius, Color(0.0, 0.0, 0.0, 0.35))
	_vgrad_rounded(rect, radius, Color(COLOR_PANEL, 0.96), Color("#080D20", 0.96))
	_rrect_line(rect, radius, Color(accent, 0.55), 1.5)
	draw_line(rect.position + Vector2(radius, 1.0), Vector2(rect.end.x - radius, rect.position.y + 1.0), Color(accent, 0.9), 2.0)


func _vgrad_rounded(rect: Rect2, radius: float, top: Color, bottom: Color) -> void:
	var points := _rrect_points(rect, radius)
	var colors := PackedColorArray()
	for point in points:
		colors.append(top.lerp(bottom, clampf((point.y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)))
	draw_polygon(points, colors)


func _chip(pos: Vector2, key: String, label: String, accent: Color = COLOR_ACCENT) -> float:
	var key_width := _text_width(key, 13) + 18.0
	_rrect(Rect2(pos, Vector2(key_width, 26.0)), 7.0, Color(accent, 0.20))
	_rrect_line(Rect2(pos, Vector2(key_width, 26.0)), 7.0, Color(accent, 0.85), 1.5)
	draw_string(fallback_font, pos + Vector2(0.0, 18.0), key, HORIZONTAL_ALIGNMENT_CENTER, key_width, 13, COLOR_WHITE)
	draw_string(fallback_font, pos + Vector2(key_width + 8.0, 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, COLOR_MUTED)
	return key_width + 8.0 + _text_width(label, 13) + 20.0


func _difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"EASY":
			return Color("#34D399")
		"NORMAL":
			return Color("#38BDF8")
		"HARD":
			return Color("#FB923C")
		"EXPERT":
			return Color("#F43F5E")
		"TEST":
			return Color("#C084FC")
	return COLOR_PINK


func _badge(pos: Vector2, text: String, color: Color) -> float:
	var width := _text_width(text, 12) + 20.0
	_rrect(Rect2(pos, Vector2(width, 22.0)), 11.0, Color(color, 0.22))
	_rrect_line(Rect2(pos, Vector2(width, 22.0)), 11.0, Color(color, 0.9), 1.3)
	draw_string(fallback_font, pos + Vector2(0.0, 16.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, 12, color)
	return width


func _best_score_for(level_index: int) -> int:
	var best := 0
	for entry in scores:
		if int(entry.level) == level_index and bool(entry.get("short", false)) == play_short:
			best = maxi(best, int(entry.score))
	return best


func _beat_pulse(time: float) -> float:
	if time < current_song_offset:
		return 0.0
	var phase := fmod(time - current_song_offset, current_beat) / current_beat
	return pow(1.0 - phase, 3.0)


func _draw_background(vs: Vector2, time: float, pulse: float, tint: Color, energy: float) -> void:
	_vgrad(Rect2(Vector2.ZERO, vs), Color("#04060F"), Color("#0B1230").lerp(Color(tint, 1.0), energy * 0.16))
	# Stage light beams swaying from the ceiling.
	for beam in range(6):
		var base_x := vs.x * (float(beam) + 0.5) / 6.0
		var sway := sin(time * 0.5 + float(beam) * 1.7) * 150.0
		var color: Color = LANE_COLORS[beam % LANE_COUNT]
		var alpha := 0.016 + pulse * 0.018 + energy * 0.022
		draw_colored_polygon(PackedVector2Array([
			Vector2(base_x - 10.0, 0.0), Vector2(base_x + 10.0, 0.0),
			Vector2(base_x + sway + 130.0, vs.y), Vector2(base_x + sway - 130.0, vs.y)
		]), Color(color, alpha))
	# Soft horizon glow behind the highway.
	_glow(Vector2(vs.x * 0.5, vs.y * 0.95), 560.0, tint, 0.45 + pulse * 0.4 + energy * 0.7)
	# Drifting dust.
	for index in range(46):
		var seed_value := float(index)
		var speed := 5.0 + fmod(seed_value * 7.0, 17.0)
		var x := fposmod(seed_value * 97.3 + time * (4.0 + fmod(seed_value, 5.0) * 2.5), vs.x)
		var y := fposmod(seed_value * 53.7 - time * speed, vs.y)
		var size := 0.8 + fmod(seed_value, 3.0) * 0.55
		draw_circle(Vector2(x, y), size, Color(COLOR_WHITE, 0.05 + 0.12 * fmod(seed_value * 0.37, 1.0)))


func _draw_brand(position: Vector2, compact: bool) -> void:
	var size := 20 if compact else 46
	_t(position, BRAND_NAME, size, COLOR_WHITE)
	var width := _text_width(BRAND_NAME, size)
	draw_line(position + Vector2(0.0, 8.0 if compact else 12.0), position + Vector2(width, 8.0 if compact else 12.0), Color(COLOR_ACCENT, 0.9), 3.0 if not compact else 2.0)
	draw_line(position + Vector2(width * 0.55, 8.0 if compact else 12.0), position + Vector2(width, 8.0 if compact else 12.0), Color(COLOR_PINK, 0.95), 3.0 if not compact else 2.0)
	if not compact:
		_t(position + Vector2(2.0, 38.0), BRAND_TAGLINE, 12, COLOR_MUTED)


func _draw_action_button(rect: Rect2, label: String, accent: Color) -> void:
	_rrect(rect, 10.0, Color(accent, 0.14))
	_rrect_line(rect, 10.0, Color(accent, 0.85), 1.5)
	draw_string(fallback_font, rect.position + Vector2(0.0, rect.size.y * 0.5 + 5.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, COLOR_WHITE)


# ---------------------------------------------------------------------------
# Menus
# ---------------------------------------------------------------------------

func _draw_screen_base(title: String, accent: Color = COLOR_ACCENT) -> Vector2:
	var vs := get_viewport_rect().size
	var pulse := 0.5 + 0.5 * sin(menu_time * 1.6)
	_draw_background(vs, menu_time, pulse * 0.35, accent, 0.25)
	_draw_brand(Vector2(56.0, 64.0), false)
	if not title.is_empty():
		_t(Vector2(56.0, 138.0), title, 15, accent)
	return vs


func _draw_menu() -> void:
	var vs := _draw_screen_base("", COLOR_VIOLET)
	_t(Vector2(60.0, 200.0), "ELIGE UNA CANCION", 15, COLOR_ACCENT)
	_t(Vector2(60.0, 246.0), "%02d / %02d" % [selected_level + 1, levels.size()], 34, COLOR_WHITE)
	var level: Dictionary = levels[selected_level]
	var diff_color := _difficulty_color(str(level.difficulty))
	_t(Vector2(60.0, 330.0), "MEJOR PUNTAJE (%s)" % ("2 MIN" if play_short else "COMPLETA"), 12, COLOR_MUTED)
	var best := _best_score_for(selected_level)
	_t(Vector2(60.0, 366.0), "%07d" % best if best > 0 else "--", 30, COLOR_YELLOW)
	_t(Vector2(60.0, 430.0), "SINCRONIA", 12, COLOR_MUTED)
	_t(Vector2(60.0, 462.0), "%+d ms" % int(round(sync_calibration * 1000.0)), 24, COLOR_ACCENT)
	_t(Vector2(60.0, 486.0), "IZQ / DER para ajustar", 12, COLOR_MUTED)
	if tap_connected:
		draw_circle(Vector2(66.0, 536.0), 5.0, COLOR_GREEN)
		_t(Vector2(80.0, 541.0), "PAD ARDUINO CONECTADO", 12, COLOR_GREEN)
		for lane in range(LANE_COUNT):
			var box := Rect2(60.0 + float(lane) * 52.0, 556.0, 44.0, 44.0)
			var lit: float = clampf(tap_flash[lane] / 0.35, 0.0, 1.0)
			_rrect(box, 8.0, Color(LANE_COLORS[lane], 0.12 + lit * 0.8))
			_rrect_line(box, 8.0, Color(LANE_COLORS[lane], 0.8), 1.5)
			draw_string(fallback_font, box.position + Vector2(0.0, 20.0), LANE_KEYS[lane], HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 15, COLOR_WHITE)
			draw_string(fallback_font, box.position + Vector2(0.0, 37.0), str(tap_counts[lane]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 11, COLOR_LIGHT)

	# Song carousel.
	var card_x := 430.0
	var card_w := vs.x - card_x - 56.0
	var selected_h := 168.0
	var other_h := 74.0
	var center_y := 250.0
	for offset in range(-2, 3):
		var index := selected_level + offset
		if index < 0 or index >= levels.size():
			continue
		var item: Dictionary = levels[index]
		var color := _difficulty_color(str(item.difficulty))
		var is_selected := offset == 0
		var height := selected_h if is_selected else other_h
		var top := center_y
		if offset < 0:
			top = center_y - 14.0 + float(offset) * (other_h + 12.0)
		elif offset > 0:
			top = center_y + selected_h + 14.0 + float(offset - 1) * (other_h + 12.0)
		var fade := 1.0 if is_selected else clampf(1.0 - absf(float(offset)) * 0.25, 0.2, 1.0)
		var rect := Rect2(card_x + (0.0 if is_selected else 26.0), top, card_w - (0.0 if is_selected else 26.0), height)
		if is_selected:
			_glow(rect.position + rect.size * 0.5, 260.0, color, 0.5)
			_panel(rect, color)
			_rrect(Rect2(rect.position.x + 14.0, rect.position.y + 16.0, 6.0, height - 32.0), 3.0, color)
			_t(rect.position + Vector2(40.0, 52.0), str(item.title), 30, COLOR_WHITE, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60.0)
			_t(rect.position + Vector2(40.0, 80.0), str(item.subtitle), 16, COLOR_LIGHT)
			var badge_x := _badge(rect.position + Vector2(40.0, 102.0), str(item.difficulty), color)
			_t(rect.position + Vector2(56.0 + badge_x, 119.0), "%s    %s" % [str(item.bpm_label), str(item.length)], 14, COLOR_LIGHT)
			_t(rect.position + Vector2(40.0, 152.0), str(item.notes), 12, COLOR_MUTED)
			var short_ok := _short_available(item)
			var pill_x := rect.end.x - 250.0
			var full_on := not play_short or not short_ok
			_rrect(Rect2(pill_x, 98.0 + rect.position.y, 110.0, 30.0), 15.0, Color(COLOR_ACCENT, 0.9 if full_on else 0.10))
			_t(Vector2(pill_x, rect.position.y + 119.0), "COMPLETA", 13, COLOR_BACKGROUND if full_on else COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, 110.0)
			var short_on := play_short and short_ok
			_rrect(Rect2(pill_x + 120.0, 98.0 + rect.position.y, 110.0, 30.0), 15.0, Color(COLOR_PINK, 0.9 if short_on else 0.10))
			_t(Vector2(pill_x + 120.0, rect.position.y + 119.0), "2 MINUTOS" if short_ok else "--", 13, COLOR_BACKGROUND if short_on else COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, 110.0)
			_t(Vector2(pill_x, rect.position.y + 152.0), "TAB cambia la version", 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, 230.0)
		else:
			_rrect(rect, 12.0, Color(COLOR_PANEL, 0.75 * fade))
			_rrect_line(rect, 12.0, Color(color, 0.35 * fade), 1.2)
			_rrect(Rect2(rect.position.x + 12.0, rect.position.y + 14.0, 4.0, height - 28.0), 2.0, Color(color, 0.8 * fade))
			_t(rect.position + Vector2(32.0, 33.0), str(item.title), 18, Color(COLOR_WHITE, fade), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 150.0)
			_t(rect.position + Vector2(32.0, 56.0), str(item.subtitle), 13, Color(COLOR_MUTED, fade))
			_t(rect.position + Vector2(rect.size.x - 120.0, 40.0), str(item.difficulty), 12, Color(color, fade), HORIZONTAL_ALIGNMENT_RIGHT, 100.0)

	# Footer shortcuts.
	var x := 56.0
	var y := vs.y - 48.0
	x += _chip(Vector2(x, y), "ARR/ABA", "elegir")
	x += _chip(Vector2(x, y), "ENTER", "jugar", COLOR_GREEN)
	x += _chip(Vector2(x, y), "TAB", "version", COLOR_PINK)
	x += _chip(Vector2(x, y), "E", "editor", COLOR_VIOLET)
	x += _chip(Vector2(x, y), "N", "nuevo", COLOR_ORANGE)
	x += _chip(Vector2(x, y), "T", "tabla", COLOR_YELLOW)
	x += _chip(Vector2(x, y), "X", "borrar", COLOR_RED)
	x += _chip(Vector2(x, y), "C", "limpiar chart", COLOR_RED)


func _draw_name_entry() -> void:
	var vs := _draw_screen_base("PREPARA TU PARTIDA")
	var level: Dictionary = levels[selected_level]
	var panel := Rect2((vs.x - 620.0) * 0.5, 210.0, 620.0, 280.0)
	_panel(panel, _difficulty_color(str(level.difficulty)))
	_t(Vector2(panel.position.x, panel.position.y + 52.0), "NOMBRE DEL JUGADOR", 20, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	_t(Vector2(panel.position.x, panel.position.y + 82.0), "%s  -  %s" % [str(level.title), ("2 MINUTOS" if (play_short and _short_available(level)) else "COMPLETA")], 15, COLOR_YELLOW, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	var typed_name := name_input
	if int(menu_time * 2.0) % 2 == 0:
		typed_name += "_"
	var field := Rect2(panel.position.x + 100.0, panel.position.y + 112.0, panel.size.x - 200.0, 58.0)
	_rrect(field, 10.0, Color("#050816"))
	_rrect_line(field, 10.0, Color(COLOR_ACCENT, 0.8), 1.5)
	_t(Vector2(field.position.x, field.position.y + 39.0), typed_name, 26, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, field.size.x)
	var x := panel.position.x + 96.0
	x += _chip(Vector2(x, panel.position.y + 210.0), "ENTER", "comenzar", COLOR_GREEN)
	x += _chip(Vector2(x, panel.position.y + 210.0), "ESC", "cancelar", COLOR_RED)
	_t(Vector2(56.0, vs.y - 36.0), "Hasta 12 caracteres", 13, COLOR_MUTED)


func _draw_new_level() -> void:
	var vs := _draw_screen_base("NUEVO NIVEL", COLOR_ORANGE)
	var panel := Rect2((vs.x - 780.0) * 0.5, 170.0, 780.0, 400.0)
	_panel(panel, COLOR_ORANGE)
	if new_song_files.is_empty():
		_t(Vector2(panel.position.x, panel.position.y + 120.0), "No hay MP3 nuevos", 28, COLOR_YELLOW, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
		_t(Vector2(panel.position.x, panel.position.y + 165.0), "Copia una cancion en la carpeta del proyecto y vuelve a abrir esta pantalla", 14, COLOR_LIGHT, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	else:
		var active := COLOR_YELLOW
		_t(panel.position + Vector2(36.0, 50.0), "CANCION", 12, COLOR_MUTED)
		_t(panel.position + Vector2(36.0, 84.0), str(new_song_files[new_song_index]).get_file(), 18, COLOR_WHITE, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 72.0)
		_t(panel.position + Vector2(36.0, 140.0), "BPM", 12, COLOR_MUTED)
		_t(panel.position + Vector2(36.0, 172.0), new_song_bpm, 24, active if new_level_field == 1 else COLOR_LIGHT)
		_t(panel.position + Vector2(300.0, 140.0), "OFFSET (s)", 12, COLOR_MUTED)
		_t(panel.position + Vector2(300.0, 172.0), new_song_offset, 24, active if new_level_field == 2 else COLOR_LIGHT)
		_t(panel.position + Vector2(36.0, 230.0), "DIFICULTAD", 12, COLOR_MUTED)
		_t(panel.position + Vector2(36.0, 262.0), CUSTOM_DIFFICULTIES[new_level_difficulty], 24, active if new_level_field == 3 else COLOR_LIGHT)
		_t(panel.position + Vector2(36.0, 306.0), "El nivel se crea con el chart vacio. Tip: py -3 tools/analyze_song.py cancion.mp3 mide BPM y offset.", 13, COLOR_MUTED)
		var x := panel.position.x + 36.0
		var y := panel.position.y + 340.0
		x += _chip(Vector2(x, y), "TAB", "campo")
		x += _chip(Vector2(x, y), "ARR/ABA", "cancion")
		x += _chip(Vector2(x, y), "IZQ/DER", "dificultad")
		x += _chip(Vector2(x, y), "ENTER", "crear", COLOR_GREEN)
		x += _chip(Vector2(x, y), "ESC", "cancelar", COLOR_RED)


func _draw_delete_confirmation() -> void:
	var vs := _draw_screen_base("CONFIRMAR ELIMINACION", COLOR_RED)
	var level: Dictionary = levels[selected_level]
	var panel := Rect2((vs.x - 680.0) * 0.5, 210.0, 680.0, 260.0)
	_panel(panel, COLOR_RED)
	var message := "Se borrara la cancion y todo su chart:" if delete_action == "song" else "Se borraran todas las notas del chart:"
	_t(Vector2(panel.position.x, panel.position.y + 70.0), message, 17, COLOR_YELLOW, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	_t(Vector2(panel.position.x, panel.position.y + 115.0), str(level.title), 26, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	_t(Vector2(panel.position.x, panel.position.y + 150.0), "Esta accion no se puede deshacer", 13, COLOR_RED, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	var x := panel.position.x + 170.0
	x += _chip(Vector2(x, panel.position.y + 196.0), "ENTER / Y", "confirmar", COLOR_RED)
	x += _chip(Vector2(x, panel.position.y + 196.0), "ESC / N", "cancelar", COLOR_ACCENT)


func _draw_scores() -> void:
	var vs := _draw_screen_base("TABLA DE PUNTUACIONES", COLOR_YELLOW)
	var level: Dictionary = levels[selected_level]
	_t(Vector2(vs.x - 56.0 - 420.0, 138.0), "%s  -  %s" % [str(level.title), "2 MIN" if play_short else "COMPLETA"], 20, COLOR_YELLOW, HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
	var level_scores: Array = []
	for entry in scores:
		if int(entry.level) == selected_level and bool(entry.get("short", false)) == play_short:
			level_scores.append(entry)
	level_scores.sort_custom(_sort_score_entries)
	var panel := Rect2((vs.x - 760.0) * 0.5, 170.0, 760.0, 410.0)
	_panel(panel, COLOR_YELLOW)
	var medals := [COLOR_YELLOW, Color("#CBD5E1"), Color("#D97706")]
	for row in range(10):
		var y := panel.position.y + 56.0 + float(row) * 34.0
		if row % 2 == 0:
			_rrect(Rect2(panel.position.x + 14.0, y - 24.0, panel.size.x - 28.0, 32.0), 8.0, Color(1.0, 1.0, 1.0, 0.035))
		if row < level_scores.size():
			var entry: Dictionary = level_scores[row]
			var rank_color: Color = medals[row] if row < 3 else COLOR_MUTED
			_t(Vector2(panel.position.x + 34.0, y), "%02d" % (row + 1), 17, rank_color)
			_t(Vector2(panel.position.x + 96.0, y), str(entry.name), 18, COLOR_WHITE)
			_t(Vector2(panel.position.x + 430.0, y), "%07d" % int(entry.score), 18, COLOR_YELLOW)
			_t(Vector2(panel.position.x + 600.0, y), "%.1f%%" % float(entry.accuracy), 16, COLOR_GREEN)
		else:
			_t(Vector2(panel.position.x + 96.0, y), "--", 16, Color(COLOR_MUTED, 0.5))
	var x := 56.0
	x += _chip(Vector2(x, vs.y - 48.0), "ARR/ABA", "cambiar nivel")
	x += _chip(Vector2(x, vs.y - 48.0), "TAB", "version", COLOR_PINK)
	x += _chip(Vector2(x, vs.y - 48.0), "T / ESC", "volver", COLOR_RED)


func _draw_editor() -> void:
	var vs := get_viewport_rect().size
	_draw_background(vs, menu_time, 0.0, COLOR_VIOLET, 0.15)
	_draw_brand(Vector2(36.0, 44.0), true)
	_t(Vector2(170.0, 42.0), "EDITOR DE NIVELES", 18, COLOR_WHITE)
	var editor_level: Dictionary = levels[selected_level]
	_t(Vector2(36.0, 72.0), str(editor_level.title) + "   /   " + str(editor_level.bpm_label), 13, COLOR_MUTED)

	var timeline := _editor_timeline_rect()
	_rrect(timeline, 10.0, Color("#060A1A"))
	var lane_height := timeline.size.y / LANE_COUNT
	for lane in range(LANE_COUNT):
		var row := Rect2(timeline.position.x, timeline.position.y + lane * lane_height, timeline.size.x, lane_height)
		draw_rect(row, Color(LANE_COLORS[lane], 0.07 if lane % 2 == 0 else 0.03))
		draw_line(row.position, Vector2(row.end.x, row.position.y), Color(1, 1, 1, 0.06), 1.0)
		_t(row.position + Vector2(14.0, lane_height * 0.5 + 6.0), LANE_KEYS[lane], 18, LANE_COLORS[lane])
	_rrect_line(timeline, 10.0, Color(COLOR_VIOLET, 0.6), 1.5)

	var view_length := 12.0
	var view_start := clampf(editor_time - 4.0, 0.0, maxf(0.0, song_length - view_length))
	var first_beat := int(floor((view_start - current_song_offset) / current_beat)) - 1
	var last_beat := int(ceil((view_start + view_length - current_song_offset) / current_beat)) + 1
	for beat_index in range(first_beat, last_beat + 1):
		var beat_time := current_song_offset + float(beat_index) * current_beat
		if beat_time < 0.0 or beat_time > song_length:
			continue
		var bx := timeline.position.x + (beat_time - view_start) / view_length * timeline.size.x
		if bx < timeline.position.x or bx > timeline.end.x:
			continue
		var strong := beat_index % 4 == 0
		draw_line(Vector2(bx, timeline.position.y), Vector2(bx, timeline.end.y), Color(0.7, 0.8, 1.0, 0.34 if strong else 0.12), 2.0 if strong else 1.0)
		if strong:
			_t(Vector2(bx + 5.0, timeline.position.y - 8.0), "COMPAS %02d" % int(beat_index / 4 + 1), 11, COLOR_MUTED)

	for note in chart:
		var note_time: float = float(note.time)
		if note_time < view_start - current_beat or note_time > view_start + view_length + current_beat:
			continue
		var note_x := timeline.position.x + (note_time - view_start) / view_length * timeline.size.x
		var lane := int(note.lane)
		var note_y := timeline.position.y + lane_height * (lane + 0.5)
		_glow(Vector2(note_x, note_y), 22.0, LANE_COLORS[lane], 0.8)
		_rrect(Rect2(note_x - 7.0, note_y - 16.0, 14.0, 32.0), 5.0, LANE_COLORS[lane])
		_rrect(Rect2(note_x - 3.0, note_y - 11.0, 6.0, 22.0), 3.0, Color(1, 1, 1, 0.5))

	var cursor_x := timeline.position.x + (editor_time - view_start) / view_length * timeline.size.x
	draw_line(Vector2(cursor_x, timeline.position.y - 16.0), Vector2(cursor_x, timeline.end.y + 5.0), COLOR_WHITE, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cursor_x - 7.0, timeline.position.y - 18.0),
		Vector2(cursor_x + 7.0, timeline.position.y - 18.0),
		Vector2(cursor_x, timeline.position.y - 6.0)
	]), COLOR_WHITE)

	_t(Vector2(72.0, 140.0), "%.2f s / %.2f s" % [editor_time, song_length], 20, COLOR_WHITE)
	_t(Vector2(vs.x - 72.0 - 300.0, 140.0), "NOTAS  %03d" % chart.size(), 20, COLOR_GREEN, HORIZONTAL_ALIGNMENT_RIGHT, 300.0)
	_t(Vector2(72.0, 530.0), "Click izq: colocar/quitar    Click der: borrar    Click central: mover cursor", 13, COLOR_MUTED)
	_t(Vector2(72.0, 560.0), "ESPACIO %s    1 negras    2 corcheas    3 semicorcheas    [ ] mover todo el chart" % ("PAUSAR" if editor_playing else "REPRODUCIR"), 13, COLOR_MUTED)
	_t(Vector2(72.0, 620.0), editor_message, 16, COLOR_YELLOW)
	_draw_action_button(Rect2(72.0, 652.0, 160.0, 38.0), "ESPACIO  PLAY", COLOR_GREEN)
	_draw_action_button(Rect2(242.0, 652.0, 160.0, 38.0), "S  GUARDAR", COLOR_ACCENT)
	_draw_action_button(Rect2(412.0, 652.0, 190.0, 38.0), "[ ]  MOVER TILES", COLOR_ORANGE)
	_draw_action_button(Rect2(612.0, 652.0, 190.0, 38.0), "ENTER  PROBAR", COLOR_VIOLET)
	_draw_action_button(Rect2(812.0, 652.0, 130.0, 38.0), "ESC  MENU", COLOR_RED)


# ---------------------------------------------------------------------------
# Gameplay
# ---------------------------------------------------------------------------

func _persp(progress: float) -> float:
	return pow(clampf(progress, 0.0, 1.5), 1.35)


func _y_at(progress: float) -> float:
	return lerpf(SPAWN_Y, JUDGEMENT_Y, _persp(progress))


func _span_at_y(y: float) -> Vector2:
	# Returns (left x, width) of the highway at the given screen height.
	var f := clampf((y - SPAWN_Y) / (g_bottom - SPAWN_Y), 0.0, 1.3)
	var width := lerpf(g_top_w, g_width, f)
	return Vector2(g_left + (g_width - width) * 0.5, width)


func _lane_point(edge: float, y: float) -> Vector2:
	var span := _span_at_y(y)
	return Vector2(span.x + span.y * edge / float(LANE_COUNT), y)


func _draw_game() -> void:
	var vs := get_viewport_rect().size
	g_width = minf(640.0, vs.x - 48.0)
	g_left = (vs.x - g_width) * 0.5
	g_top_w = g_width * HIGHWAY_TOP_RATIO
	g_bottom = JUDGEMENT_Y + 46.0
	var tier := _streak_tier_for(combo)
	var tier_color: Color = TIER_COLORS[tier]
	var energy := clampf(float(combo) / 64.0, 0.0, 1.0)
	var pulse := _beat_pulse(maxf(0.0, song_time)) if song_time >= 0.0 else 0.0

	_draw_background(vs, maxf(0.0, song_time), pulse, tier_color, energy)
	_draw_side_flash(vs)
	_draw_highway(vs, tier_color, energy, pulse)
	_draw_notes(vs, tier, tier_color, energy)
	_draw_receptors(tier, tier_color, energy, pulse)
	_draw_hit_effects(g_left, g_width)
	_draw_hud(vs, tier_color)
	_draw_streak_aura(vs, g_left, g_width)

	# Combo watermark inside the highway.
	if combo >= 3 and not level_finished:
		var combo_size := 76 + int(streak_pulse * 22.0)
		_t(Vector2(g_left, 345.0), str(combo), combo_size, Color(tier_color, 0.16 + streak_pulse * 0.22), HORIZONTAL_ALIGNMENT_CENTER, g_width)
		_t(Vector2(g_left, 372.0), "COMBO", 16, Color(COLOR_WHITE, 0.30), HORIZONTAL_ALIGNMENT_CENTER, g_width)

	if song_time < 0.0:
		var seconds := int(ceil(-song_time))
		var countdown := str(seconds)
		var local := fmod(-song_time, 1.0)
		if song_time > -0.15:
			countdown = "GO!"
		var count_size := 70 + int(local * 36.0)
		_t(Vector2(g_left, 400.0), countdown, count_size, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, g_width)
	elif feedback_timer > 0.0:
		var f_size := 26 + int(feedback_timer * 18.0)
		_t(Vector2(g_left, 262.0), feedback_text, f_size, Color(feedback_color, minf(1.0, feedback_timer * 5.0)), HORIZONTAL_ALIGNMENT_CENTER, g_width)

	if is_paused:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.01, 0.02, 0.06, 0.82))
		_t(Vector2(0.0, 300.0), "PAUSA", 58, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		_t(Vector2(0.0, 345.0), "Sincronia  %+d ms   (IZQ / DER ajusta)" % int(round(sync_calibration * 1000.0)), 18, COLOR_ACCENT, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		_t(Vector2(0.0, 380.0), "Si las notas llegan tarde respecto al sonido, baja el valor; si llegan antes, subelo.", 13, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		var x := vs.x * 0.5 - 200.0
		x += _chip(Vector2(x, 420.0), "ESPACIO", "continuar", COLOR_GREEN)
		x += _chip(Vector2(x, 420.0), "R", "reiniciar", COLOR_ORANGE)
		x += _chip(Vector2(x, 420.0), "ESC", "menu", COLOR_RED)

	if level_finished:
		_draw_results(vs)
	elif streak_announcement_timer > 0.0 and not is_paused:
		_draw_streak_announcement(vs)


func _draw_highway(vs: Vector2, tier_color: Color, energy: float, pulse: float) -> void:
	var top_left := _lane_point(0.0, SPAWN_Y)
	var top_right := _lane_point(float(LANE_COUNT), SPAWN_Y)
	var bottom_left := _lane_point(0.0, g_bottom)
	var bottom_right := _lane_point(float(LANE_COUNT), g_bottom)
	# Outer glow for the whole road.
	for layer in range(4):
		var spread := 10.0 + float(layer) * 9.0
		draw_colored_polygon(PackedVector2Array([
			top_left + Vector2(-spread * 0.4, 0.0), top_right + Vector2(spread * 0.4, 0.0),
			bottom_right + Vector2(spread, 0.0), bottom_left + Vector2(-spread, 0.0)
		]), Color(tier_color, 0.025 + energy * 0.02 + pulse * 0.012))
	# Road surface.
	draw_polygon(
		PackedVector2Array([top_left, top_right, bottom_right, bottom_left]),
		PackedColorArray([Color("#070B1C", 0.55), Color("#070B1C", 0.55), Color("#0E1632", 0.94), Color("#0E1632", 0.94)])
	)
	# Lane tints and press highlights.
	for lane in range(LANE_COUNT):
		var color: Color = LANE_COLORS[lane]
		var press: float = clampf(lane_flash[lane] / 0.14, 0.0, 1.0)
		var tint_alpha := 0.04 if lane % 2 == 0 else 0.015
		var tl := _lane_point(float(lane), SPAWN_Y)
		var tr := _lane_point(float(lane + 1), SPAWN_Y)
		var br := _lane_point(float(lane + 1), g_bottom)
		var bl := _lane_point(float(lane), g_bottom)
		draw_polygon(
			PackedVector2Array([tl, tr, br, bl]),
			PackedColorArray([Color(color, 0.0), Color(color, 0.0), Color(color, tint_alpha + press * 0.40), Color(color, tint_alpha + press * 0.40)])
		)
	# Beat and bar lines that scroll with the music, exactly like the notes.
	if song_time > -TRAVEL_TIME:
		var first_beat := int(floor((song_time - current_song_offset) / current_beat)) + 1
		for beat in range(first_beat - 1, first_beat + int(TRAVEL_TIME / current_beat) + 2):
			var beat_time := current_song_offset + float(beat) * current_beat
			var progress := 1.0 - (beat_time - song_time) / TRAVEL_TIME
			if progress < 0.0 or progress > 1.05 or beat_time < 0.0:
				continue
			var y := _y_at(progress)
			var span := _span_at_y(y)
			var is_bar := beat % 4 == 0
			var alpha := (0.30 if is_bar else 0.11) * minf(1.0, progress * 3.0)
			draw_line(Vector2(span.x, y), Vector2(span.x + span.y, y), Color(COLOR_WHITE, alpha), 2.0 if is_bar else 1.0)
	# Lane dividers and glowing edges.
	for lane in range(1, LANE_COUNT):
		draw_line(_lane_point(float(lane), SPAWN_Y), _lane_point(float(lane), g_bottom), Color(COLOR_WHITE, 0.10), 1.5)
	var edge_color := COLOR_ACCENT.lerp(tier_color, energy)
	draw_line(top_left, bottom_left, Color(edge_color, 0.25), 7.0)
	draw_line(top_right, bottom_right, Color(edge_color, 0.25), 7.0)
	draw_line(top_left, bottom_left, edge_color, 2.5)
	draw_line(top_right, bottom_right, edge_color, 2.5)
	# Fade the far end into the background.
	draw_polygon(
		PackedVector2Array([top_left + Vector2(-20.0, -4.0), top_right + Vector2(20.0, -4.0), top_right + Vector2(60.0, 140.0), top_left + Vector2(-60.0, 140.0)]),
		PackedColorArray([Color("#04060F", 1.0), Color("#04060F", 1.0), Color("#04060F", 0.0), Color("#04060F", 0.0)])
	)


func _draw_notes(_vs: Vector2, tier: int, tier_color: Color, energy: float) -> void:
	var index := active_notes.size() - 1
	while index >= 0:
		var note: Dictionary = active_notes[index]
		index -= 1
		if note.hit:
			continue
		var note_time: float = float(note.time)
		var progress := 1.0 - (note_time - song_time) / TRAVEL_TIME
		if progress < 0.0:
			continue
		var y := _y_at(progress)
		if y > get_viewport_rect().size.y + 40.0:
			continue
		var lane := int(note.lane)
		var span := _span_at_y(y)
		var lane_width := span.y / float(LANE_COUNT)
		var center_x := span.x + lane_width * (float(lane) + 0.5)
		var f := clampf((y - SPAWN_Y) / (g_bottom - SPAWN_Y), 0.0, 1.2)
		var note_width := lane_width * 0.80
		var note_height := lerpf(9.0, 30.0, minf(f, 1.0))
		var color: Color = LANE_COLORS[lane]
		var missed: bool = note.missed
		if missed:
			color = Color("#475069")
		var rect := Rect2(center_x - note_width * 0.5, y - note_height * 0.5, note_width, note_height)
		if not missed:
			_glow(Vector2(center_x, y), note_width * 0.62, color, 0.9 + energy)
		_rrect(Rect2(rect.position + Vector2(0.0, 4.0), rect.size), note_height * 0.45, Color(0, 0, 0, 0.45))
		_rrect(rect, note_height * 0.45, color)
		if not missed:
			var shine := Rect2(rect.position.x + note_width * 0.10, rect.position.y + note_height * 0.12, note_width * 0.80, note_height * 0.36)
			_rrect(shine, note_height * 0.18, Color(1, 1, 1, 0.42))
			_rrect_line(rect, note_height * 0.45, Color(COLOR_WHITE, 0.55), 1.2)
			if tier > 0:
				_rrect_line(rect.grow(2.0), note_height * 0.5, Color(tier_color, 0.35 + energy * 0.5), 1.5)


func _draw_receptors(tier: int, tier_color: Color, energy: float, pulse: float) -> void:
	var lane_width := g_width / float(LANE_COUNT)
	# Hit bar.
	var bar := Rect2(g_left - 14.0, JUDGEMENT_Y - 6.0, g_width + 28.0, 12.0)
	_rrect(bar, 6.0, Color(COLOR_WHITE, 0.10 + pulse * 0.16))
	draw_line(Vector2(g_left - 10.0, JUDGEMENT_Y), Vector2(g_left + g_width + 10.0, JUDGEMENT_Y), Color(COLOR_WHITE, 0.55 + pulse * 0.4), 2.0)
	for lane in range(LANE_COUNT):
		var center := Vector2(g_left + lane_width * (float(lane) + 0.5), JUDGEMENT_Y)
		var color: Color = LANE_COLORS[lane]
		var press: float = clampf(lane_flash[lane] / 0.14, 0.0, 1.0)
		var radius := minf(31.0, lane_width * 0.32) + press * 6.0
		_glow(center, radius * 2.6, color, 0.5 + press * 2.2 + energy * 0.6)
		draw_circle(center, radius + 4.0, Color(0.0, 0.0, 0.0, 0.55))
		draw_circle(center, radius, Color("#070B1C"))
		draw_circle(center, radius * (0.55 + press * 0.45), Color(color, 0.25 + press * 0.65))
		draw_arc(center, radius, 0.0, TAU, 40, Color(color, 0.55 + press * 0.45), 4.0)
		if tier > 0:
			var arc_start := fmod(shake_clock * (0.8 + float(tier) * 0.25) + float(lane) * 1.2, TAU)
			draw_arc(center, radius + 7.0, arc_start, arc_start + PI * 0.7, 18, Color(tier_color, 0.45 + energy * 0.4), 2.0)
		# Key cap.
		var cap := Rect2(center.x - 22.0, JUDGEMENT_Y + 46.0, 44.0, 32.0)
		_rrect(cap, 8.0, Color(color, 0.12 + press * 0.55))
		_rrect_line(cap, 8.0, Color(color, 0.9), 1.5)
		draw_string(fallback_font, Vector2(cap.position.x, cap.position.y + 23.0), LANE_KEYS[lane], HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, 18, COLOR_WHITE)


func _draw_hud(vs: Vector2, tier_color: Color) -> void:
	# Song progress along the very top.
	var progress := clampf(song_time / maxf(1.0, song_length), 0.0, 1.0)
	draw_rect(Rect2(0.0, 0.0, vs.x, 4.0), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(0.0, 0.0, vs.x * progress, 4.0), COLOR_ACCENT)

	# Left panel: song info and life.
	var left_x := 28.0
	var panel_w := g_left - 56.0
	_draw_brand(Vector2(left_x, 44.0), true)
	var level: Dictionary = levels[selected_level]
	var diff_color := _difficulty_color(str(level.difficulty))
	_t(Vector2(left_x, 96.0), str(level.title), 16, COLOR_WHITE, HORIZONTAL_ALIGNMENT_LEFT, panel_w)
	_t(Vector2(left_x, 116.0), str(level.subtitle), 12, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT, panel_w)
	_badge(Vector2(left_x, 130.0), str(level.difficulty), diff_color)
	# Life bar (vertical).
	var life_rect := Rect2(left_x, 200.0, 18.0, 330.0)
	_rrect(life_rect, 8.0, Color(1, 1, 1, 0.07))
	var life_ratio := clampf(life / MAX_LIFE, 0.0, 1.0)
	var life_color := Color("#34D399") if life > 35.0 else Color("#F43F5E")
	if life_ratio > 0.0:
		var fill_h := life_rect.size.y * life_ratio
		_rrect(Rect2(life_rect.position.x, life_rect.end.y - fill_h, life_rect.size.x, fill_h), 8.0, life_color)
	_rrect_line(life_rect, 8.0, Color(COLOR_WHITE, 0.4), 1.2)
	_t(Vector2(left_x + 28.0, 232.0), "VIDA", 12, COLOR_MUTED)
	_t(Vector2(left_x + 28.0, 258.0), "%d" % int(life), 24, life_color)
	_t(Vector2(left_x, vs.y - 28.0), "ESPACIO pausa  /  ESC menu  /  R reiniciar", 11, Color(COLOR_MUTED, 0.8))

	# Right panel: score, combo, accuracy, counts.
	var right_x := g_left + g_width + 36.0
	var right_w := vs.x - right_x - 28.0
	_t(Vector2(right_x, 56.0), "PUNTAJE", 12, COLOR_MUTED)
	_t(Vector2(right_x, 94.0), "%07d" % score, 34, COLOR_WHITE, HORIZONTAL_ALIGNMENT_LEFT, right_w)
	_t(Vector2(right_x, 150.0), "COMBO", 12, COLOR_MUTED)
	_t(Vector2(right_x, 196.0), str(combo), 46, tier_color, HORIZONTAL_ALIGNMENT_LEFT, right_w)
	_badge(Vector2(right_x, 212.0), "x%.2f" % _combo_multiplier(), tier_color)
	# Streak meter toward the next tier.
	var meter := Rect2(right_x, 250.0, right_w, 8.0)
	_rrect(meter, 4.0, Color(1, 1, 1, 0.08))
	_rrect(Rect2(meter.position, Vector2(maxf(8.0, meter.size.x * clampf(float(combo) / 64.0, 0.0, 1.0)), meter.size.y)), 4.0, tier_color)
	for milestone in [8, 16, 32]:
		var tick_x := meter.position.x + meter.size.x * float(milestone) / 64.0
		draw_line(Vector2(tick_x, meter.position.y - 3.0), Vector2(tick_x, meter.end.y + 3.0), Color(COLOR_WHITE, 0.5), 1.0)
	_t(Vector2(right_x, 300.0), "PRECISION", 12, COLOR_MUTED)
	_t(Vector2(right_x, 330.0), "%.1f%%" % _accuracy_percent(), 24, COLOR_GREEN)
	var rows := [["PERFECT", perfects, Color("#FDE68A")], ["GREAT", greats, Color("#6EE7B7")], ["GOOD", goods, Color("#93C5FD")], ["MISS", misses, Color("#FB7185")]]
	for i in range(rows.size()):
		var row_y := 380.0 + float(i) * 26.0
		_t(Vector2(right_x, row_y), str(rows[i][0]), 12, rows[i][2])
		_t(Vector2(right_x, row_y), str(rows[i][1]), 14, COLOR_WHITE, HORIZONTAL_ALIGNMENT_RIGHT, right_w)
	if autoplay:
		_t(Vector2(right_x, 520.0), "AUTOPLAY", 14, COLOR_ORANGE)
	if tap_connected:
		draw_circle(Vector2(right_x + 4.0, vs.y - 34.0), 4.0, COLOR_GREEN)
		_t(Vector2(right_x + 14.0, vs.y - 29.0), "PAD", 11, COLOR_GREEN)


func _draw_streak_aura(viewport_size: Vector2, field_left: float, field_width: float) -> void:
	if combo < 8 and streak_pulse <= 0.0:
		return
	var tier := _streak_tier_for(combo)
	var energy := maxf(clampf(float(combo) / 64.0, 0.0, 1.0), streak_pulse * 0.65)
	var color: Color = TIER_COLORS[tier]
	var orbit_time := shake_clock * (0.12 + energy * 0.10)
	for side in range(2):
		var x := field_left - 22.0 if side == 0 else field_left + field_width + 22.0
		var center := Vector2(x, viewport_size.y * 0.70)
		_glow(center, 60.0, color, 0.6 + energy)
		for ring in range(2):
			var radius := 16.0 + float(ring) * 11.0 + sin(orbit_time * 6.0 + float(ring)) * (1.5 + streak_pulse * 3.0)
			draw_arc(center, radius, orbit_time * 5.0 + float(ring) * 1.7, orbit_time * 5.0 + float(ring) * 1.7 + PI * 1.45, 24, Color(color, 0.25 + energy * 0.4), 1.5 + energy * 1.5)


func _draw_streak_announcement(viewport_size: Vector2) -> void:
	var alpha := minf(1.0, streak_announcement_timer / 0.30)
	var pop := 1.0 + maxf(0.0, streak_announcement_timer - 1.0) * 1.2
	var tier_titles := ["", "LA LLAMA DESPIERTA", "RITUAL ENCADENADO", "MAMBO MISTICO", "LEYENDA VIVA"]
	var color: Color = TIER_COLORS[streak_tier]
	var cy := viewport_size.y * 0.30
	_glow(Vector2(viewport_size.x * 0.5, cy), 260.0, color, 1.6 * alpha)
	draw_line(Vector2(viewport_size.x * 0.5 - 220.0, cy - 40.0), Vector2(viewport_size.x * 0.5 + 220.0, cy - 40.0), Color(color, alpha * 0.8), 2.0)
	_t(Vector2(0.0, cy - 14.0), "RACHA  x%d" % streak_announcement_combo, int(20.0 * pop), Color(COLOR_WHITE, alpha), HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x)
	_t(Vector2(0.0, cy + 30.0), tier_titles[streak_tier], int(38.0 * pop), Color(color, alpha), HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x)
	draw_line(Vector2(viewport_size.x * 0.5 - 220.0, cy + 52.0), Vector2(viewport_size.x * 0.5 + 220.0, cy + 52.0), Color(color, alpha * 0.8), 2.0)


func _draw_hit_effects(field_left: float, field_width: float) -> void:
	var lane_width := field_width / float(LANE_COUNT)
	for effect in hit_effects:
		var progress: float = float(effect.elapsed) / HIT_EFFECT_DURATION
		var alpha := 1.0 - progress
		var lane := int(effect.lane)
		var tier := _streak_tier_for(int(effect.get("combo", 0)))
		var center := Vector2(field_left + lane_width * (float(lane) + 0.5), JUDGEMENT_Y)
		var radius := 24.0 + progress * (70.0 + float(tier) * 12.0)
		var color: Color = LANE_COLORS[lane].lerp(effect.color, 0.45)
		if str(effect.text) == "BAD":
			color = Color("#FB7185")
		elif tier > 0:
			color = color.lerp(TIER_COLORS[tier], 0.3)
		_glow(center, radius * 1.4, color, alpha * 2.0)
		draw_arc(center, radius, 0.0, TAU, 40, Color(color, alpha), 4.0 - progress * 3.0)
		draw_arc(center, radius * 0.6, 0.0, TAU, 32, Color(COLOR_WHITE, alpha * 0.6), 2.0)
		var ray_count := 10 + tier * 3
		for ray in range(ray_count):
			var angle := TAU * float(ray) / float(ray_count) + float(lane) * 0.4
			var start_point := center + Vector2.from_angle(angle) * (radius * 0.8)
			var end_point := center + Vector2.from_angle(angle) * (radius * 0.8 + 14.0 * alpha + 4.0)
			draw_line(start_point, end_point, Color(color, alpha * 0.85), 2.0)
		_t(Vector2(center.x - lane_width * 0.5, JUDGEMENT_Y - 52.0 - progress * 28.0), str(effect.text), 14 + int(alpha * 5.0), Color(color, alpha), HORIZONTAL_ALIGNMENT_CENTER, lane_width)


func _draw_side_flash(viewport_size: Vector2) -> void:
	if side_flash_timer <= 0.0:
		return
	var alpha := side_flash_timer / 0.30 * 0.30
	var color := Color(side_flash_color, alpha)
	var clear := Color(side_flash_color, 0.0)
	draw_polygon(
		PackedVector2Array([Vector2(0.0, 0.0), Vector2(240.0, 0.0), Vector2(240.0, viewport_size.y), Vector2(0.0, viewport_size.y)]),
		PackedColorArray([color, clear, clear, color])
	)
	draw_polygon(
		PackedVector2Array([Vector2(viewport_size.x - 240.0, 0.0), Vector2(viewport_size.x, 0.0), Vector2(viewport_size.x, viewport_size.y), Vector2(viewport_size.x - 240.0, viewport_size.y)]),
		PackedColorArray([clear, color, color, clear])
	)


func _grade_for(accuracy: float) -> String:
	if accuracy >= 96.0:
		return "S"
	if accuracy >= 90.0:
		return "A"
	if accuracy >= 78.0:
		return "B"
	if accuracy >= 62.0:
		return "C"
	return "D"


func _draw_results(vs: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.01, 0.02, 0.06, 0.72))
	var panel := Rect2((vs.x - 560.0) * 0.5, 130.0, 560.0, 440.0)
	var accent := COLOR_RED if game_over else COLOR_GREEN
	_glow(panel.position + panel.size * 0.5, 380.0, accent, 0.8)
	_panel(panel, accent, 18.0)
	_t(Vector2(panel.position.x, panel.position.y + 56.0), "GAME OVER" if game_over else "NIVEL COMPLETADO", 30, accent, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	_t(Vector2(panel.position.x, panel.position.y + 84.0), str(player_name), 14, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)
	var grade := _grade_for(_accuracy_percent())
	var grade_color: Color = {"S": COLOR_YELLOW, "A": COLOR_GREEN, "B": COLOR_ACCENT, "C": COLOR_ORANGE, "D": COLOR_RED}[grade]
	_glow(Vector2(panel.position.x + 110.0, panel.position.y + 190.0), 120.0, grade_color, 1.4)
	_t(Vector2(panel.position.x + 40.0, panel.position.y + 235.0), grade, 130, grade_color, HORIZONTAL_ALIGNMENT_CENTER, 140.0)
	_t(Vector2(panel.position.x + 200.0, panel.position.y + 140.0), "PUNTAJE", 12, COLOR_MUTED)
	_t(Vector2(panel.position.x + 200.0, panel.position.y + 178.0), "%07d" % score, 36, COLOR_WHITE)
	_t(Vector2(panel.position.x + 200.0, panel.position.y + 218.0), "PRECISION  %.1f%%" % _accuracy_percent(), 16, COLOR_GREEN)
	_t(Vector2(panel.position.x + 200.0, panel.position.y + 244.0), "MAX COMBO  %d" % max_combo, 16, COLOR_WHITE)
	var labels := [["PERFECT", perfects, Color("#FDE68A")], ["GREAT", greats, Color("#6EE7B7")], ["GOOD", goods, Color("#93C5FD")], ["MISS", misses, Color("#FB7185")]]
	for i in range(labels.size()):
		var x := panel.position.x + 40.0 + float(i) * 122.0
		_rrect(Rect2(x, panel.position.y + 290.0, 110.0, 66.0), 10.0, Color(labels[i][2], 0.10))
		_t(Vector2(x, panel.position.y + 316.0), str(labels[i][0]), 12, labels[i][2], HORIZONTAL_ALIGNMENT_CENTER, 110.0)
		_t(Vector2(x, panel.position.y + 344.0), str(labels[i][1]), 22, COLOR_WHITE, HORIZONTAL_ALIGNMENT_CENTER, 110.0)
	var cx := panel.position.x + 150.0
	cx += _chip(Vector2(cx, panel.position.y + 392.0), "R", "reiniciar", COLOR_GREEN)
	cx += _chip(Vector2(cx, panel.position.y + 392.0), "ESC", "menu", COLOR_RED)


func _accuracy_percent() -> float:
	if judged_notes == 0:
		return 100.0
	var weighted := perfects * 300.0 + greats * 200.0 + goods * 100.0
	return weighted / (judged_notes * 300.0) * 100.0
