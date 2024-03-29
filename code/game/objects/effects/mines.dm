/obj/effect/mine
	name = "dummy mine"
	desc = "Better stay away from that thing."
	density = 0
	anchored = 1
	layer = 3
	icon = 'icons/obj/weapons.dmi'
	icon_state = "uglymine"
	var/triggered = 0

/obj/effect/mine/proc/mineEffect(mob/victim)
	victim << "<span class='danger'>*click*</span>"

/obj/effect/mine/Crossed(AM as mob|obj)
	if(isanimal(AM))
		var/mob/living/simple_animal/SA = AM
		if(!SA.flying)
			triggermine(SA)
	else
		triggermine(AM)

/obj/effect/mine/proc/triggermine(mob/victim)
	if(triggered)
		return
	visible_message("<span class='danger'>[victim] sets off \icon[src] [src]!</span>")
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(3, 1, src)
	s.start()
	mineEffect(victim)
	triggered = 1
	qdel(src)


/obj/effect/mine/explosive
	name = "explosive mine"
	var/range_devastation = 0
	var/range_heavy = 1
	var/range_light = 2
	var/range_flash = 3

/obj/effect/mine/explosive/mineEffect(mob/victim)
	explosion(loc, range_devastation, range_heavy, range_light, range_flash)


/obj/effect/mine/stun
	name = "stun mine"
	var/stun_time = 8

/obj/effect/mine/stun/mineEffect(mob/victim)
	if(isliving(victim))
		victim.Weaken(stun_time)

/obj/effect/mine/kickmine
	name = "kick mine"

/obj/effect/mine/kickmine/mineEffect(mob/victim)
	if(isliving(victim) && victim.client)
		victim << "<span class='userdanger'>You have been kicked FOR NO REISIN!</span>"
		del(victim.client)


/obj/effect/mine/gas
	name = "oxygen mine"
	var/gas_amount = 360
	var/gas_type = SPAWN_OXYGEN

/obj/effect/mine/gas/mineEffect(mob/victim)
	atmos_spawn_air(gas_type, gas_amount)


/obj/effect/mine/gas/plasma
	name = "plasma mine"
	gas_type = SPAWN_TOXINS


/obj/effect/mine/gas/n2o
	name = "\improper N2O mine"
	gas_type = SPAWN_N2O


/obj/effect/mine/sound
	name = "honkblaster 1000"
	var/sound = 'sound/items/bikehorn.ogg'

/obj/effect/mine/sound/mineEffect(mob/victim)
	playsound(loc, sound, 100, 1)


/obj/effect/mine/sound/bwoink
	name = "bwoink mine"
	sound = 'sound/effects/adminhelp.ogg'

/obj/effect/mine/pickup
	name = "pickup"
	desc = "pick me up"
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity2"
	density = 0
	var/duration = 0

/obj/effect/mine/pickup/New()
	..()
	animate(src, pixel_y = 4, time = 20, loop = -1)

/obj/effect/mine/pickup/triggermine(mob/victim)
	if(triggered)
		return
	triggered = 1
	invisibility = 101
	mineEffect(victim)
	qdel(src)


/obj/effect/mine/pickup/bloodbath
	name = "Red Orb"
	desc = "You feel angry just looking at it."
	duration = 1200 //2min
	color = "red"

/obj/effect/mine/pickup/bloodbath/mineEffect(mob/living/carbon/victim)
	if(!victim.client || !istype(victim))
		return
	victim << "<span class='reallybig redtext'>KILL EM ALL</span>"
	var/old_color = victim.client.color
	var/red_splash = list(1,0,0,0.8,0.2,0, 0.8,0,0.2,0.1,0,0)
	var/pure_red = list(0,0,0,0,0,0,0,0,0,1,0,0)

	spawn(0)
		new /obj/effect/hallucination/delusion(victim.loc,victim,force_kind="demon",duration=duration,skip_nearby=0)

	var/obj/item/weapon/twohanded/required/chainsaw/chainsaw = new(victim.loc)
	chainsaw.flags |= NODROP
	victim.drop_r_hand()
	victim.drop_l_hand()
	victim.put_in_hands(chainsaw)

	victim.reagents.add_reagent("adminordrazine",25)

	victim.client.color = pure_red
	animate(victim.client,color = red_splash, time = 10, easing = SINE_EASING|EASE_OUT)
	sleep(10)
	animate(victim.client,color = old_color, time = duration)//, easing = SINE_EASING|EASE_OUT)
	sleep(duration)
	victim << "<span class='notice'>You feel calm again.<span>"
	qdel(chainsaw)
	qdel(src)

/obj/effect/mine/pickup/healing
	name = "Blue Orb"
	desc = "You feel better just looking at it."
	color = "blue"

/obj/effect/mine/pickup/healing/mineEffect(mob/living/carbon/victim)
	if(!victim.client || !istype(victim))
		return
	victim << "<span class='notice'>You feel great!</span>"
	victim.revive(full_heal = 1, admin_revive = 1)

/obj/effect/mine/pickup/speed
	name = "Yellow Orb"
	desc = "You feel faster just looking at it."
	color = "yellow"
	duration = 300

/obj/effect/mine/pickup/speed/mineEffect(mob/living/carbon/victim)
	if(!victim.client || !istype(victim))
		return
	victim << "<span class='notice'>You feel fast!</span>"
	victim.status_flags |= GOTTAGOREALLYFAST
	sleep(duration)
	victim.status_flags &= ~GOTTAGOREALLYFAST
	victim << "<span class='notice'>You slow down.</span>"