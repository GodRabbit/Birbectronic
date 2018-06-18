extends KinematicBody2D

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


onready var player_body = get_node("body")
onready var player_neck = get_node("body/neck")
onready var player_head = get_node("body/neck/player_head")
onready var bullets_node = get_parent().get_node("bullets")
onready var bullet_pos_end = get_node("body/neck/player_head/pos_end")
onready var bullet_pos_start = get_node("body/neck/player_head/pos_start")
onready var invinc_timer = get_node("invinc_timer")
onready var hud = get_node("hud")
onready var BulletClass = load("res://scenes/bullet_basic.tscn")

#sprites affected by temperature:
onready var head_sprite = get_node("body/neck/player_head/sprite")
onready var cannon_sprite = get_node("body/neck/player_head/head_canon/sprite")

#disable timers:
onready var body_disable_timer = get_node("circular_timer")
onready var head_disable_timer = get_node("body/neck/player_head/circular_timer")
onready var cannon_disable_timer = get_node("body/neck/player_head/head_canon/circular_timer") 

const SIDE_LEFT = "side_left"
const SIDE_RIGHT = "side_right"

var head_rotation = 39.2
var neck_rotation = 39.2

#all temperatures scaled to 0-100 basis, to prevent complications
const max_temperature = 100
const min_head_temperature = 5
const min_body_temperature = 10
const min_cannon_temperature = 1
const cooling_speed = 3
const disabeling_max_time = 1.5 #how much seconds each part needs to be at max temperature to be disabled

var body_temp_raising_speed = 0.1
export var body_temperature = 25.0

#counts toward disabling the body, each second at max temperature
#raise this counter. When at <disabeling_max_time>, the body is disabled
var body_counter_to_disable = 0.0
var is_body_disabled = false

var head_temp_raising_speed = 0.2
export var head_temperature = 25.0

var head_counter_to_disable = 0.0
var is_head_disabled = false

var cannon_temp_raising_speed = 1
export var cannon_temperature = 20.0
var cannon_counter_to_disable = 0.0
var is_cannon_disabled = false

export var max_health = 50.0
var hp_regen = 0.6
var is_invincible = false

export var current_side = SIDE_RIGHT

var current_health = max_health

var velocity = Vector2(0, 0)
var move_speed = 30

#a property of the player, not the current speed, but the potential speed of the head
var head_rot_speed = 0.005
var neck_rot_speed = 0.05

#force managment:
#this is very important in managing tight controls
#0.0 feels bad and clunky, and small numbers making the movemant a bit
#smoother and more realistic. [i.e more "tight"]
#numbers too high on force_time will make the controls feel really bad
const force_time = 0.1
var force_countdown = 0.0
var is_force_apply = false

#this is the CURRENT speed of the head.
var head_rotation_velocity = 0.0
const head_rotate_force_time = 0.05
var head_rotate_force_countdown = 0.0
var is_head_rotate_force_apply = false

#shooting mangment:
var atk_speed = 5 #deprecated for now
var atk_range = 0.7 #in seconds
var shot_speed = 50

var is_shooting = false

#the potential damage dealing ability of the player
var strength = 5

signal on_death

func _ready():
	self.add_to_group("player")
	player_head.add_to_group("player_head")
	set_physics_process(true)
	
	#handle signals:
	head_disable_timer.connect("timeout", self, "re_enable_head")
	body_disable_timer.connect("timeout", self, "re_enable_body")
	cannon_disable_timer.connect("timeout", self, "re_enable_cannon")
	invinc_timer.connect("timeout", self, "on_invinc_end")

func set_head_rotation(val):
	var d = val-head_rotation
	head_rotation = val
	player_head.rotate(d)

func add_head_rotation(val):
	set_head_rotation(head_rotation+val)

func set_neck_rotation(val):
	var d = val-neck_rotation
	neck_rotation = val
	player_neck.rotate(d)

func add_neck_rotation(val):
	set_neck_rotation(neck_rotation + val)

func set_side(side):
	if(current_side == side):
		return
	if(side == SIDE_RIGHT):
		apply_scale(Vector2(-1, 1))
		current_side = SIDE_RIGHT
	else:
		apply_scale(Vector2(-1, 1))
		current_side = SIDE_LEFT

#signals the code that a force is now applying, hence creating
#acceleration and raising tempertaure
func start_force():
	force_countdown = 0.0
	is_force_apply = true

func stop_force():
	force_countdown = 0.0
	is_force_apply = false

#gets the amount of speed reduction based on whether or not there is force
#applying
func get_force_percent():
	if(!is_force_apply):
		return 0.0
	var d = 1.0-(force_countdown/force_time)
	if(d > 1):
		return 1.0
	elif(d < 0):
		return 0.0
	else:
		return d

func start_head_force():
	head_rotate_force_countdown = 0.0
	is_head_rotate_force_apply = true

func stop_head_force():
	head_rotate_force_countdown = 0.0
	is_head_rotate_force_apply = false

func get_head_force_percent():
	if(!is_head_rotate_force_apply):
		return 0.0
	var d =  1 - (head_rotate_force_countdown/head_rotate_force_time)
	if(d > 1):
		return 1.0
	elif(d < 0):
		return 0.0
	else:
		return d

func get_input():
	if(!is_force_apply):
		velocity = Vector2(0, 0)
	if(Input.is_action_pressed("ui_right") && !is_body_disabled):
		velocity.x += 1
		set_side(SIDE_RIGHT)
		start_force()
		add_body_temperature(body_temp_raising_speed)
	elif(Input.is_action_pressed("ui_left") && !is_body_disabled):
		velocity.x -= 1
		set_side(SIDE_LEFT)
		start_force()
		add_body_temperature(body_temp_raising_speed)
	if(Input.is_action_pressed("ui_down") && !is_body_disabled):
		velocity.y += 1
		add_body_temperature(body_temp_raising_speed)
	elif(Input.is_action_pressed("ui_up") && !is_body_disabled):
		velocity.y -= 1
		add_body_temperature(body_temp_raising_speed)
	velocity = velocity.normalized() * move_speed
	velocity = Vector2(velocity.x*get_force_percent(), velocity.y)
	if(!is_head_rotate_force_apply):
		head_rotation_velocity = 0.0
	if(Input.is_action_pressed("head_control_up") && !is_head_disabled):
		head_rotation_velocity +=  -head_rot_speed
		start_head_force()
		add_head_temperature(head_temp_raising_speed)
	elif(Input.is_action_pressed("head_control_down") && !is_head_disabled):
		head_rotation_velocity += head_rot_speed
		start_head_force()
		add_head_temperature(head_temp_raising_speed)
	elif(Input.is_action_pressed("neck_control_up")):
		add_neck_rotation(-neck_rot_speed)
	elif(Input.is_action_pressed("neck_control_down")):
		add_neck_rotation(neck_rot_speed)
	head_rotation_velocity = head_rotation_velocity * get_head_force_percent()
	if(Input.is_action_pressed("shoot") && !is_cannon_disabled): # when the player shoots
		#handle bullet properties:
		var b = BulletClass.instance()
		var v = bullet_pos_end.global_position - bullet_pos_start.global_position
		v = v * (shot_speed + velocity.length())
		#v = v.rotated(head_rotation+ 2*39.2 +PI/2.0)
		b.rotate(head_rotation + 39.2)
		if(current_side == SIDE_LEFT):
			b.apply_scale(Vector2(-1, 1))
		b.global_translate(bullet_pos_end.global_position)
		b.add_force(Vector2(0, 0), v)
		b.set_max_range(atk_range)
		b.set_temperature(get_bullet_temperature())
		b.set_damage(get_total_damage())
		bullets_node.add_child(b)
		add_cannon_temperature(cannon_temp_raising_speed)
		is_shooting = true
	else:
		is_shooting = false

func _physics_process(delta):
	get_input()
	var collision_data = move_and_collide(velocity) 
	add_head_rotation(head_rotation_velocity)
	
	#control force and acceleration of head rotation and body:
	if(is_force_apply):
		force_countdown += delta
		if(force_countdown > force_time):
			stop_force()
	else:
		add_body_temperature(-cooling_speed*delta)
	
	if(is_head_rotate_force_apply):
		head_rotate_force_countdown += delta
		if(head_rotate_force_countdown > head_rotate_force_time):
			stop_head_force()
	else:
		add_head_temperature(-cooling_speed*delta)
	
	if(!is_shooting):
		add_cannon_temperature(-cooling_speed*delta)
	
	#handle hp reduction due to high heat:
	add_health(get_health_reduction()*delta)
	
	#check if the temperature is too high, for disable:
	if(get_current_head_temperature() >= max_temperature):
		head_counter_to_disable += delta
		if(head_counter_to_disable >= disabeling_max_time):
			disable_head()
	else:
		head_counter_to_disable = 0.0
	
	if(get_current_body_temperature() >= max_temperature):
		body_counter_to_disable += delta
		if(body_counter_to_disable >= disabeling_max_time):
			disable_body()
	else:
			body_counter_to_disable = 0.0
	
	if(get_current_cannon_temperature() >= max_temperature):
		cannon_counter_to_disable += delta
		if(cannon_counter_to_disable >= disabeling_max_time):
			disable_cannon()
	else:
			cannon_counter_to_disable = 0.0
	
#	if(collision_data!= null && collision_data.collider.is_in_group("enemies")):
#		on_hurt(-collision_data.collider.get_damage())
	
	#update sprites:
	update_sprites()
	
	#update hud:
	hud.set_player(self)

func get_current_health():
	return current_health

func set_health(val):
	if(val > max_health):
		current_health = max_health
	elif(val <= 0.0):
		current_health = 0.0
		emit_signal("on_death")
	else:
		current_health = val

func add_health(val):
	set_health(get_current_health() + val)

func get_health_percent():
	return (current_health/max_health)*100.0

#how much hp you lose, based on temperature
func get_health_reduction():
	var d = hp_regen
	if(body_temperature > 50.0):
		d = d - 0.5*(get_current_body_temperature()/100.0)
	elif(is_body_disabled): #if body is disabled you are losing A LOT more hp
		d = d - 1
	if(head_temperature > 40.0):
		d = d - 0.4*(get_current_head_temperature()/100.0)
	elif(is_head_disabled): # while head is disabeled you are losing tons of hp
		d = d - 0.8
	if(cannon_temperature > 90.0):
		d = d - 0.1*(get_current_cannon_temperature()/100.0)
	elif(is_cannon_disabled): #you lose some hp while cannon is disabeled
		d = d - 0.1
	return d

func get_current_head_temperature():
	return head_temperature

func set_current_head_temperature(val):
	if(val > max_temperature):
		head_temperature = max_temperature
	elif(val < min_head_temperature):
		head_temperature = min_head_temperature
	else:
		head_temperature = val

func add_head_temperature(val):
	set_current_head_temperature(get_current_head_temperature() + val)

func disable_head():
	is_head_disabled = true
	head_disable_timer.start()
	head_counter_to_disable = 0.0
	set_current_head_temperature(0.0)

func re_enable_head():
	head_disable_timer.stop()
	is_head_disabled = false
	set_current_head_temperature(0.0)

func get_current_body_temperature():
	return body_temperature

func set_current_body_temperature(val):
	if(val > max_temperature):
		body_temperature = max_temperature
	elif(val < min_body_temperature):
		body_temperature = min_body_temperature
	else:
		body_temperature = val

func add_body_temperature(val):
	set_current_body_temperature(get_current_body_temperature() + val)

func disable_body():
	is_body_disabled = true
	body_disable_timer.start()
	body_counter_to_disable = 0.0
	set_current_body_temperature(0.0)

func re_enable_body():
	body_disable_timer.stop()
	is_body_disabled = false
	set_current_body_temperature(0.0)

func get_current_cannon_temperature():
	return cannon_temperature

func set_current_cannon_temperature(val):
	if(val > max_temperature):
		cannon_temperature = max_temperature
	elif(val < min_cannon_temperature):
		cannon_temperature = min_cannon_temperature
	else:
		cannon_temperature = val

func add_cannon_temperature(val):
	set_current_cannon_temperature(get_current_cannon_temperature() + val)

func disable_cannon():
	is_cannon_disabled = true
	cannon_disable_timer.start()
	cannon_counter_to_disable = 0.0
	set_current_cannon_temperature(0.0)

func re_enable_cannon():
	cannon_disable_timer.stop()
	is_cannon_disabled = false
	set_current_cannon_temperature(0.0)

#neck temperature depends on the body and head temperature
#neck does not heat while moving
func get_current_neck_temperature():
	var ht = get_current_head_temperature() #short for head temperature
	var bt = get_current_body_temperature() #short for body temperature
	var ct = get_current_cannon_temperature() #short for cannon tmperature
	var t = 0.5*bt+0.45*ht + 0.05*ct #50% of body heat, 45% of head heat and 5% of cannon heat
	return t

#update the sprites based on the heat of the different parts
func update_sprites():
	if(!is_body_disabled):
		player_body.material.set_shader_param("val", get_current_body_temperature()/100.0)
		player_body.material.set_shader_param("is_dead", false)
	else:
		player_body.material.set_shader_param("is_dead", true)
	
	if(!is_head_disabled):
		head_sprite.material.set_shader_param("val", get_current_head_temperature()/100.0)
		head_sprite.material.set_shader_param("is_dead", false)
	else:
		head_sprite.material.set_shader_param("is_dead", true)
	
	if(is_body_disabled && is_head_disabled): #neck is disabled only if the body and the head are disabled
		player_neck.material.set_shader_param("is_dead", true)
	else:
		player_neck.material.set_shader_param("val", get_current_neck_temperature()/100.0)
		player_neck.material.set_shader_param("is_dead", false)
	
	if(!is_cannon_disabled):
		cannon_sprite.material.set_shader_param("val", get_current_cannon_temperature()/100.0)
		cannon_sprite.material.set_shader_param("is_dead", false)
	else:
		cannon_sprite.material.set_shader_param("is_dead", true)

func get_total_damage():
	var f = 0.15*(get_current_body_temperature()/100.0) #15% of body heat is converted to damage
	f += 0.35*(get_current_head_temperature()/100.0) #35% of head heat is converted to damage
	f += 0.5*(get_current_cannon_temperature()/100.0) #and 50% of cannon heat
	if(get_bullet_temperature() > 90): #super strong damage on high temperatures
		f = f*2.0
	return strength*f

func get_bullet_temperature():
	var ht = get_current_head_temperature() #short for head temperature
	var bt = get_current_body_temperature() #short for body temperature
	var ct = get_current_cannon_temperature() #short for cannon tmperature
	return 0.8*ct + 0.15*ht +0.05*bt #80% of cannon heat, 15% of head heat and 5% of body heat

func on_hurt(dmg):
	if(!is_invincible):
		add_health(dmg)
		invinc_timer.start()
		is_invincible = true

func on_invinc_end():
	is_invincible = false