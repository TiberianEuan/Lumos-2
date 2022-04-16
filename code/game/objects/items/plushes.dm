/obj/item/toy/plush
	name = "plush"
	desc = "This is the special coder plush, do not steal."
	icon = 'icons/obj/plushes.dmi'
	icon_state = "debug"
	attack_verb = list("thumped", "whomped", "bumped")
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE
	var/list/squeak_override //Weighted list; If you want your plush to have different squeak sounds use this
	var/stuffed = TRUE //If the plushie has stuffing in it
	var/unstuffable = FALSE //for plushies that can't be stuffed
	var/obj/item/grenade/grenade //You can remove the stuffing from a plushie and add a grenade to it for *nefarious uses*
	gender = NEUTER

	var/snowflake_id					//if we set from a config snowflake plushie.
	/// wrapper, do not use, read only
	var/__ADMIN_SET_TO_ID
	var/can_random_spawn = TRUE			//if this is FALSE, don't spawn this for random plushies.

/obj/item/toy/plush/random_snowflake/Initialize(mapload, set_snowflake_id)
	. = ..()
	var/list/configlist = CONFIG_GET(keyed_list/snowflake_plushies)
	var/id = safepick(configlist)
	if(!id)
		return
	set_snowflake_from_config(id)

/obj/item/toy/plush/DoRevenantThrowEffects(atom/target)
	var/datum/component/squeak/squeaker = GetComponent(/datum/component/squeak)
	squeaker.do_play_squeak(TRUE)

/obj/item/toy/plush/Initialize(mapload, set_snowflake_id)
	. = ..()
	AddComponent(/datum/component/squeak, squeak_override)
	AddElement(/datum/element/bed_tuckable, 6, -5, 90)

	//have we decided if Pinocchio goes in the blue or pink aisle yet?
	if(gender == NEUTER)
		if(prob(50))
			gender = FEMALE
		else
			gender = MALE

	if(set_snowflake_id)
		set_snowflake_from_config(set_snowflake_id)


/obj/item/toy/plush/Destroy()
	QDEL_NULL(grenade)

/obj/item/toy/plush/vv_get_var(var_name)
	if(var_name == NAMEOF(src, __ADMIN_SET_TO_ID))
		return debug_variable("__ADMIN: SET SNOWFLAKE ID", snowflake_id, 0, src)
	return ..()

/obj/item/toy/plush/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, __ADMIN_SET_TO_ID))
		return set_snowflake_from_config(var_value)
	return ..()

/obj/item/toy/plush/proc/set_snowflake_from_config(id)
	var/list/configlist = CONFIG_GET(keyed_list/snowflake_plushies)
	var/list/jsonlist = configlist[id]
	if(!jsonlist)
		return FALSE
	jsonlist = json_decode(jsonlist)
	if(jsonlist["inherit_from"])
		var/path = text2path(jsonlist["inherit_from"])
		if(!ispath(path, /obj/item/toy/plush))
			stack_trace("Invalid path for inheritance")
		else
			var/obj/item/toy/plush/P = new path		//can't initial() lists
			name = P.name
			desc = P.desc
			icon_state = P.icon_state
			item_state = P.item_state
			icon = P.icon
			squeak_override = P.squeak_override
			attack_verb = P.attack_verb
			gender = P.gender
			qdel(P)
	if(jsonlist["name"])
		name = jsonlist["name"]
	if(jsonlist["desc"])
		desc = jsonlist["desc"]
	if(jsonlist["gender"])
		gender = jsonlist["gender"]
	if(jsonlist["icon_state"])
		icon_state = jsonlist["icon_state"]
		item_state = jsonlist["item_state"]
		var/static/config_sprites = file("config/plushies/sprites.dmi")
		icon = config_sprites
	if(jsonlist["attack_verb"])
		attack_verb = jsonlist["attack_verb"]
	if(jsonlist["squeak_override"])
		squeak_override = jsonlist["squeak_override"]
	if(squeak_override)
		var/datum/component/squeak/S = GetComponent(/datum/component/squeak)
		S?.override_squeak_sounds = squeak_override
	snowflake_id = id
	return TRUE

/obj/item/toy/plush/handle_atom_del(atom/A)
	if(A == grenade)
		grenade = null
	..()

/obj/item/toy/plush/attack_self(mob/user)
	. = ..()
	if(stuffed || grenade)
		to_chat(user, "<span class='notice'>You pet [src]. D'awww.</span>")
		if(grenade && !grenade.active)
			if(istype(grenade, /obj/item/grenade/chem_grenade))
				var/obj/item/grenade/chem_grenade/G = grenade
				if(G.nadeassembly) //We're activated through different methods
					return
			log_game("[key_name(user)] activated a hidden grenade in [src].")
			grenade.preprime(user, msg = FALSE, volume = 10)
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT,"plushpet", /datum/mood_event/plushpet)
	else
		to_chat(user, "<span class='notice'>You try to pet [src], but it has no stuffing. Aww...</span>")
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT,"plush_nostuffing", /datum/mood_event/plush_nostuffing)

/obj/item/toy/plush/attackby(obj/item/I, mob/living/user, params)
	if(I.get_sharpness())
		if(!grenade)
			if(unstuffable)
				to_chat(user, "<span class='notice'>Nothing to do here.</span>")
				return
			if(!stuffed)
				to_chat(user, "<span class='warning'>You already murdered it!</span>")
				return
			user.visible_message("<span class='notice'>[user] tears out the stuffing from [src]!</span>", "<span class='notice'>You rip a bunch of the stuffing from [src]. Murderer.</span>")
			I.play_tool_sound(src)
			stuffed = FALSE
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT,"plushjack", /datum/mood_event/plushjack)
		else
			to_chat(user, "<span class='notice'>You remove the grenade from [src].</span>")
			user.put_in_hands(grenade)
			grenade = null
		return
	if(istype(I, /obj/item/grenade))
		if(unstuffable)
			to_chat(user, "<span class='warning'>No... you should destroy it now!</span>")
			sleep(10)
			if(QDELETED(user) || QDELETED(src))
				return
			SEND_SOUND(user, 'sound/weapons/armbomb.ogg')
			return
		if(stuffed)
			to_chat(user, "<span class='warning'>You need to remove some stuffing first!</span>")
			return
		if(grenade)
			to_chat(user, "<span class='warning'>[src] already has a grenade!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		user.visible_message("<span class='warning'>[user] slides [grenade] into [src].</span>", \
		"<span class='danger'>You slide [I] into [src].</span>")
		grenade = I
		var/turf/grenade_turf = get_turf(src)
		log_game("[key_name(user)] added a grenade ([I.name]) to [src] at [AREACOORD(grenade_turf)].")
		return
	return ..()

GLOBAL_LIST_INIT(valid_plushie_paths, valid_plushie_paths())
/proc/valid_plushie_paths()
	. = list()
	for(var/i in subtypesof(/obj/item/toy/plush))
		var/obj/item/toy/plush/abstract = i
		if(!initial(abstract.can_random_spawn))
			continue
		. += i

/obj/item/toy/plush/random
	name = "Illegal plushie"
	desc = "Something fucked up"
	can_random_spawn = FALSE

/obj/item/toy/plush/random/Initialize()
	..()
	var/newtype
	var/list/snowflake_list = CONFIG_GET(keyed_list/snowflake_plushies)

	/// If there are no snowflake plushies we'll default to base plush, so we grab from the valid list
	if (snowflake_list.len)
		newtype = prob(CONFIG_GET(number/snowflake_plushie_prob)) ? /obj/item/toy/plush/random_snowflake : pick(GLOB.valid_plushie_paths)
	else
		newtype = pick(GLOB.valid_plushie_paths)

	new newtype(loc)
	return INITIALIZE_HINT_QDEL

/obj/item/toy/plush/carpplushie
	name = "space carp plushie"
	desc = "An adorable stuffed toy that resembles a space carp."
	icon_state = "carpplush"
	item_state = "carp_plushie"
	attack_verb = list("bitten", "eaten", "fin slapped")
	squeak_override = list('sound/weapons/bite.ogg'=1)

/obj/item/toy/plush/bubbleplush
	name = "bubblegum plushie"
	desc = "The friendly red demon that gives good miners gifts."
	icon_state = "bubbleplush"
	attack_verb = list("rends")
	squeak_override = list('sound/magic/demon_attack1.ogg'=1)

/obj/item/toy/plush/plushvar
	name = "ratvar plushie"
	desc = "An adorable plushie of the clockwork justiciar himself with new and improved spring arm action."
	icon_state = "plushvar"
	var/obj/item/toy/plush/narplush/clash_target
	gender = MALE	//he's a boy, right?

/obj/item/toy/plush/plushvar/Moved()
	. = ..()
	if(clash_target)
		return
	var/obj/item/toy/plush/narplush/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clashing)
		clash_of_the_plushies(P)

/obj/item/toy/plush/plushvar/proc/clash_of_the_plushies(obj/item/toy/plush/narplush/P)
	clash_target = P
	P.clashing = TRUE
	say("YOU.")
	P.say("Ratvar?!")
	var/obj/item/toy/plush/a_winnar_is
	var/victory_chance = 10
	for(var/i in 1 to 10) //We only fight ten times max
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(!Adjacent(P))
			visible_message("<span class='warning'>The two plushies angrily flail at each other before giving up.</span>")
			clash_target = null
			P.clashing = FALSE
			return
		playsound(src, 'sound/magic/clockwork/ratvar_attack.ogg', 50, TRUE, frequency = 2)
		sleep(2.4)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = src
			break
		P.SpinAnimation(5, 0)
		sleep(5)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		playsound(P, 'sound/magic/clockwork/narsie_attack.ogg', 50, TRUE, frequency = 2)
		sleep(3.3)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = P
			break
		SpinAnimation(5, 0)
		victory_chance += 10
		sleep(5)
	if(!a_winnar_is)
		a_winnar_is = pick(src, P)
	if(a_winnar_is == src)
		say(pick("DIE.", "ROT."))
		P.say(pick("Nooooo...", "Not die. To y-", "Die. Ratv-", "Sas tyen re-"))
		playsound(src, 'sound/magic/clockwork/anima_fragment_attack.ogg', 50, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_dies.ogg', 50, TRUE, frequency = 2)
		explosion(P, 0, 0, 1)
		qdel(P)
		clash_target = null
	else
		say("NO! I will not be banished again...")
		P.say(pick("Ha.", "Ra'sha fonn dest.", "You fool. To come here."))
		playsound(src, 'sound/magic/clockwork/anima_fragment_death.ogg', 62, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_attack1.ogg', 50, TRUE, frequency = 2)
		explosion(src, 0, 0, 1)
		qdel(src)
		P.clashing = FALSE

/obj/item/toy/plush/narplush
	name = "\improper Nar'Sie plushie"
	desc = "A small stuffed doll of the elder goddess Nar'Sie. Who thought this was a good children's toy?"
	icon_state = "narplush"
	var/clashing
	var/is_invoker = TRUE
	gender = FEMALE	//it's canon if the toy is

/obj/item/toy/plush/narplush/Moved()
	. = ..()
	var/obj/item/toy/plush/plushvar/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clash_target && !clashing)
		P.clash_of_the_plushies(src)

/obj/item/toy/plush/narplush/hugbox
	desc = "A small stuffed doll of the elder goddess Nar'Sie. Who thought this was a good children's toy? <b>It looks sad.</b>"
	is_invoker = FALSE

/obj/item/toy/plush/lizardplushie
	name = "lizard plushie"
	desc = "An adorable stuffed toy that resembles a lizardperson."
	icon_state = "plushie_lizard"
	item_state = "plushie_lizard"
	attack_verb = list("clawed", "hissed", "tail slapped")
	squeak_override = list('sound/weapons/slash.ogg' = 1)

/obj/item/toy/plush/lizardplushie/kobold
	name = "kobold plushie"
	desc = "An adorable stuffed toy that resembles a kobold."
	icon_state = "kobold"
	item_state = "kobold"

/obj/item/toy/plush/lizardplushie/kobold
	name = "spacelizard plushie"
	desc = "An adorable stuffed toy that resembles a lizard in a suit."
	icon_state = "plushie_spacelizard"
	item_state = "plushie_spacelizard"

/obj/item/toy/plush/nukeplushie
	name = "operative plushie"
	desc = "A stuffed toy that resembles a syndicate nuclear operative. The tag claims operatives to be purely fictitious."
	icon_state = "plushie_nuke"
	item_state = "plushie_nuke"
	attack_verb = list("shot", "nuked", "detonated")
	squeak_override = list('sound/effects/hit_punch.ogg' = 1)

/obj/item/toy/plush/slimeplushie
	name = "slime plushie"
	desc = "An adorable stuffed toy that resembles a slime. It is practically just a hacky sack."
	icon_state = "plushie_slime"
	item_state = "plushie_slime"
	attack_verb = list("blorbled", "slimed", "absorbed", "glomped")
	squeak_override = list('sound/effects/blobattack.ogg' = 1)
	gender = FEMALE	//given all the jokes and drawings, I'm not sure the xenobiologists would make a slimeboy

/obj/item/toy/plush/awakenedplushie
	name = "awakened plushie"
	desc = "An ancient plushie that has grown enlightened to the true nature of reality."
	icon_state = "plushie_awake"
	item_state = "plushie_awake"
	can_random_spawn = FALSE

/obj/item/toy/plush/awakenedplushie/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/edit_complainer)

/obj/item/toy/plush/beeplushie
	name = "bee plushie"
	desc = "A cute toy that resembles an even cuter bee."
	icon_state = "plushie_bee"
	item_state = "plushie_bee"
	attack_verb = list("stung")
	gender = FEMALE
	squeak_override = list('modular_citadel/sound/voice/scream_moth.ogg' = 1)

/obj/item/toy/plush/mothplushie
	name = "moth plushie"
	desc = "An adorable stuffed toy that resembles some kind of insect."
	icon_state = "moff"
	item_state = "moff"
	squeak_override = list('modular_citadel/sound/voice/mothsqueak.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/lampplushie
	name = "lamp plushie"
	desc = "A toy lamp plushie, doesn't actually make light, but it still toggles on and off. Click clack!"
	icon_state = "plushie_lamp"
	item_state = "plushie_lamp"
	attack_verb = list("lit", "flickered", "flashed")
	squeak_override = list('sound/weapons/magout.ogg' = 1)

/obj/item/toy/plush/drake
	name = "drake plushie"
	desc = "A large beast from lavaland turned into a marketable plushie!"
	icon_state = "drake"
	item_state = "drake"
	attack_verb = list("bit", "devoured", "burned")

/obj/item/toy/plush/deer
	name = "deer plushie"
	desc = "Oh deer, a plushie!"
	icon_state = "deer"
	item_state = "deer"
	attack_verb = list("bleated", "rammed", "kicked")

/obj/item/toy/plush/box
	name = "cardboard plushie"
	desc = "A toy box plushie, it holds cotten. Only a baddie would place a bomb through the postal system..."
	icon_state = "box"
	item_state = "box"
	attack_verb = list("open", "closed", "packed", "hidden", "rigged", "bombed", "sent", "gave")

/obj/item/toy/plush/slaggy
	name = "slag plushie"
	desc = "A piece of slag with some googly eyes and a drawn on mouth."
	icon_state = "slaggy"
	item_state = "slaggy"
	attack_verb = list("melted", "refined", "stared")

/obj/item/toy/plush/mr_buckety
	name = "bucket plushie"
	desc = "A bucket that is missing its handle with some googly eyes and a drawn on mouth."
	icon_state = "mr_buckety"
	item_state = "mr_buckety"
	attack_verb = list("filled", "dumped", "stared")

/obj/item/toy/plush/dr_scanny
	name = "scanner plushie"
	desc = "A old outdated scanner that has been modified to have googly eyes, a dawn on mouth and, heart."
	icon_state = "dr_scanny"
	item_state = "dr_scanny"
	attack_verb = list("scanned", "beeped", "stared")

/obj/item/toy/plush/borgplushie
	name = "K9 plushie"
	desc = "An adorable stuffed toy of a robot."
	icon_state = "securityk9"
	item_state = "securityk9"
	attack_verb = list("beeped", "booped", "pinged")
	squeak_override = list('sound/machines/beep.ogg' = 1)

/obj/item/toy/plush/borgplushie/medihound
	name = "medihound plushie"
	icon_state = "medihound"
	item_state = "medihound"

/obj/item/toy/plush/borgplushie/scrubpuppy
	name = "scrubpuppy plushie"
	icon_state = "scrubpuppy"
	item_state = "scrubpuppy"

/obj/item/toy/plush/borgplushie/pupdozer
	name = "pupdozer plushie"
	icon_state = "pupdozer"
	item_state = "pupdozer"

/obj/item/toy/plush/aiplush
	name = "AI plushie"
	desc = "A little stuffed toy AI core... it appears to be malfunctioning."
	icon_state = "malfai"
	item_state = "malfai"
	attack_verb = list("hacked", "detonated", "overloaded")
	squeak_override = list('sound/machines/beep.ogg' = 9, 'sound/machines/buzz-two.ogg' = 1)

/obj/item/toy/plush/snakeplushie
	name = "snake plushie"
	desc = "An adorable stuffed toy that resembles a snake. Not to be mistaken for the real thing."
	icon_state = "plushie_snake"
	item_state = "plushie_snake"
	attack_verb = list("bitten", "hissed", "tail slapped")
	squeak_override = list('modular_citadel/sound/voice/hiss.ogg' = 1)

/obj/item/toy/plush/mammal
	name = "mammal plushie"
	desc = "An adorable stuffed toy resembling some sort of crew member."
	icon_state = "ych"
	item_state = "ych"
	can_random_spawn = FALSE

/obj/item/toy/plush/mammal/fox
	name = "fox plushie"
	desc = "An adorable stuffed toy resembling a fox."
	icon_state = "fox"
	item_state = "fox"
	attack_verb = list("yipped", "geckered", "yapped")

/obj/item/toy/plush/mammal/dog
	name = "dog plushie"
	icon_state = "corgi"
	item_state = "corgi"
	desc = "An adorable stuffed toy that resembles a dog."
	attack_verb = list("barked", "boofed", "borked")
	squeak_override = list(
	'modular_citadel/sound/voice/bark1.ogg' = 1,
	'modular_citadel/sound/voice/bark2.ogg' = 1
	)

/obj/item/toy/plush/mammal/dog/fcorgi
	name = "corgi plushie"
	icon_state = "girlycorgi"
	item_state = "girlycorgi"
	desc = "An adorable stuffed toy that resembles a dog. This one dons a pink ribbon."

/obj/item/toy/plush/mammal/dog/borgi
	name = "borgi plushie"
	icon_state = "borgi"
	item_state = "borgi"
	desc = "An adorable stuffed toy that resembles a robot dog."

/obj/item/toy/plush/xeno
	name = "xenohybrid plushie"
	desc = "An adorable stuffed toy that resembles a xenomorphic crewmember."
	icon_state = "xeno"
	item_state = "xeno"
	squeak_override = list('sound/voice/hiss2.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/bird
	name = "bird plushie"
	desc = "An adorable stuffed plushie that resembles an avian."
	icon_state = "bird"
	item_state = "bird"
	attack_verb = list("peeped", "beeped", "poofed")
	squeak_override = list('modular_citadel/sound/voice/peep.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/sergal
	name = "sergal plushie"
	desc = "An adorable stuffed plushie that resembles a sagaru."
	icon_state = "sergal"
	item_state = "sergal"
	squeak_override = list('modular_citadel/sound/voice/merp.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/catgirl
	name = "feline plushie"
	desc = "An adorable stuffed toy that resembles a feline."
	icon_state = "cat"
	item_state = "cat"
	attack_verb = list("headbutt", "scritched", "bit")
	squeak_override = list('modular_citadel/sound/voice/nya.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/catgirl/fermis
	name = "medcat plushie"
	desc = "An affectionate stuffed toy that resembles a certain medcat, comes complete with battery operated wagging tail!! You get the impression she's cheering you on to to find happiness and be kind to people."
	icon_state = "fermis"
	item_state = "fermis"
	attack_verb = list("cuddled", "petpatted", "wigglepurred")
	squeak_override = list('modular_citadel/sound/voice/merowr.ogg' = 1)

/obj/item/toy/plush/teddybear
	name = "teddy"
	desc = "It's a teddy bear!"
	icon_state = "teddy"
	item_state = "teddy"

/obj/item/toy/plush/crab
	name = "crab plushie"
	desc = "Fewer pinches than a real one, but it still clicks."
	icon_state = "crab"
	item_state = "crab"
	attack_verb = list("clicked", "clacked", "pinched")

/obj/item/toy/plush/gondola
	name = "gondola plushie"
	desc = "Just looking at it seems to calm you down. Please do not eat it though."
	icon_state = "gondola"
	item_state = "gondola"
	attack_verb = list("calmed", "smiled", "peaced")

/obj/item/toy/plush/hairball
	name = "Hairball"
	desc = "A bundle of undigested fibers and scales. Yuck."
	icon_state = "Hairball"
	unstuffable = TRUE
	squeak_override = list('sound/misc/splort.ogg'=1)
	attack_verb = list("sploshed", "splorted", "slushed")
	can_random_spawn = FALSE

