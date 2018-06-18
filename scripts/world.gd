extends Node2D

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
#	Copyright 2018  Dor "GodRabbit" Shlush

onready var player = get_node("player_birb")
onready var end_game_node = get_node("end_game/main_node")
onready var you_won_sprite = get_node("end_game/main_node/you_won_sprite")
onready var you_lost_sprite = get_node("end_game/main_node/you_lost_sprite")
onready var play_again_button = get_node("end_game/main_node/play_again_button")
onready var exit_button = get_node("end_game/main_node/end_button")
onready var enemies_collection = get_node("enemies")

var game_started = false

func _ready():
	player.connect("on_death", self, "on_lose")
	play_again_button.connect("pressed", self, "restart_game")
	exit_button.connect("pressed", self, "exit_game")
	end_game_node.hide()
	set_physics_process(true)
	set_process_input(true)

func _input(event):
	if(event.is_action_pressed("ui_accept")):
		get_node("tutorial").hide()
		game_started = true
		for x in enemies_collection.get_children():
			x.is_disabled = false
	if(event.is_action_pressed("help")):
		get_node("tutorial").show()

func on_lose():
	end_game_node.show()
	you_won_sprite.hide()
	you_lost_sprite.show()
	get_tree().paused = true

func on_win():
	end_game_node.show()
	you_won_sprite.show()
	you_lost_sprite.hide()
	get_tree().paused = true

func restart_game():
	get_tree().reload_current_scene()
	get_tree().paused = false

func exit_game():
	get_tree().quit()

func _physics_process(delta):
	if(enemies_collection.get_children().size() == 0):
		on_win()