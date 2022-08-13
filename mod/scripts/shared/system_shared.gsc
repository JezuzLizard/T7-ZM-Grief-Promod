#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;

#insert scripts\shared\shared.gsh;

#namespace system;

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////

Usage:

REGISTER_SYSTEM( <system_name>, <preload_function>, <postload_function>, <pre-reqs> )
	
	system_name:		Name of the system.  To avoid confusion, this typically should match the namespace
						that the system is in.
	
	preload_function:	This function will automatically run during the pre initializion of a level load - this 
						will be during the first frame, during the level load phase (before _load::main)
						for all code executes during the first frame is:  autoexecs, level load, gametype, finalization
	
	postload_function:	This function will automatically run during the post initializion of a level load - this 
						will be during the first frame, during the finalization phase
						for all code executes during the first frame is:  autoexecs, level load, gametype, finalization

	pre-reqs:			Specifies a system or an array of systems that this system requires.  This system will
						wait until the precahce and main functions return from the required systems before
						running this system's main function.  Typically, this can be 'undefined'
	
Example:

	namespace coolsystem;
	
	REGISTER_SYSTEM( "coolsystem", &__init__, undefined )
		
	function __init__()
	{
		// Runs durring first frame, before any waits.  
	}
	
	

///////////////////////////////////////////////////////////////////////////////////////////////////////////*/

function register( str_system, func_preinit, func_postinit, reqs = [] )
{
	if ( IsDefined( level.system_funcs) && IsDefined( level.system_funcs[str_system] ) )
	{
		AssertMsg( "system '" + str_system + "' is already defined once. Please use a different name for your system." );
		return;
	}
	switch ( str_system )
	{
		case "bgb":
		case "bgb_machine":
		case "bgb_token":
		case "zm_bgb_aftertaste":
		case "zm_bgb_aftertaste":
		case "zm_bgb_alchemical_antithesis":
		case "zm_bgb_alchemical_antithesis":
		case "zm_bgb_always_done_swiftly":
		case "zm_bgb_always_done_swiftly":
		case "zm_bgb_anywhere_but_here":
		case "zm_bgb_armamental_accomplishment":
		case "zm_bgb_arms_grace":
		case "zm_bgb_arsenal_accelerator":
		case "zm_bgb_board_games":
		case "zm_bgb_board_to_death":
		case "zm_bgb_bullet_boost":
		case "zm_bgb_burned_out":
		case "zm_bgb_cache_back":
		case "zm_bgb_coagulant":
		case "zm_bgb_crate_power":
		case "zm_bgb_crawl_space":
		case "zm_bgb_danger_closest":
		case "zm_bgb_dead_of_nuclear_winter":
		case "zm_bgb_disorderly_combat":
		case "zm_bgb_ephemeral_enhancement":
		case "zm_bgb_extra_credit":
		case "zm_bgb_eye_candy":
		case "zm_bgb_fatal_contraption":
		case "zm_bgb_fear_in_headlights":
		case "zm_bgb_firing_on_all_cylinders":
		case "zm_bgb_flavor_hexed":
		case "zm_bgb_head_drama":
		case "zm_bgb_idle_eyes":
		case "zm_bgb_im_feelin_lucky":
		case "zm_bgb_immolation_liquidation":
		case "zm_bgb_impatient":
		case "zm_bgb_in_plain_sight":
		case "zm_bgb_kill_joy":
		case "zm_bgb_killing_time":
		case "zm_bgb_licensed_contractor":
		case "zm_bgb_lucky_crit":
		case "zm_bgb_mind_blown":
		case "zm_bgb_near_death_experience":
		case "zm_bgb_newtonian_negation":
		case "zm_bgb_now_you_see_me":
		case "zm_bgb_on_the_house":
		case "zm_bgb_perkaholic":
		case "zm_bgb_phoenix_up":
		case "zm_bgb_pop_shocks":
		case "zm_bgb_power_vacuum":
		case "zm_bgb_profit_sharing":
		case "zm_bgb_projectile_vomiting":
		case "zm_bgb_reign_drops":
		case "zm_bgb_respin_cycle":
		case "zm_bgb_round_robbin":
		case "zm_bgb_secret_shopper":
		case "zm_bgb_self_medication":
		case "zm_bgb_shopping_free":
		case "zm_bgb_slaughter_slide":
		case "zm_bgb_soda_fountain":
		case "zm_bgb_stock_option":
		case "zm_bgb_sword_flay":
		case "zm_bgb_temporal_gift":
		case "zm_bgb_tone_death":
		case "zm_bgb_unbearable":
		case "zm_bgb_undead_man_walking":
		case "zm_bgb_unquenchable":
		case "zm_bgb_wall_power":
		case "zm_bgb_whos_keeping_score":
			return;
		default:
			break;
	}
	//append to the func_init array, we'll sort based on reqs before we run everything
	DEFAULT( level.system_funcs, [] );
	
	level.system_funcs[str_system] = SpawnStruct();
	level.system_funcs[str_system].prefunc = func_preinit;
	level.system_funcs[str_system].postfunc = func_postinit;
	level.system_funcs[str_system].reqs = reqs;
	level.system_funcs[str_system].predone = !IsDefined(func_preinit);
	level.system_funcs[str_system].postdone = !IsDefined(func_postinit);
	level.system_funcs[str_system].ignore = false;
}

function exec_post_system(req)
{
	/#
	if (!IsDefined(level.system_funcs[req]))
	{
		AssertMsg( "system '" + req + "' is not defined." );
	}
	#/
	if (level.system_funcs[req].ignore)
	{
		return ;
	}
	if (!level.system_funcs[req].postdone)
	{
		[[level.system_funcs[req].postfunc]]();
		level.system_funcs[req].postdone=true;
	}
}

function run_post_systems()
{
	//sort the func_init list based on reqs
	foreach(key,func in level.system_funcs)
	{
		assert(func.predone || func.ignore,"failed to complete pre-initialization before post-initializtion call.  Avoid waits in pre-initialization");
		if (IsArray(func.reqs))
		{
			foreach(req in func.reqs)
			{
				thread exec_post_system(req);
			}
		}
		else
		{
			thread exec_post_system(func.reqs);
		}

		thread exec_post_system(key);
	}
	if (!level flag::exists("system_init_complete"))
	{
		level flag::init("system_init_complete",false);
	}
	level flag::set("system_init_complete");
}

function exec_pre_system(req)
{
	/#
	if (!IsDefined(level.system_funcs[req]))
	{
		AssertMsg( "system '" + req + "' is not defined." );
	}
	#/
	if (level.system_funcs[req].ignore)
	{
		return ;
	}
	if (!level.system_funcs[req].predone)
	{
		[[level.system_funcs[req].prefunc]]();
		level.system_funcs[req].predone=true;
	}
}

function run_pre_systems()
{
	//sort the func_init list based on reqs
	foreach(key,func in level.system_funcs)
	{
		if (IsArray(func.reqs))
		{
			foreach(req in func.reqs)
			{
				thread exec_pre_system(req);
			}
		}
		else
		{
			thread exec_pre_system(func.reqs);
		}

		thread exec_pre_system(key);
	}
}

function wait_till( required_systems )
{
	if (!level flag::exists("system_init_complete"))
	{
		level flag::init("system_init_complete",false);
	}
	level flag::wait_till("system_init_complete");
}

/@
"Name: ignore( str_system )"
"Summary: Call in the gametype main function to turn off systems even if they are included in _load or anywhere else."
"MandatoryArg: <str_system> name of the system to turn off (defined in REGISTER_SYSTEM call)."
"Example: level system::ignore( "scene" );"
@/
function ignore( str_system )
{
	Assert( !isdefined( level.gametype ), "Ignored systems must be set before level.gametype is set." );

	if ( !isdefined( level.system_funcs) || !isdefined( level.system_funcs[str_system] ) )
	{
		register(str_system,undefined,undefined,undefined); //make sure it exists so it'll get ignored if it tries to add itself after this
	}
		
	level.system_funcs[str_system].ignore = true;
}

function is_system_running( str_system )
{
	if ( !isdefined( level.system_funcs) || !isdefined( level.system_funcs[str_system] ) )
		return false;
	
	return level.system_funcs[str_system].postdone;
}