///Wing base type. doesn't really do anything
/obj/item/organ/wings
	name = "wings"
	///Unremovable is until the features are completely finished
	organ_flags = ORGAN_UNREMOVABLE | ORGAN_EDIBLE
	visual = TRUE
	cosmetic_only = TRUE

	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_EXTERNAL_WINGS

	feature_key = "wings"

/obj/item/organ/wings/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(!human.wear_suit)
		return TRUE
	if(!(human.wear_suit.flags_inv & HIDEJUMPSUIT))
		return TRUE
	if(human.wear_suit.species_exception && is_type_in_list(src, human.wear_suit.species_exception))
		return TRUE
	return FALSE

///Checks if the wings can soften short falls
/obj/item/organ/wings/proc/can_soften_fall()
	return TRUE

///The true wings that you can use to fly and shit (you cant actually shit with them)
/obj/item/organ/wings/functional
	///The flight action object
	var/datum/action/innate/flight/fly

	///The preference type for opened wings
	var/wings_open_feature_key = "wingsopen"
	///The preference type for closed wings
	var/wings_closed_feature_key = "wings"

	///Are our wings open or closed?
	var/wings_open = FALSE

/obj/item/organ/wings/functional/get_global_feature_list()
	if(wings_open)
		return GLOB.wings_open_list
	else
		return GLOB.wings_list

/obj/item/organ/wings/functional/Insert(mob/living/carbon/reciever, special, drop_if_replaced)
	. = ..()
	if(!.)
		return

	if(isnull(fly))
		fly = new
		fly.Grant(reciever)

/obj/item/organ/wings/functional/Remove(mob/living/carbon/organ_owner, special, moving)
	. = ..()

	fly.Remove(organ_owner)

/obj/item/organ/wings/functional/on_life(delta_time, times_fired)
	. = ..()

	handle_flight(owner)

///Called on_life(). Handle flight code and check if we're still flying
/obj/item/organ/wings/functional/proc/handle_flight(mob/living/carbon/human/human)
	if(human.movement_type & ~FLYING)
		return FALSE
	if(!can_fly(human))
		toggle_flight(human)
		return FALSE
	return TRUE


///Check if we're still eligible for flight (wings covered, atmosphere too thin, etc)
/obj/item/organ/wings/functional/proc/can_fly(mob/living/carbon/human/human)
	if(human.stat || human.body_position == LYING_DOWN)
		return FALSE
	//Jumpsuits have tail holes, so it makes sense they have wing holes too
	if(human.wear_suit && ((human.wear_suit.flags_inv & HIDEJUMPSUIT) && (!human.wear_suit.species_exception || !is_type_in_list(src, human.wear_suit.species_exception))))
		to_chat(human, span_warning("Your suit blocks your wings from extending!"))
		return FALSE
	var/turf/location = get_turf(human)
	if(!location)
		return FALSE

	var/datum/gas_mixture/environment = location.return_air()
	if(environment?.returnPressure() < HAZARD_LOW_PRESSURE + 10)
		to_chat(human, span_warning("The atmosphere is too thin for you to fly!"))
		return FALSE
	else
		return TRUE

///Slipping but in the air?
/obj/item/organ/wings/functional/proc/fly_slip(mob/living/carbon/human/human)
	var/obj/buckled_obj
	if(human.buckled)
		buckled_obj = human.buckled

	to_chat(human, span_notice("Your wings spazz out and launch you!"))

	playsound(human.loc, 'sound/misc/slip.ogg', 50, TRUE, -3)

	for(var/obj/item/choking_hazard in human.held_items)
		human.accident(choking_hazard)

	var/olddir = human.dir

	human.stop_pulling()
	if(buckled_obj)
		buckled_obj.unbuckle_mob(human)
		step(buckled_obj, olddir)
	else
		human.AddComponent(/datum/component/force_move, get_ranged_target_turf(human, olddir, 4), TRUE)
	return TRUE

///UNSAFE PROC, should only be called through the Activate or other sources that check for CanFly
/obj/item/organ/wings/functional/proc/toggle_flight(mob/living/carbon/human/human)
	if(!HAS_TRAIT_FROM(human, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT))
		human.physiology.stun_mod *= 2
		ADD_TRAIT(human, TRAIT_NO_FLOATING_ANIM, SPECIES_FLIGHT_TRAIT)
		ADD_TRAIT(human, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
		passtable_on(human, SPECIES_TRAIT)
		open_wings()
	else
		human.physiology.stun_mod *= 0.5
		REMOVE_TRAIT(human, TRAIT_NO_FLOATING_ANIM, SPECIES_FLIGHT_TRAIT)
		REMOVE_TRAIT(human, TRAIT_MOVE_FLYING, SPECIES_FLIGHT_TRAIT)
		passtable_off(human, SPECIES_TRAIT)
		close_wings()

///SPREAD OUR WINGS AND FLLLLLYYYYYY
/obj/item/organ/wings/functional/proc/open_wings()
	feature_key = wings_open_feature_key
	wings_open = TRUE

	owner.update_body_parts()

///close our wings
/obj/item/organ/wings/functional/proc/close_wings()
	feature_key = wings_closed_feature_key
	wings_open = FALSE

	owner.update_body_parts()
	if(isturf(owner?.loc))
		var/turf/location = loc
		location.Entered(src, NONE)

///hud action for starting and stopping flight
/datum/action/innate/flight
	name = "Toggle Flight"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "flight"

/datum/action/innate/flight/Activate()
	var/mob/living/carbon/human/human = owner
	var/obj/item/organ/wings/functional/wings = human.getorganslot(ORGAN_SLOT_EXTERNAL_WINGS)
	if(wings && wings.can_fly(human))
		wings.toggle_flight(human)
		if(!(human.movement_type & FLYING))
			to_chat(human, span_notice("You settle gently back onto the ground..."))
		else
			to_chat(human, span_notice("You beat your wings and begin to hover gently above the ground..."))
			human.set_resting(FALSE, TRUE)

///Moth wings! They can flutter in low-grav and burn off in heat
/obj/item/organ/wings/moth
	feature_key = "moth_wings"
	preference = "feature_moth_wings"
	layers = list(BODY_FRONT_LAYER, BODY_BEHIND_LAYER)

	dna_block = DNA_MOTH_WINGS_BLOCK

	///Are we burned?
	var/burnt = FALSE
	///Store our old sprite here for if our burned wings are healed
	var/original_sprite = ""

/obj/item/organ/wings/moth/get_global_feature_list()
	return GLOB.moth_wings_list

/obj/item/organ/wings/moth/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(!(human.wear_suit?.flags_inv & HIDEMUTWINGS))
		return TRUE
	return FALSE

/obj/item/organ/wings/moth/Insert(mob/living/carbon/reciever, special, drop_if_replaced)
	. = ..()
	if(!.)
		return

	RegisterSignal(reciever, COMSIG_HUMAN_BURNING, PROC_REF(try_burn_wings))
	RegisterSignal(reciever, COMSIG_LIVING_POST_FULLY_HEAL, PROC_REF(heal_wings))
	RegisterSignal(reciever, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(update_float_move))

/obj/item/organ/wings/moth/Remove(mob/living/carbon/organ_owner, special, moving)
	. = ..()

	UnregisterSignal(organ_owner, list(COMSIG_HUMAN_BURNING, COMSIG_LIVING_POST_FULLY_HEAL, COMSIG_MOVABLE_PRE_MOVE))
	REMOVE_TRAIT(organ_owner, TRAIT_FREE_FLOAT_MOVEMENT, src)

/obj/item/organ/wings/moth/can_soften_fall()
	return !burnt

///Check if we can flutter around
/obj/item/organ/wings/moth/proc/update_float_move()
	SIGNAL_HANDLER

	if(!isspaceturf(owner.loc) && !burnt)
		var/datum/gas_mixture/current = owner.loc.return_air()
		if(current && (current.returnPressure() >= ONE_ATMOSPHERE*0.85)) //as long as there's reasonable pressure and no gravity, flight is possible
			ADD_TRAIT(owner, TRAIT_FREE_FLOAT_MOVEMENT, src)
			return

	REMOVE_TRAIT(owner, TRAIT_FREE_FLOAT_MOVEMENT, src)

///check if our wings can burn off ;_;
/obj/item/organ/wings/moth/proc/try_burn_wings(mob/living/carbon/human/human)
	SIGNAL_HANDLER

	if(!burnt && human.bodytemperature >= 800 && human.fire_stacks > 0) //do not go into the extremely hot light. you will not survive
		to_chat(human, span_danger("Your precious wings burn to a crisp!"))

		burn_wings()
		human.update_body_parts()

///burn the wings off
/obj/item/organ/wings/moth/proc/burn_wings()
	burnt = TRUE

	original_sprite = sprite_datum.name
	set_sprite("Burnt Off")

///heal our wings back up!!
/obj/item/organ/wings/moth/proc/heal_wings()
	SIGNAL_HANDLER

	if(burnt)
		burnt = FALSE
		set_sprite(original_sprite)
