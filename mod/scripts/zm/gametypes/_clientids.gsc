#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;

#using scripts\shared\laststand_shared;
#using scripts\zm\_zm_laststand;

#insert scripts\shared\shared.gsh;

#namespace clientids;

REGISTER_SYSTEM( "clientids", &__init__, undefined )
	
function __init__()
{
	callback::on_start_gametype( &init );
	callback::on_connect( &on_player_connect );
}	

function init()
{
	// this is now handled in code ( not lan )
	// see s_nextScriptClientId 
	level.clientid = 0;
	level.player_too_many_players_check = false;
	level._game_module_player_damage_callback = &game_module_player_damage_callback;
	level._game_module_player_damage_grief_callback = &game_module_player_damage_grief_callback;
	level.prevent_player_damage = &player_prevent_damage;
	level.no_end_game_check = true;
	level.round_number = 20;
	level.teamcount = 2;
	level.multiteam = level.teamcount > 2;
	if(sessionmodeiszombiesgame())
	{
		level.zombie_team_index = level.teamcount + 1;
		if(2 == level.zombie_team_index)
		{
			level.zombie_team = "axis";
		}
		else
		{
			level.zombie_team = "team" + level.zombie_team_index;
		}
	}
	level.teams = [];
	level.teamindex = [];
	teamcount = level.teamcount;
	level.teams["allies"] = "allies";
	level.teams["axis"] = "axis";
	level.teamindex["neutral"] = 0;
	level.teamindex["allies"] = 1;
	level.teamindex["axis"] = 2;
	for(teamindex = 3; teamindex <= teamcount; teamindex++)
	{
		level.teams["team" + teamindex] = "team" + teamindex;
		level.teamindex["team" + teamindex] = teamindex;
	}
	logprint( "Adding bots\n" );
	level thread add_bots();
}

function disable_intersection_tracker( player )
{
	return true;
}

function add_bots()
{
	wait 1;
	max_clients = getDvarInt( "com_maxclients" );
	level.player_intersection_tracker_override = &disable_intersection_tracker;
	for( i = 1; i < max_clients; i++ )
	{
		bot = addTestClient();
		bot [[ level.spawnPlayer ]]();
		wait 0.05;
	}
	wait 5;
	level.player_intersection_tracker_override = undefined;
	bgbs = getEntArray( "zbarrier_zmcore_bgb_machine", "classname" );
	for( index = 0; index < bgbs.size; index++ )
	{
		bgbs[index] Delete();
	}
}

function on_player_connect()
{
	self.clientid = matchRecordNewPlayer( self );
	if ( !isdefined( self.clientid ) || self.clientid == -1 )
	{
		self.clientid = level.clientid;
		level.clientid++;	// Is this safe? What if a server runs for a long time and many people join/leave
	}
	teamplayersallies = countplayers( "allies");
	teamplayersaxis = countplayers( "axis");
	if ( teamplayersallies > teamplayersaxis )
	{
		self.team = "axis";
		self.sessionteam = "axis";
		self.pers[ "team" ] = "axis";
		self._encounters_team = "A";
	}
	else if ( teamplayersallies < teamplayersaxis )
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
	else
	{
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
}
 

function game_module_player_damage_callback( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime ) //checked partially changed output to cerberus output
{
	self.last_damage_from_zombie_or_player = 0;
	if ( isDefined( eattacker ) )
	{
		if ( isplayer( eattacker ) && eattacker == self )
		{
			return;
		}
		if ( isDefined( eattacker.is_zombie ) || eattacker.is_zombie && isplayer( eattacker ) )
		{
			self.last_damage_from_zombie_or_player = 1;
		}
	}
	if ( isDefined( eattacker) && isplayer( eattacker ) )
	{
		if ( smeansofdeath == "MOD_MELEE" )
		{
			eattacker.pers[ "stabs" ]++;
			eattacker.stabs++;
		}
	}
	if ( isplayer( eattacker ) && isDefined( eattacker._encounters_team ) && eattacker._encounters_team != self._encounters_team )
	{
		//self player_steal_points( eattacker, smeansofdeath );
	}
	if ( isDefined( self._being_shellshocked ) && self._being_shellshocked || laststand::player_is_in_laststand() )
	{
		return;
	}
	if ( isplayer( eattacker ) && isDefined( eattacker._encounters_team ) && eattacker._encounters_team != self._encounters_team )
	{
		self.last_griefed_by.attacker = eattacker;
		self.last_griefed_by.meansofdeath = smeansofdeath;
		self.last_griefed_by.weapon = sweapon;
		if ( isDefined( level._game_module_player_damage_grief_callback ) )
		{
			self [[ level._game_module_player_damage_grief_callback ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );
		}
		// if ( isDefined( level._effect[ "butterflies" ] ) )
		// {
		// 	if ( isDefined( sweapon ) && weapontype( sweapon ) == "grenade" )
		// 	{
		// 		playfx( level._effect[ "butterflies" ], self.origin + vectorScale( ( 1, 1, 1 ), 40 ) );
		// 	}
		// 	else
		// 	{
		// 		playfx( level._effect[ "butterflies" ], vpoint, vdir );
		// 	}
		// }
		//self thread watch_for_down( eattacker );
		self thread do_game_mode_shellshock( eattacker, smeansofdeath );
		self playsound( "zmb_player_hit_ding" );
	}
}

function do_game_mode_shellshock( attacker, meansofdeath ) //checked matched cerberus output
{
	self endon( "disconnect" );
	self._being_shellshocked = 1;
	if ( meansofdeath == "MOD_MELEE" )
	{
		self shellshock( "grief_stab_zm", 0.75 );
	}
	else 
	{
		self shellshock( "grief_stab_zm", 0.25 );
	}
	wait 0.75;
	self._being_shellshocked = 0;
}

function game_module_player_damage_grief_callback( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
	old_revives = self.revives;
	if ( isDefined( eattacker ) && isplayer( eattacker ) && eattacker != self && eattacker.team != self.team )
	{
		if ( smeansofdeath == "MOD_MELEE" )
		{
			//check if player is reviving before knockback
			// if ( self zm_laststand::is_reviving_any() )
			// {
			// 	self.is_reviving_grief = 1;
			// }
			self applyknockback( idamage, vdir );
		}
		// else if ( is_weapon_shotgun( sweapon ) )
		// {
		// 	if ( self zm_laststand::is_reviving_any() )
		// 	{
		// 		self.is_reviving_grief = 1;
		// 	}
		// 	self applyknockback( idamage, vdir );
		// }
	}
	// if ( isDefined( self.is_reviving_grief ) && self.is_reviving_grief )
	// {
	// 	if ( self.revives == old_revives )
	// 	{
	// 		if ( !self zm_laststand::is_reviving_any() )
	// 		{
	// 			knocked_off_revive = 1;
	// 		}
	// 	}
	// }
	// if ( isDefined( knocked_off_revive ) && knocked_off_revive )
	// {
	// 	//self player_steal_points( eattacker, "deny_revive" );
	// }
	self.is_reviving_grief = false;
}

function player_prevent_damage( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
    if ( isdefined( eattacker ) && isplayer( eattacker ) && self != eattacker && !eattacker hasperk( "specialty_noname" ) && !( isdefined( self.is_zombie ) && self.is_zombie ) )
        return true;

    return false;
}