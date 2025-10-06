extends Node2D

@onready var dealer_hand_label: Label = $DealerHandLabel
@onready var player_hand_label: Label = $PlayerHandLabel
@onready var status_label: Label = $StatusLabel
@onready var coins_label: Label = $CoinsLabel
@onready var bet_spin: SpinBox = $BetRow/BetSpin
@onready var deal_btn: Button = $ButtonsRow/DealButton
@onready var hit_btn: Button = $ButtonsRow/HitButton
@onready var stand_btn: Button = $ButtonsRow/StandButton
@onready var double_btn: Button = $ButtonsRow/DoubleButton
@onready var new_round_btn: Button = $ButtonsRow/NewRoundButton
@onready var card_sfx: AudioStreamPlayer2D = $CardSFX
@onready var exit_btn: Button = $ExitButton

var deck: Array = []
var player_hand: Array = []
var dealer_hand: Array = []
var current_bet: int = 0
var round_active: bool = false
var player_doubled: bool = false
var dealer_hidden: bool = true

const SUITS = ["♠","♥","♦","♣"]
const RANKS = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]

func _ready() -> void:
	randomize()
	dealer_hand_label.add_theme_font_size_override("font_size", 32)
	player_hand_label.add_theme_font_size_override("font_size", 32)
	status_label.add_theme_font_size_override("font_size", 22)
	_update_coins(State.coins)
	if not State.is_connected("score_changed", _update_coins):
		State.score_changed.connect(_update_coins)
	_update_ui()

func _update_coins(v: int) -> void:
	coins_label.text = "Coins: %d" % v

func _emit_coins_changed() -> void:
	State.emit_signal("score_changed", State.coins)

func _build_deck() -> void:
	deck.clear()
	for s in SUITS:
		for r in RANKS:
			deck.append({ "rank": r, "suit": s })
	deck.shuffle()

func _deal_card(hand: Array) -> void:
	if deck.is_empty():
		_build_deck()
	hand.append(deck.pop_back())

func _hand_value(hand: Array) -> int:
	var total := 0
	var aces := 0
	for c in hand:
		var r: String = c["rank"]
		if r == "A":
			total += 11
			aces += 1
		elif r in ["K","Q","J","10"]:
			total += 10
		else:
			total += int(r)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _is_blackjack(hand: Array) -> bool:
	return hand.size() == 2 and _hand_value(hand) == 21

func _format_hand(hand: Array, hide_second: bool=false) -> String:
	if hide_second and hand.size() >= 2:
		var first = "%s%s" % [hand[0]["rank"], hand[0]["suit"]]
		return first + ", [?]"
	var items: Array[String] = []
	for c in hand:
		items.append("%s%s" % [c["rank"], c["suit"]])
	return ", ".join(items)

# ---------- Animated UI helpers ----------

func _set_dealer_text(animated: bool) -> void:
	var show_hidden = dealer_hidden and round_active
	var hand_str = _format_hand(dealer_hand, show_hidden)
	var val_str = "?" if show_hidden else str(_hand_value(dealer_hand))
	var text = "%s (%s)" % [hand_str, val_str]
	if animated:
		await _animate_label_change(dealer_hand_label, text)
	else:
		dealer_hand_label.text = text

func _set_player_text(animated: bool) -> void:
	var text = "%s (%d)" % [_format_hand(player_hand), _hand_value(player_hand)]
	if animated:
		await _animate_label_change(player_hand_label, text)
	else:
		player_hand_label.text = text

func _animate_label_change(label: Label, new_text: String) -> void:
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.9, 0.9)
	label.modulate.a = 0.0
	label.text = new_text
	var t = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 1.0, 0.18)
	t.parallel().tween_property(label, "scale", Vector2(1, 1), 0.18)
	await t.finished

func _play_card_sfx() -> void:
	if is_instance_valid(card_sfx) and card_sfx.stream:
		card_sfx.play()

func _deal_to_player() -> void:
	_deal_card(player_hand)
	_play_card_sfx()
	await _set_player_text(true)

func _deal_to_dealer() -> void:
	_deal_card(dealer_hand)
	_play_card_sfx()
	await _set_dealer_text(true)

# ---------- Round flow ----------

func _start_round() -> void:
	if round_active:
		return
	current_bet = clamp(int(bet_spin.value), 1, 100000)
	if State.coins < current_bet:
		status_label.text = "Not enough coins."
		return

	State.coins -= current_bet
	_emit_coins_changed()

	player_doubled = false
	round_active = true
	dealer_hidden = true

	_build_deck()
	player_hand.clear()
	dealer_hand.clear()

	await _deal_to_player()
	await get_tree().create_timer(0.08).timeout
	await _deal_to_dealer()
	await get_tree().create_timer(0.08).timeout
	await _deal_to_player()
	await get_tree().create_timer(0.08).timeout
	await _deal_to_dealer()

	if _is_blackjack(player_hand) or _is_blackjack(dealer_hand):
		dealer_hidden = false
		await _set_dealer_text(true)
		_end_round_naturals()
	else:
		status_label.text = "Your move: Hit / Stand / Double"
	_update_ui(true)

func _end_round_naturals() -> void:
	if _is_blackjack(player_hand) and _is_blackjack(dealer_hand):
		State.coins += current_bet
		_emit_coins_changed()
		status_label.text = "Push! Both have Blackjack."
	elif _is_blackjack(player_hand):
		var payout = int(round(current_bet * 2.5))
		State.coins += payout
		_emit_coins_changed()
		status_label.text = "Blackjack! You win 3:2."
	else:
		status_label.text = "Dealer Blackjack. You lose."
	round_active = false
	_update_ui()

func _player_hit() -> void:
	if not round_active: return
	await _deal_to_player()
	if _hand_value(player_hand) > 21:
		dealer_hidden = false
		await _set_dealer_text(true)
		status_label.text = "Bust! You lose."
		round_active = false
	_update_ui()

func _player_stand() -> void:
	if not round_active: return
	dealer_hidden = false
	await _set_dealer_text(true)
	await _dealer_play()
	_resolve()
	_update_ui()

func _player_double() -> void:
	if not round_active: return
	if State.coins < current_bet:
		status_label.text = "Not enough coins to double."
		return
	State.coins -= current_bet
	_emit_coins_changed()
	current_bet *= 2
	player_doubled = true

	await _deal_to_player()
	if _hand_value(player_hand) > 21:
		dealer_hidden = false
		await _set_dealer_text(true)
		status_label.text = "Bust after double! You lose."
		round_active = false
	else:
		await _player_stand()

func _dealer_play() -> void:
	while _hand_value(dealer_hand) < 17:
		await get_tree().create_timer(0.18).timeout
		await _deal_to_dealer()

func _resolve() -> void:
	var p = _hand_value(player_hand)
	var d = _hand_value(dealer_hand)

	if d > 21:
		State.coins += current_bet * 2
		_emit_coins_changed()
		status_label.text = "Dealer busts! You win."
	elif p > d:
		State.coins += current_bet * 2
		_emit_coins_changed()
		status_label.text = "You win!"
	elif p == d:
		State.coins += current_bet
		_emit_coins_changed()
		status_label.text = "Push."
	else:
		status_label.text = "You lose."
	round_active = false

func _update_ui(buttons_only: bool=false) -> void:
	if not buttons_only:
		await _set_dealer_text(false)
		await _set_player_text(false)

	deal_btn.disabled = round_active
	hit_btn.disabled = not round_active
	stand_btn.disabled = not round_active
	double_btn.disabled = not round_active or player_hand.size() != 2
	new_round_btn.disabled = round_active

	if not round_active and dealer_hand.size() > 0:
		status_label.text += "  (Press New Round or Deal)"

# ---- Button callbacks ----
func _on_deal_pressed() -> void:
	_start_round()

func _on_hit_pressed() -> void:
	_player_hit()

func _on_stand_pressed() -> void:
	_player_stand()

func _on_double_pressed() -> void:
	_player_double()

func _on_new_round_pressed() -> void:
	status_label.text = "Place your bet and Deal."
	round_active = false
	player_hand.clear()
	dealer_hand.clear()
	dealer_hidden = true
	_update_ui()

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://casino.tscn")
