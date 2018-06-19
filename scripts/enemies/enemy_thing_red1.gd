extends Area2D

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

onready var progress = get_node("progress")
onready var move_timer = get_node("move_timer")

export var is_disabled = false
export var max_hp = 15.0
var current_hp = max_hp
var damage = 3
var speed = 25
var velocity = Vector2(1,1)

func _ready():
	set_physics_process(true)
	add_to_group("enemies")
	connect("body_entered", self, "on_body_entered")
	move_timer.connect("timeout", self, "random_move")
	random_move()

func _physics_process(delta):
	if(is_disabled):
		hide()
		return
	show()
	global_translate(velocity * delta)
	
	for x in get_overlapping_bodies():
		if(x.is_in_group("player")):
			x.on_hurt(-get_damage())
		if(x.is_in_group("player_head")):
			x.get_parent().get_parent().get_parent().on_hurt(-get_damage()) #nasty but I dont have time for pretty code :((
		if(x.is_in_group("walls")):
			add_hp(-1)

func get_damage():
	return damage

func get_current_hp():
	return current_hp

func set_current_hp(val):
	if(val > max_hp):
		current_hp = max_hp
	elif(val <= 0.0):
		current_hp = 0.0
		on_death()
	else:
		current_hp = val

func add_hp(val):
	set_current_hp(get_current_hp() + val)
	update_gui()

func get_percent_hp():
	return (current_hp/max_hp)*100.0

func on_death():
	queue_free()

func update_gui():
	progress.value = get_percent_hp()

func random_move():
	var v = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0))
	v = v.normalized()*speed
	velocity = v
	move_timer.start()

func on_body_entered(body):
	if(body.is_in_group("bullets")):
		add_hp(-body.get_damage())