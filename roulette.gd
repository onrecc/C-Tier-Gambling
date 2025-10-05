extends Node2D

@export var label_path: NodePath = NodePath("Label")
@export var spin_button_path: NodePath = NodePath("./CanvasLayer/spin")
@export var spinnyboi_path: NodePath = NodePath("./spinnyboi")
@export var exit_button_path: NodePath = NodePath("./CanvasLayer/exit")

@export var min_steps: int = 40
@export var max_steps: int = 80
@export var start_delay: float = 0.01
@export var end_delay: float = 0.18

@export var pop_scale: float = 1.35
@export var pop_duration: float = 0.12

@onready var label: Label = null
@onready var spin_button: Button = null
@onready var spinnyboi: Sprite2D = null
@onready var wheel_sfx: AudioStreamPlayer2D = $WheelSFX
@onready var exit_button: Button = null

var audio_gen: AudioStreamGenerator = AudioStreamGenerator.new()
var audio_playback: AudioStreamGeneratorPlayback = null

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var slots: Array[String] = []

var soft_red   := Color("ffcccc")
var soft_black := Color("aaaaaa")
var soft_green := Color("aaffcc")

var colors := {
	"0": soft_green, "00": soft_green,
	"28": soft_black, "9": soft_red, "26": soft_black, "30": soft_red,
	"11": soft_black, "7": soft_red, "20": soft_black, "32": soft_red,
	"17": soft_black, "5": soft_red, "22": soft_black, "34": soft_red,
	"15": soft_black, "3": soft_red, "24": soft_black, "36": soft_red,
	"13": soft_black, "1": soft_red,
	"27": soft_black, "10": soft_red, "25": soft_black, "29": soft_red,
	"12": soft_black, "8": soft_red, "19": soft_black, "31": soft_red,
	"18": soft_black, "6": soft_red, "21": soft_black, "33": soft_red,
	"16": soft_black, "4": soft_red, "23": soft_black, "35": soft_red,
	"14": soft_black, "2": soft_red
}

# ---- Betting System ----
var bets: Array[Dictionary] = []
var player_balance: int = 1000

func place_bet(bet_type: String, value, amount: int, button_name: String = ""):
	if amount <= 0 or amount > player_balance:
		return
	player_balance -= amount	
	bets.append({"type": bet_type, "value": value, "amount": amount, "button": button_name})

func evaluate_bets(winning_number: String) -> int:
	var total_winnings = 0
	var winning_color = ""
	if winning_number in ["0","00"]:
		winning_color = "green"
	else:
		if _get_color(winning_number) == soft_red:
			winning_color = "red"
		else:	
			winning_color = "black"

	var winning_even_odd = ""
	if winning_number in ["0","00"]:
		winning_even_odd = "none"
	else:
		if int(winning_number) % 2 == 0:
			winning_even_odd = "even"
		else:
			winning_even_odd = "odd"

	var winning_range = ""
	if winning_number in ["0","00"]:
		winning_range = "none"
	else:
		var num = int(winning_number)
		if num <= 18:
			winning_range = "1-18" 
		else:
			winning_range = "19-36"

	var winning_dozen = ""
	if winning_number in ["0","00"]:
		winning_dozen = "none"
	else:
		var num = int(winning_number)
		if num <= 12:
			winning_dozen = "1-12"
		elif num <= 24:
			winning_dozen = "13-24"
		else:
			winning_dozen = "25-36"

	for bet in bets:
		match bet["type"]:
			"number":
				if str(bet["value"]) == winning_number:
					total_winnings += bet["amount"] * 35
			"color":
				if bet["value"] == winning_color:
					total_winnings += bet["amount"] * 2
			"even_odd":
				if bet["value"] == winning_even_odd:
					total_winnings += bet["amount"] * 2
			"range":
				if bet["value"] == winning_range:
					total_winnings += bet["amount"] * 2
			"dozen":
				if bet["value"] == winning_dozen:
					total_winnings += bet["amount"] * 3
	bets.clear()
	player_balance += total_winnings
	return total_winnings

# -------------------------

func _ready() -> void:
	rng.randomize()
	_build_slots()

	var node: Node = get_node_or_null(label_path)
	if node is Label:
		label = node
	else:
		label = _find_first_label()
	if not label:
		push_error("roulette.gd: No Label found.")
		return
	label.text = slots[rng.randi_range(0, slots.size() - 1)]
	label.scale = Vector2.ONE

	spin_button = get_node_or_null(spin_button_path)
	if spin_button and spin_button is Button:
		spin_button.pressed.connect(spin)

	exit_button = get_node_or_null(exit_button_path)
	if exit_button and exit_button is Button:
		exit_button.pressed.connect(_on_exit_pressed)

	spinnyboi = get_node_or_null(spinnyboi_path)
	if spinnyboi:
		spinnyboi.rotation = 0.0

	if wheel_sfx and wheel_sfx is AudioStreamPlayer2D:
		audio_gen.mix_rate = 44100
		audio_gen.buffer_length = 0.1
		wheel_sfx.stream = audio_gen
		wheel_sfx.play()
		audio_playback = wheel_sfx.get_stream_playback() as AudioStreamGeneratorPlayback

	_connect_bet_buttons()

func _connect_bet_buttons() -> void:
	var cl = $CanvasLayer
	for btn in cl.get_children():
		if btn is Button:
			btn.pressed.connect(_on_bet_button_pressed.bind(btn.name))
			
func _update_button_bet_display(button_name: String) -> void:
	var button = $CanvasLayer.get_node(button_name) as Button
	if not button: return

	var total_bet = _get_total_bet_for_button(button_name)

	if button_name.is_valid_int() or button_name in ["0", "00"]:
		var bet_label = button.get_node_or_null("BetLabel")
		if bet_label:
			bet_label.text = str(total_bet) if total_bet > 0 else ""
	else:
		if total_bet > 0:
			button.text = button_name.capitalize() + " (" + str(total_bet) + ")"
		else:
			button.text = button_name.capitalize()
			
func _reset_bets() -> void:
	bets.clear()
	for child in $CanvasLayer.get_children():
		if child is Button:
			var btn_name = child.name
			if btn_name.is_valid_int() or btn_name in ["0", "00"]:
				var bet_label = child.get_node_or_null("BetLabel")
				if bet_label:
					bet_label.text = ""
			else:
				child.text = btn_name.capitalize()

func _on_bet_button_pressed(name: String) -> void:
	var bet_amount = 10
	var button = $CanvasLayer.get_node(name) as Button

	match name.to_lower():
		"even":
			place_bet("even_odd", "even", bet_amount, "even")
		"odd":
			place_bet("even_odd", "odd", bet_amount, "odd")
		"red":
			place_bet("color", "red", bet_amount, "red")
		"black":
			place_bet("color", "black", bet_amount, "black")
		"1to18":
			place_bet("range", "1-18", bet_amount, "1to18")
		"19to36":
			place_bet("range", "19-36", bet_amount, "19to36")
		"1to12":
			place_bet("dozen", "1-12", bet_amount, "1to12")
		"13to24":
			place_bet("dozen", "13-24", bet_amount, "13to24")
		"25to36":
			place_bet("dozen", "25-36", bet_amount, "25to36")
		"0":
			place_bet("number", "0", bet_amount, "0")
		"00":
			place_bet("number", "00", bet_amount, "00")
		_:
			if name.is_valid_int():
				var num = int(name)
				if num >= 1 and num <= 36:
					place_bet("number", str(num), bet_amount, str(num))
					
	if button:
		var total_bet = _get_total_bet_for_button(name)
		button.text = name.capitalize() + " (" + str(total_bet) + ")"

	print("Placed bet: ", bets)

func _get_total_bet_for_button(name: String) -> int:
	var total := 0
	for bet in bets:
		if bet.has("button") and bet["button"] == name:
			total += bet["amount"]
	return total

func _build_slots() -> void:
	slots = [
		"0", "28", "9", "26", "30", "11", "7", "20", "32", "17",
		"5", "22", "34", "15", "3", "24", "36", "13", "1", "00",
		"27", "10", "25", "29", "12", "8", "19", "31", "18", "6",
		"21", "33", "16", "4", "23", "35", "14", "2"
	]

func play_tick(frequency: float = 1000.0, duration: float = 0.03):
	if not audio_playback:
		return
	var sample_rate = audio_gen.mix_rate
	var total_samples = int(duration * sample_rate)
	for i in range(total_samples):
		var t = i / sample_rate
		var sample = sin(2.0 * PI * frequency * t) * 0.3 
		audio_playback.push_frame(Vector2(sample, sample))
		
func play_end_sfx(frequency: float = 1600.0, duration: float = 0.50):
	if not audio_playback:
		return
	var sample_rate = audio_gen.mix_rate
	var total_samples = int(duration * sample_rate)
	for i in range(total_samples):
		var t = i / sample_rate
		var decay = 1.0 - t / duration
		var sample = sin(2.0 * PI * frequency * t) * 0.5 * decay
		audio_playback.push_frame(Vector2(sample, sample))

func _find_first_label() -> Label:
	return _recursive_find_label(self)
	
func _get_color(value: String) -> Color:
	return colors.get(value, Color.WHITE)

func _recursive_find_label(node: Node) -> Label:
	for c in node.get_children():
		if c is Label:
			return c
		var res: Label = _recursive_find_label(c)
		if res:
			return res
	return null

func _on_exit_pressed() -> void:
	var casino_scene_path := "res://Casino.tscn"
	var err = get_tree().change_scene_to_file(casino_scene_path)
	if err != OK:
		push_error("Failed to change scene to Casino.tscn")

func spin() -> void:
	if not label:
		return

	var n: int = slots.size()
	if n == 0:
		return

	var target_index: int = rng.randi_range(0, n - 1)
	var start_index: int = rng.randi_range(0, n - 1)

	var steps: int = rng.randi_range(min_steps, max_steps)
	var remainder: int = (target_index - start_index) % n
	if remainder < 0:
		remainder += n
	steps += (n + remainder - (steps % n)) % n

	var total_rotations: float = rng.randf_range(3.0, 6.0) * TAU
	var i: int = 0
	while i < steps:
		var progress: float = float(i) / float(steps)
		var eased: float = 1.0 - pow(1.0 - progress, 2)
		var delay: float = lerp(start_delay, end_delay, eased)

		var idx: int = (start_index + i) % n
		var value: String = slots[idx]
		label.text = value
		label.add_theme_color_override("font_color", _get_color(value))

		if spinnyboi:
			spinnyboi.rotation = total_rotations * eased
			
		if audio_playback:
			var freq = lerp(1400, 800, eased)
			play_tick(freq, 0.03)

		await get_tree().create_timer(delay).timeout
		i += 1

	label.text = slots[target_index]
	label.add_theme_color_override("font_color", _get_color(slots[target_index]))
	_play_pop()
	play_end_sfx()
	_reset_bets()

	var winnings = evaluate_bets(slots[target_index])
	print("Winning number: ", slots[target_index], " | Player won: ", winnings, " | Balance: ", player_balance)

func _play_pop() -> void:
	var tw: Tween = create_tween()
	var track1 = tw.tween_property(label, "scale", Vector2(pop_scale, pop_scale), pop_duration)
	if track1:
		track1.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var track2 = tw.tween_property(label, "scale", Vector2.ONE, pop_duration)
	if track2:
		track2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
