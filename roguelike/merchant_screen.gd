extends Control
## Merchant Screen - Buy and sell cards

signal merchant_completed(result: Dictionary)

@onready var gold_label: Label = $Panel/VBoxContainer/Header/GoldLabel
@onready var shop_list: GridContainer = $Panel/VBoxContainer/ShopSection/ShopList
@onready var deck_list: VBoxContainer = $Panel/VBoxContainer/DeckSection/DeckScroll/DeckList
@onready var message_label: Label = $Panel/VBoxContainer/Message
@onready var done_button: Button = $Panel/VBoxContainer/Done

# Shop inventory templates
const SHOP_CARDS := [
	{"name": "Steel Harpoon", "hook": 3, "line": 3, "sinker": 0, "ability": "None", "price": 30},
	{"name": "Reinforced Net", "hook": 1, "line": 4, "sinker": 2, "ability": "Stun", "price": 40},
	{"name": "Barbed Hook", "hook": 2, "line": 2, "sinker": 1, "ability": "Bleed", "price": 35},
	{"name": "Heavy Anchor", "hook": 2, "line": 5, "sinker": 0, "ability": "None", "price": 45},
	{"name": "Chumslinger", "hook": 0, "line": 2, "sinker": 2, "ability": "Chum", "price": 25},
	{"name": "Repair Kit", "hook": 1, "line": 3, "sinker": 2, "ability": "Repair", "price": 50},
	{"name": "Push Pole", "hook": 1, "line": 2, "sinker": 2, "ability": "Push", "price": 35},
	{"name": "Grappling Line", "hook": 2, "line": 2, "sinker": 2, "ability": "Pull", "price": 35},
]

const SELL_VALUE := 10  # Gold per card sold

var gold: int = 0
var shop_inventory: Array[Dictionary] = []
var player_deck: Array[CardData] = []
var cards_bought: Array[CardData] = []
var cards_sold: Array[CardData] = []


func _ready() -> void:
	visible = false
	done_button.pressed.connect(_on_done)


func show_merchant(current_gold: int, deck: Array[CardData]) -> void:
	gold = current_gold
	player_deck = deck.duplicate()
	cards_bought.clear()
	cards_sold.clear()
	message_label.text = ""
	
	# Generate random shop inventory (4 cards)
	shop_inventory.clear()
	var shuffled := SHOP_CARDS.duplicate()
	shuffled.shuffle()
	for i in mini(4, shuffled.size()):
		shop_inventory.append(shuffled[i])
	
	_update_display()
	visible = true


func _update_display() -> void:
	gold_label.text = "Gold: %d" % gold
	
	# Shop items
	for child in shop_list.get_children():
		child.queue_free()
	
	for item in shop_inventory:
		var vbox := VBoxContainer.new()
		shop_list.add_child(vbox)
		
		var name_lbl := Label.new()
		name_lbl.text = item.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		var stats_lbl := Label.new()
		stats_lbl.text = "H:%d L:%d S:%d" % [item.hook, item.line, item.sinker]
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(stats_lbl)
		
		if item.ability != "None":
			var ability_lbl := Label.new()
			ability_lbl.text = "[%s]" % item.ability
			ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ability_lbl.add_theme_font_size_override("font_size", 11)
			vbox.add_child(ability_lbl)
		
		var buy_btn := Button.new()
		buy_btn.text = "Buy (%d g)" % item.price
		buy_btn.disabled = gold < item.price
		buy_btn.pressed.connect(_on_buy_card.bind(item))
		vbox.add_child(buy_btn)
	
	# Player deck (for selling)
	for child in deck_list.get_children():
		child.queue_free()
	
	for i in player_deck.size():
		var card := player_deck[i]
		var hbox := HBoxContainer.new()
		deck_list.add_child(hbox)
		
		var lbl := Label.new()
		lbl.text = "%s (H:%d L:%d)" % [card.card_name, card.hook, card.line]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)
		
		var sell_btn := Button.new()
		sell_btn.text = "Sell (%d g)" % SELL_VALUE
		sell_btn.pressed.connect(_on_sell_card.bind(i))
		hbox.add_child(sell_btn)


func _on_buy_card(item: Dictionary) -> void:
	if gold < item.price:
		message_label.text = "Not enough gold!"
		return
	
	gold -= item.price
	
	# Create the card
	var card := CardData.new()
	card.card_name = item.name
	card.hook = item.hook
	card.line = item.line
	card.sinker = item.sinker
	card.ability = item.ability
	
	cards_bought.append(card)
	player_deck.append(card)
	
	# Remove from shop
	shop_inventory.erase(item)
	
	message_label.text = "Bought %s!" % card.card_name
	_update_display()


func _on_sell_card(deck_index: int) -> void:
	if player_deck.size() <= 3:
		message_label.text = "Can't sell - need at least 3 cards!"
		return
	
	var card := player_deck[deck_index]
	cards_sold.append(card)
	player_deck.remove_at(deck_index)
	gold += SELL_VALUE
	
	message_label.text = "Sold %s for %d gold!" % [card.card_name, SELL_VALUE]
	_update_display()


func _on_done() -> void:
	visible = false
	merchant_completed.emit({
		"gold": gold,
		"bought": cards_bought,
		"sold": cards_sold,
		"deck": player_deck
	})
