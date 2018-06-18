extends RigidBody2D

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


#in seconds!
export var max_range = 2.0
export var damage = 1
export var temperature = 0.0

onready var main_sprite = get_node("sprite")
onready var sprite_heated = get_node("sprite_heated")
onready var death_timer = get_node("death_timer")

func _ready():
	add_to_group("bullets")
	connect("body_enter", self, "on_body_enter")
	death_timer.connect("timeout", self, "on_end_life")
	death_timer.wait_time = max_range
	death_timer.start()
	update_sprite()

func set_max_range(val):
	max_range = val

func get_max_range():
	return max_range

func on_end_life():
	queue_free()

func set_temperature(val):
	if(val > 100.0):
		temperature = 100.0
	elif(val < 0.0):
		temperature = 0.0
	else:
		temperature = val

func set_damage(val):
	damage = val

func get_damage():
	return damage

#updated the sprite based on temperature
func update_sprite():
	if(temperature <= 90.0): #less than 90, the bullet shows the usual sprite:
		main_sprite.show()
		sprite_heated.hide()
		main_sprite.material.set_shader_param("val", temperature/100.0)
	elif(temperature > 90.0):
		main_sprite.hide()
		sprite_heated.show()

func on_body_enter(body):
	queue_free()