extends Control

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

#general purpose GUI for timer with a circular progress bar counting down

#progress is going down from 100 to 0, as time goes by
onready var progress = get_node("progress")
#timer start at max time and goes to 0.0
onready var label = get_node("timer_label")

#in seconds:
export var wait_time = 5.0
export var is_counting = false

var counter = 0.0

signal timeout

func _ready():
	update_gui()

func start():
	counter = 0.0
	set_physics_process(true)
	is_counting = true
	self.show()

func stop():
	set_physics_process(false)
	counter = wait_time
	is_counting = false
	self.hide()

func _physics_process(delta):
	if(is_counting):
		counter+= delta
		if(counter >= wait_time):
			emit_signal("timeout")
			counter = 0.0
	update_gui()

func update_gui():
	if(is_counting):
		var p = (1-(counter/wait_time))*100.0 #count DOWN, the progress is from 100 to 0
		progress.value = p
		var format ="%.1f"
		label.set_text(format % (wait_time - counter))
	else:
		stop()