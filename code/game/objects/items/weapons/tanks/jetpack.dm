/obj/item/weapon/tank/jetpack
	name = "jetpack (empty)"
	desc = "A tank of compressed gas for use as propulsion in zero-gravity areas. Use with caution."
	icon_state = "jetpack"
	item_state = "jetpack"
	w_class = 4
	distribute_pressure = ONE_ATMOSPHERE * O2STANDARD
	actions_types = list(/datum/action/item_action/set_internals, /datum/action/item_action/jetpack_mode)
	var/gas_type = "o2"
	var/on = FALSE
	var/turbo = FALSE
	var/datum/effect_system/trail_follow/ion/ion_trail

/obj/item/weapon/tank/jetpack/New()
	..()
	air_contents.assert_gas(gas_type)
	air_contents.gases[gas_type][MOLES] = (6 * ONE_ATMOSPHERE) * volume / (R_IDEAL_GAS_EQUATION * T20C)

	ion_trail = new
	ion_trail.set_up(src)

/obj/item/weapon/tank/jetpack/ui_action_click(mob/user, actiontype)
	if(actiontype == /datum/action/item_action/jetpack_mode)
		cycle(user)
	else
		toggle_internals(user)


/obj/item/weapon/tank/jetpack/proc/cycle(mob/user)
	if(user.incapacitated())
		return

	if(!on)
		turn_on()
		user << "<span class='notice'>You turn the thrusters on.</span>"
	else if(!turbo)
		turbo = TRUE
		user << "<span class='notice'>You engage turbo mode.</span>"
	else
		turn_off()
		turbo = FALSE
		user << "<span class='notice'>You turn jetpack off.</span>"
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()


/obj/item/weapon/tank/jetpack/proc/turn_on()
	on = TRUE
	icon_state = "[initial(icon_state)]-on"
	ion_trail.start()

/obj/item/weapon/tank/jetpack/proc/turn_off()
	on = FALSE
	icon_state = initial(icon_state)
	ion_trail.stop()

/obj/item/weapon/tank/jetpack/proc/allow_thrust(num, mob/living/user)
	if(!on)
		return
	if((num < 0.005 || air_contents.total_moles() < num))
		turn_off()
		return

	var/datum/gas_mixture/removed = air_contents.remove(num)
	if(removed.total_moles() < 0.005)
		turn_off()
		return

	var/turf/T = get_turf(user)
	T.assume_air(removed)

	return 1

/obj/item/weapon/tank/jetpack/void
	name = "void jetpack (oxygen)"
	desc = "It works well in a void."
	icon_state = "jetpack-void"
	item_state =  "jetpack-void"

/obj/item/weapon/tank/jetpack/oxygen
	name = "jetpack (oxygen)"
	desc = "A tank of compressed oxygen for use as propulsion in zero-gravity areas. Use with caution."
	icon_state = "jetpack"
	item_state = "jetpack"

/obj/item/weapon/tank/jetpack/oxygen/harness
	name = "jet harness (oxygen)"
	desc = "A lightweight tactical harness, used by those who don't want to be weighed down by traditional jetpacks."
	icon_state = "jetpack-mini"
	item_state = "jetpack-mini"
	volume = 40
	throw_range = 7
	w_class = 3

/obj/item/weapon/tank/jetpack/oxygen/captain
	name = "\improper Captain's jetpack"
	desc = "A compact, lightweight jetpack containing a high amount of compressed oxygen."
	icon_state = "jetpack-captain"
	item_state = "jetpack-captain"
	w_class = 3
	volume = 90

/obj/item/weapon/tank/jetpack/carbondioxide
	name = "jetpack (carbon dioxide)"
	desc = "A tank of compressed carbon dioxide for use as propulsion in zero-gravity areas. Painted black to indicate that it should not be used as a source for internals."
	icon_state = "jetpack-black"
	item_state =  "jetpack-black"
	distribute_pressure = 0
	gas_type = "co2"

/obj/item/weapon/tank/jetpack/suit
	name = "suit inbuilt jetpack"
	desc = "A device that will use your internals tank as a gas source for propulsion."
	icon_state = "jetpack-void"
	item_state =  "jetpack-void"
	actions_types = list(/datum/action/item_action/jetpack_mode)
	var/obj/item/weapon/tank/internals/tank = null

/obj/item/weapon/tank/jetpack/suit/New()
	..()
	SSobj.processing -= src
	air_contents = null

/obj/item/weapon/tank/jetpack/suit/cycle(mob/user)
	var/mob/living/carbon/human/H = user
	if(!istype(H.s_store, /obj/item/weapon/tank/internals))
		user << "<span class='warning'>You need a tank in your suit storage!</span>"
		return
	..()

/obj/item/weapon/tank/jetpack/suit/turn_on()
	if(!ishuman(loc.loc))
		return
	var/mob/living/carbon/human/H = loc.loc
	tank = H.s_store
	air_contents = tank.air_contents
	SSobj.processing |= src
	..()

/obj/item/weapon/tank/jetpack/suit/turn_off()
	tank = null
	air_contents = null
	SSobj.processing -= src
	..()

/obj/item/weapon/tank/jetpack/suit/process()
	if(!ishuman(loc.loc))
		turn_off()
		return
	var/mob/living/carbon/human/H = loc.loc
	if(!tank || tank != H.s_store)
		turn_off()
		return
	..()
