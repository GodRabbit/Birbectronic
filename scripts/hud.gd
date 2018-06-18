extends CanvasLayer

#	Copyright 2018  Dor "GodRabbit" Shlush
# This file is part of "Birbectronic".
#
#    "Birbectronic" is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    "Birbectronic" is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with "Birbectronic".  If not, see <https://www.gnu.org/licenses/>.
#

var player

onready var health_bar = get_node("main_container/hp_container/health_bar")
onready var head_temp_bar = get_node("main_container/temp_container/head_temp_bar")
onready var body_temp_bar = get_node("main_container/temp_container/body_temp_bar")
onready var cannon_temp_bar = get_node("main_container/temp_container/cannon_temp_bar")
onready var enemies_label = get_node("main_container/hp_container/ememies_label")

func _ready():
	pass

func set_player(p):
	player = p
	update_gui()

func update_gui():
	health_bar.value = player.get_health_percent()
	head_temp_bar.value = player.get_current_head_temperature()
	body_temp_bar.value = player.get_current_body_temperature()
	cannon_temp_bar.value = player.get_current_cannon_temperature()
	var left_enemies = player.get_parent().get_node("enemies").get_children().size()
	enemies_label.set_text("Enemies Left: " + str(left_enemies))