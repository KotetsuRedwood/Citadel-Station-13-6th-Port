//backpack item

/obj/item/weapon/defibrillator
	name = "defibrillator"
	desc = "A device that delivers powerful shocks to detachable paddles that resuscitate incapacitated patients."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "defibunit"
	item_state = "defibunit"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	w_class = 4
	origin_tech = "biotech=4"
	actions_types = list(/datum/action/item_action/toggle_paddles)

	var/on = 0 //if the paddles are equipped (1) or on the defib (0)
	var/safety = 1 //if you can zap people with the defibs on harm mode
	var/powered = 0 //if there's a cell in the defib with enough power for a revive, blocks paddles from reviving otherwise
	var/obj/item/weapon/twohanded/shockpaddles/paddles
	var/obj/item/weapon/stock_parts/cell/high/bcell = null
	var/combat = 0 //can we revive through space suits?

/obj/item/weapon/defibrillator/New() //starts without a cell for rnd
	..()
	paddles = make_paddles()
	update_icon()
	return

/obj/item/weapon/defibrillator/loaded/New() //starts with hicap
	..()
	paddles = make_paddles()
	bcell = new(src)
	update_icon()
	return

/obj/item/weapon/defibrillator/update_icon()
	update_power()
	update_overlays()
	update_charge()

/obj/item/weapon/defibrillator/proc/update_power()
	if(bcell)
		if(bcell.charge < paddles.revivecost)
			powered = 0
		else
			powered = 1
	else
		powered = 0

/obj/item/weapon/defibrillator/proc/update_overlays()
	overlays.Cut()
	if(!on)
		overlays += "[initial(icon_state)]-paddles"
	if(powered)
		overlays += "[initial(icon_state)]-powered"
	if(!bcell)
		overlays += "[initial(icon_state)]-nocell"
	if(!safety)
		overlays += "[initial(icon_state)]-emagged"

/obj/item/weapon/defibrillator/proc/update_charge()
	if(powered) //so it doesn't show charge if it's unpowered
		if(bcell)
			var/ratio = bcell.charge / bcell.maxcharge
			ratio = Ceiling(ratio*4) * 25
			overlays += "[initial(icon_state)]-charge[ratio]"

/obj/item/weapon/defibrillator/CheckParts()
	bcell = locate(/obj/item/weapon/stock_parts/cell) in contents
	update_icon()

/obj/item/weapon/defibrillator/ui_action_click()
	toggle_paddles()

/obj/item/weapon/defibrillator/attack_hand(mob/user)
	if(loc == user)
		if(slot_flags == SLOT_BACK)
			if(user.get_item_by_slot(slot_back) == src)
				ui_action_click()
			else
				user << "<span class='warning'>Put the defibrillator on your back first!</span>"

		else if(slot_flags == SLOT_BELT)
			if(user.get_item_by_slot(slot_belt) == src)
				ui_action_click()
			else
				user << "<span class='warning'>Strap the defibrillator's belt on first!</span>"
		return
	..()

/obj/item/weapon/defibrillator/MouseDrop(obj/over_object)
	if(ismob(src.loc))
		var/mob/M = src.loc
		switch(over_object.name)
			if("r_hand")
				if(M.r_hand)
					return
				if(!M.unEquip(src))
					return
				M.put_in_r_hand(src)
			if("l_hand")
				if(M.l_hand)
					return
				if(!M.unEquip(src))
					return
				M.put_in_l_hand(src)

/obj/item/weapon/defibrillator/attackby(obj/item/weapon/W, mob/user, params)
	if(W == paddles)
		paddles.unwield()
		toggle_paddles()
	if(istype(W, /obj/item/weapon/stock_parts/cell))
		var/obj/item/weapon/stock_parts/cell/C = W
		if(bcell)
			user << "<span class='notice'>[src] already has a cell.</span>"
		else
			if(C.maxcharge < paddles.revivecost)
				user << "<span class='notice'>[src] requires a higher capacity cell.</span>"
				return
			if(!user.unEquip(W))
				return
			W.loc = src
			bcell = W
			user << "<span class='notice'>You install a cell in [src].</span>"

	if(istype(W, /obj/item/weapon/screwdriver))
		if(bcell)
			bcell.updateicon()
			bcell.loc = get_turf(src.loc)
			bcell = null
			user << "<span class='notice'>You remove the cell from [src].</span>"

	update_icon()
	return

/obj/item/weapon/defibrillator/emag_act(mob/user)
	if(safety)
		safety = 0
		user << "<span class='warning'>You silently disable [src]'s safety protocols with the cryptographic sequencer."
	else
		safety = 1
		user << "<span class='notice'>You silently enable [src]'s safety protocols with the cryptographic sequencer."

/obj/item/weapon/defibrillator/emp_act(severity)
	if(bcell)
		deductcharge(1000 / severity)
		if(bcell.reliability != 100 && prob(50/severity))
			bcell.reliability -= 10 / severity
	if(safety)
		safety = 0
		src.visible_message("<span class='notice'>[src] beeps: Safety protocols disabled!</span>")
		playsound(get_turf(src), 'sound/machines/defib_saftyOff.ogg', 50, 0)
	else
		safety = 1
		src.visible_message("<span class='notice'>[src] beeps: Safety protocols enabled!</span>")
		playsound(get_turf(src), 'sound/machines/defib_saftyOn.ogg', 50, 0)
	update_icon()
	..()

/obj/item/weapon/defibrillator/proc/toggle_paddles()
	set name = "Toggle Paddles"
	set category = "Object"
	on = !on

	var/mob/living/carbon/human/user = usr
	if(on)
		//Detach the paddles into the user's hands
		if(!usr.put_in_hands(paddles))
			on = 0
			user << "<span class='warning'>You need a free hand to hold the paddles!</span>"
			update_icon()
			return
		paddles.loc = user
	else
		//Remove from their hands and back onto the defib unit
		paddles.unwield()
		remove_paddles(user)

	update_icon()
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/weapon/defibrillator/proc/make_paddles()
	return new /obj/item/weapon/twohanded/shockpaddles(src)

/obj/item/weapon/defibrillator/equipped(mob/user, slot)
	..()
	if((slot_flags == SLOT_BACK && slot != slot_back) || (slot_flags == SLOT_BELT && slot != slot_belt))
		remove_paddles(user)
		update_icon()

/obj/item/weapon/defibrillator/item_action_slot_check(slot, mob/user)
	if(slot == user.getBackSlot())
		return 1

/obj/item/weapon/defibrillator/proc/remove_paddles(mob/user)
	var/mob/living/carbon/human/M = user
	if(paddles in get_both_hands(M))
		M.unEquip(paddles,1)
	update_icon()
	return

/obj/item/weapon/defibrillator/Destroy()
	if(on)
		var/M = get(paddles, /mob)
		remove_paddles(M)
	. = ..()
	update_icon()

/obj/item/weapon/defibrillator/proc/deductcharge(chrgdeductamt)
	if(bcell)
		if(bcell.charge < (paddles.revivecost+chrgdeductamt))
			powered = 0
			update_icon()
		if(bcell.use(chrgdeductamt))
			update_icon()
			return 1
		else
			update_icon()
			return 0

/obj/item/weapon/defibrillator/proc/cooldowncheck(mob/user)
	spawn(50)
		if(bcell)
			if(bcell.charge >= paddles.revivecost)
				user.visible_message("<span class='notice'>[src] beeps: Unit ready.</span>")
				playsound(get_turf(src), 'sound/machines/defib_ready.ogg', 50, 0)
			else
				user.visible_message("<span class='notice'>[src] beeps: Charge depleted.</span>")
				playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
		paddles.cooldown = 0
		paddles.update_icon()
		update_icon()

/obj/item/weapon/defibrillator/compact
	name = "compact defibrillator"
	desc = "A belt-equipped defibrillator that can be rapidly deployed."
	icon_state = "defibcompact"
	item_state = "defibcompact"
	w_class = 3
	slot_flags = SLOT_BELT
	origin_tech = "biotech=4"

/obj/item/weapon/defibrillator/compact/item_action_slot_check(slot, mob/user)
	if(slot == user.getBeltSlot())
		return 1

/obj/item/weapon/defibrillator/compact/loaded/New()
	..()
	paddles = make_paddles()
	bcell = new(src)
	update_icon()
	return

/obj/item/weapon/defibrillator/compact/combat
	name = "combat defibrillator"
	desc = "A belt-equipped blood-red defibrillator that can be rapidly deployed. Does not have the restrictions or safeties of conventional defibrillators and can revive through space suits."
	combat = 1
	safety = 0

/obj/item/weapon/defibrillator/compact/combat/loaded/New()
	..()
	paddles = make_paddles()
	bcell = new /obj/item/weapon/stock_parts/cell/infinite(src)
	update_icon()
	return

/obj/item/weapon/defibrillator/compact/combat/loaded/attackby(obj/item/weapon/W, mob/user, params)
	if(W == paddles)
		paddles.unwield()
		toggle_paddles()
		update_icon()
		return

//paddles

/obj/item/weapon/twohanded/shockpaddles
	name = "defibrillator paddles"
	desc = "A pair of plastic-gripped paddles with flat metal surfaces that are used to deliver powerful electric shocks."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "defibpaddles"
	item_state = "defibpaddles"
	force = 0
	throwforce = 6
	w_class = 4
	flags = NODROP

	var/revivecost = 1000
	var/cooldown = 0
	var/busy = 0
	var/obj/item/weapon/defibrillator/defib
	var/req_defib = 1
	var/combat = 0 //If it penetrates armor and gives additional functionality

/obj/item/weapon/twohanded/shockpaddles/proc/recharge(var/time)
	if(req_defib || !time)
		return
	cooldown = 1
	update_icon()
	sleep(time)
	var/turf/T = get_turf(src)
	T.audible_message("<span class='notice'>[src] beeps: Unit is recharged.</span>")
	playsound(T, 'sound/machines/defib_ready.ogg', 50, 0)
	cooldown = 0
	update_icon()

/obj/item/weapon/twohanded/shockpaddles/New(mainunit)
	..()
	if(check_defib_exists(mainunit, src) && req_defib)
		defib = mainunit
		loc = defib
		busy = 0
		update_icon()
	return

/obj/item/weapon/twohanded/shockpaddles/update_icon()
	icon_state = "defibpaddles[wielded]"
	item_state = "defibpaddles[wielded]"
	if(cooldown)
		icon_state = "defibpaddles[wielded]_cooldown"

/obj/item/weapon/twohanded/shockpaddles/suicide_act(mob/user)
	user.visible_message("<span class='danger'>[user] is putting the live paddles on \his chest! It looks like \he's trying to commit suicide.</span>")
	if(req_defib)
		defib.deductcharge(revivecost)
	playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 50, 1, -1)
	return (OXYLOSS)

/obj/item/weapon/twohanded/shockpaddles/dropped(mob/user)
	if(!req_defib)
		return ..()
	if(user)
		var/obj/item/weapon/twohanded/offhand/O = user.get_inactive_hand()
		if(istype(O))
			O.unwield()
		user << "<span class='notice'>The paddles snap back into the main unit.</span>"
		defib.on = 0
		loc = defib
		defib.update_icon()
	return unwield(user)

/obj/item/weapon/twohanded/shockpaddles/proc/check_defib_exists(mainunit, mob/living/carbon/human/M, obj/O)
	if(!req_defib)
		return 1 //If it doesn't need a defib, just say it exists
	if (!mainunit || !istype(mainunit, /obj/item/weapon/defibrillator))	//To avoid weird issues from admin spawns
		M.unEquip(O)
		qdel(O)
		return 0
	else
		return 1

/obj/item/weapon/twohanded/shockpaddles/attack(mob/M, mob/user)
	var/halfwaycritdeath = (config.health_threshold_crit + config.health_threshold_dead) / 2

	if(busy)
		return
	if(req_defib && !defib.powered)
		user.visible_message("<span class='notice'>[defib] beeps: Unit is unpowered.</span>")
		playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
		return
	if(!wielded)
		if(isrobot(user))
			user << "<span class='warning'>You must activate the paddles in your active module before you can use them on someone!</span>"
		else
			user << "<span class='warning'>You need to wield the paddles in both hands before you can use them on someone!</span>"
		return
	if(cooldown)
		if(req_defib)
			user << "<span class='warning'>[defib] is recharging!</span>"
		else
			user << "<span class='warning'>[src] are recharging!</span>"
		return
	if(!ishuman(M))
		if(req_defib)
			user << "<span class='warning'>The instructions on [defib] don't mention how to revive that...</span>"
		else
			user << "<span class='warning'>You aren't sure how to revive that...</span>"
		return
	else
		var/mob/living/carbon/human/H = M
		if(user.a_intent == "disarm")
			if(req_defib && defib.safety)
				return
			if(!req_defib && !combat)
				return
			busy = 1
			H.visible_message("<span class='danger'>[user] has touched [H.name] with [src]!</span>", \
					"<span class='userdanger'>[user] has touched [H.name] with [src]!</span>")
			H.adjustStaminaLoss(50)
			H.Weaken(5)
			H.updatehealth() //forces health update before next life tick
			playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 50, 1, -1)
			H.emote("gasp")
			add_logs(user, M, "stunned", src)
			if(req_defib)
				defib.deductcharge(revivecost)
				cooldown = 1
			busy = 0
			update_icon()
			if(req_defib)
				defib.cooldowncheck(user)
			else
				recharge(60)
			return
		if(user.zone_selected == "chest")
			if(user.a_intent == "harm")
				if(req_defib && defib.safety)
					return
				if(!req_defib && !combat)
					return
				user.visible_message("<span class='warning'>[user] begins to place [src] on [M.name]'s chest.</span>",
					"<span class='warning'>You overcharge the paddles and begin to place them onto [M]'s chest...</span>")
				busy = 1
				update_icon()
				if(do_after(user, 30, target = M))
					user.visible_message("<span class='notice'>[user] places [src] on [M.name]'s chest.</span>",
						"<span class='warning'>You place [src] on [M.name]'s chest and begin to charge them.</span>")
					var/turf/T = get_turf(defib)
					playsound(get_turf(src), 'sound/machines/defib_charge.ogg', 50, 0)
					if(req_defib)
						T.audible_message("<span class='warning'>\The [defib] lets out an urgent beep and lets out a steadily rising hum...</span>")
					else
						user.audible_message("<span class='warning'>[src] let out an urgent beep.</span>")
					if(do_after(user, 30, target = M)) //Takes longer due to overcharging
						if(!M)
							busy = 0
							update_icon()
							return
						if(M && M.stat == DEAD)
							user << "<span class='warning'>[M] is dead.</span>"
							playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
							busy = 0
							update_icon()
							return
						user.visible_message("<span class='boldannounce'><i>[user] shocks [M] with \the [src]!</span>", "<span class='warning'>You shock [M] with \the [src]!</span>")
						playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 100, 1, -1)
						playsound(loc, 'sound/weapons/Egloves.ogg', 100, 1, -1)
						var/mob/living/carbon/human/HU = M
						M.emote("scream")
						if(!HU.heart_attack)
							HU.heart_attack = 1
							if(!HU.stat)
								HU.visible_message("<span class='warning'>[M] thrashes wildly, clutching at their chest!</span>",
									"<span class='userdanger'>You feel a horrible agony in your chest!</span>")
						HU.apply_damage(50, BURN, "chest")
						add_logs(user, M, "overloaded the heart of", defib)
						M.Weaken(5)
						M.Jitter(100)
						if(req_defib)
							defib.deductcharge(revivecost)
							cooldown = 1
						busy = 0
						update_icon()
						if(!req_defib)
							recharge(60)
						if(req_defib && (defib.cooldowncheck(user)))
							return
				busy = 0
				update_icon()
				return
			if(!H.suiciding && !(H.disabilities & NOCLONE))
				H.notify_ghost_cloning("Your heart is being defibrillated. Re-enter your corpse if you want to be revived!", source = src)

			user.visible_message("<span class='warning'>[user] begins to place [src] on [M.name]'s chest.</span>", "<span class='warning'>You begin to place [src] on [M.name]'s chest...</span>")
			busy = 1
			update_icon()
			if(do_after(user, 30, target = M)) //beginning to place the paddles on patient's chest to allow some time for people to move away to stop the process
				user.visible_message("<span class='notice'>[user] places [src] on [M.name]'s chest.</span>", "<span class='warning'>You place [src] on [M.name]'s chest.</span>")
				playsound(get_turf(src), 'sound/machines/defib_charge.ogg', 50, 0)
				var/tplus = world.time - H.timeofdeath
				var/tlimit = 1200 //past this much time the patient is unrecoverable (in deciseconds)
				var/tloss = 600 //brain damage starts setting in on the patient after some time left rotting
				var/total_burn	= 0
				var/total_brute	= 0
				if(do_after(user, 20, target = M)) //placed on chest and short delay to shock for dramatic effect, revive time is 5sec total
					for(var/obj/item/carried_item in H.contents)
						if(istype(carried_item, /obj/item/clothing/suit/space))
							if((!src.combat && !req_defib) || (req_defib && !defib.combat))
								user.audible_message("<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Patient's chest is obscured. Operation aborted.</span>")
								playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
								busy = 0
								update_icon()
								return
					if(H.stat == DEAD)
						M.visible_message("<span class='warning'>[M]'s body convulses a bit.")
						playsound(get_turf(src), "bodyfall", 50, 1)
						playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 50, 1, -1)
						total_brute	= H.getBruteLoss()
						total_burn	= H.getFireLoss()

						var/failed = null

						if (H.suiciding || (H.disabilities & NOCLONE))
							failed = "<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Resuscitation failed - Recovery of patient impossible. Further attempts futile.</span>"
						else if ((tplus > tlimit) || !H.getorgan(/obj/item/organ/internal/heart))
							failed = "<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Resuscitation failed - Heart tissue damage beyond point of no return. Further attempts futile.</span>"
						else if(total_burn >= 180 || total_brute >= 180)
							failed = "<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Resuscitation failed - Severe tissue damage makes recovery of patient impossible via defibrillator. Further attempts futile.</span>"
						else if(H.get_ghost())
							failed = "<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Resuscitation failed - No activity in patient's brain. Further attempts may be successful.</span>"
						else
							var/obj/item/organ/internal/brain/BR = H.getorgan(/obj/item/organ/internal/brain)
							if(!BR || BR.damaged_brain)
								failed = "<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Resuscitation failed - Patient's brain is missing or damaged beyond point of no return. Further attempts futile.</span>"

						if(failed)
							user.visible_message(failed)
							playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
						else
							//If the body has been fixed so that they would not be in crit when defibbed, give them oxyloss to put them back into crit
							if (H.health > halfwaycritdeath)
								H.adjustOxyLoss(H.health - halfwaycritdeath, 0)
							else
								var/overall_damage = total_brute + total_burn + H.getToxLoss() + H.getOxyLoss()
								var/mobhealth = H.health
								H.adjustOxyLoss((mobhealth - halfwaycritdeath) * (H.getOxyLoss() / overall_damage), 0)
								H.adjustToxLoss((mobhealth - halfwaycritdeath) * (H.getToxLoss() / overall_damage), 0)
								H.adjustFireLoss((mobhealth - halfwaycritdeath) * (total_burn / overall_damage), 0)
								H.adjustBruteLoss((mobhealth - halfwaycritdeath) * (total_brute / overall_damage), 0)
							user.visible_message("<span class='notice'>[req_defib ? "[defib]" : "[src]"] pings: Resuscitation successful.</span>")
							playsound(get_turf(src), 'sound/machines/defib_success.ogg', 50, 0)
							H.revive()
							H.emote("gasp")
							if(tplus > tloss)
								H.setBrainLoss( max(0, min(99, ((tlimit - tplus) / tlimit * 100))))
							add_logs(user, M, "revived", defib)
						if(req_defib)
							defib.deductcharge(revivecost)
							cooldown = 1
						update_icon()
						if(req_defib)
							defib.cooldowncheck(user)
						else
							recharge(60)
					else if(H.heart_attack)
						H.heart_attack = 0
						user.visible_message("<span class='notice'>[req_defib ? "[defib]" : "[src]"] pings: Patient's heart is now beating again.</span>")
						playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 50, 1, -1)
					else
						user.visible_message("<span class='warning'>[req_defib ? "[defib]" : "[src]"] buzzes: Patient is not in a valid state. Operation aborted.</span>")
						playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
			busy = 0
			update_icon()
		else
			user << "<span class='warning'>You need to target your patient's chest with [src]!</span>"
			return

/obj/item/weapon/twohanded/shockpaddles/syndicate
	name = "syndicate defibrillator paddles"
	desc = "A pair of paddles used to revive deceased operatives. It possesses both the ability to penetrate armor and todeliver powerful shocks offensively."
	combat = 1
	icon = 'icons/obj/weapons.dmi'
	icon_state = "defibpaddles0"
	item_state = "defibpaddles0"
	req_defib = 0
