/obj/item/weapon/sharpener
	name = "sharpening block"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "sharpener"
	desc = "A block that makes things sharp."
	var/used = 0
	var/increment = 4
	var/max = 30
	var/prefix = "sharpened"
	var/requires_sharpness = 1


/obj/item/weapon/sharpener/attackby(obj/item/I, mob/user, params)
	if(used)
		user << "<span class='notice'>The sharpening block is too worn to use again.</span>"
		return
	if(I.force >= max || I.throwforce >= max)//no esword sharpening
		user << "<span class='notice'>[I] is much too powerful to sharpen further.</span>"
		return
	if(requires_sharpness && I.sharpness != IS_SHARP)
		user << "<span class='notice'>You can only sharpen items that are already sharp, such as knives.</span>"
		return
	if(istype(I, /obj/item/weapon/twohanded))//some twohanded items should still be sharpenable, but handle force differently. therefore i need this stuff
		var/obj/item/weapon/twohanded/TH = I
		if(TH.force_wielded >= max)
			user << "<span class='notice'>[TH] is much too powerful to sharpen further.</span>"
			return
		if(TH.wielded)
			user << "<span class='notice'>[TH] must be unwielded before it can be sharpened.</span>"
			return
		if(TH.force_wielded > initial(TH.force_wielded))
			user << "<span class='notice'>[TH] has already been refined before. It cannot be sharpened further.</span>"
			return
		TH.force_wielded = Clamp(TH.force_wielded + increment, 0, max)//wieldforce is increased since normal force wont stay
	if(I.force > initial(I.force))
		user << "<span class='notice'>[I] has already been refined before. It cannot be sharpened further.</span>"
		return
	user.visible_message("<span class='notice'>[user] sharpens [I] with [src]!</span>", "<span class='notice'>You sharpen [I], making it much more deadly than before.</span>")
	I.sharpness = IS_SHARP//this is only kept here because of super sharpening blocks, it wont do anything with standard since objects should already be sharp
	I.force = Clamp(I.force + increment, 0, max)
	I.throwforce = Clamp(I.throwforce + increment, 0, max)
	I.name = "[prefix] [I.name]"
	name = "worn out [name]"
	desc = "[desc] At least, it used to."
	used = 1

/obj/item/weapon/sharpener/super
	name = "super sharpening block"
	desc = "A block that will make your weapon sharper than Einstein on adderall."
	increment = 200
	max = 200
	prefix = "super-sharpened"
	requires_sharpness = 0