/obj/item/clothing/under/rank/brigdoc
	name = "brig physician outfit"
	desc = "The uniform of the Brig Physician. Do no harm."
	icon = 'modular_lumos/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_lumos/icons/mob/clothing/uniform.dmi'
	icon_state = "brigphys"
	item_state = "brigphys"
	armor = list("melee" = 10, "bullet" = 0, "laser" = 0,"energy" = 0, "bomb" = 0, "bio" = 10, "rad" = 0, "fire" = 20, "acid" = 30, "wound" = 10)
	can_adjust = FALSE
	strip_delay = 50
	alt_covers_chest = TRUE
	sensor_mode = SENSOR_COORDS
	sensor_flags = NONE
	anthro_mob_worn_overlay = 'modular_lumos/icons/mob/clothing/uniform_digi.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC

/obj/item/clothing/under/rank/brigdoc/skirt
	name = "brig physician skirt"
	desc = "The uniform of the Brig Physician. Do no harm, with a skirt"
	icon_state = "brigphysf"
	item_state = "brigphysf"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/rank/blueshield
	name = "blueshield outfit"
	desc = "The uniform of a Blueshield. It makes you feel protected"
	icon = 'modular_lumos/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_lumos/icons/mob/clothing/uniform.dmi'
	icon_state = "blueshield"
	item_state = "blueshield"
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5,"energy" = 5, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 20, "acid" = 30, "wound" = 10)
	can_adjust = FALSE
	strip_delay = 50
	alt_covers_chest = TRUE
	sensor_mode = SENSOR_COORDS
	sensor_flags = NONE
	anthro_mob_worn_overlay = 'modular_lumos/icons/mob/clothing/uniform_digi.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC


/obj/item/clothing/under/rank/blueshield/skirt
	name = "blueshield skirt"
	desc = "The uniform of the Blueshield. It makes you feel protected, even with a bit of a breeze."
	icon_state = "blueshieldf"
	item_state = "blueshieldf"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
