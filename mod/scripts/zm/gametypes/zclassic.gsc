// T6 GSC SOURCE
// Decompiled by https://github.com\xensik\gsc-tool
#using scripts\codescripts\struct;
#using scripts\shared\math_shared;
#using scripts\shared\ai\zombie_utility;
#using scripts\shared\flag_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\util_shared;
#using scripts\zm\gametypes\_globallogic_score;
#using scripts\zm\gametypes\_globallogic_ui;
#using scripts\zm\gametypes\_zm_gametype;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm;

function main()
{
	zm_gametype::main();
	level.onprecachegametype = &onprecachegametype;
	level.onstartgametype = &onstartgametype;
	level._game_module_custom_spawn_init_func = &zm_gametype::custom_spawn_init_func;
	level.custom_spectate_permissions = &setspectatepermissionsgrief;
	level._supress_survived_screen = 1;
	level._game_module_player_laststand_callback = &grief_laststand_weapon_save;
	level.onplayerspawned_restore_previous_weapons = &grief_laststand_weapons_return;
	level.game_module_onplayerconnect = &grief_onplayerconnect;
	//level.autoassign = &autoassign_override;
	callback::on_start_gametype( &init );
}

function onprecachegametype()
{
	level.playersuicideallowed = 1;
	level.canplayersuicide = &zm_gametype::canplayersuicide;
}

function onstartgametype()
{
	level.spawnmins = (0, 0, 0);
	level.spawnmaxs = (0, 0, 0);
	structs = struct::get_array("player_respawn_point", "targetname");
	foreach(struct in structs)
	{
		level.spawnmins = math::expand_mins(level.spawnmins, struct.origin);
		level.spawnmaxs = math::expand_maxs(level.spawnmaxs, struct.origin);
	}
	level.mapcenter = math::find_box_center(level.spawnmins, level.spawnmaxs);
	setmapcenter(level.mapcenter);
}

function init()
{
	level.powerup_drop_count = 0;
	level.no_end_game_check = 1;
	level._game_module_game_end_check = &grief_game_end_check_func;
	level.round_end_custom_logic = &grief_round_end_custom_logic;
	level thread zm_gametype::init();
	level.callbackplayermelee = &callback_playermelee;
	level._supress_survived_screen = true;
	level thread wait_for_team_death_and_round_end_override();
}

function grief_onplayerconnect()
{
	self thread zgrief_player_bled_out_msg();
}

function setspectatepermissionsgrief()
{
	self allowspectateteam( "allies", 1 );
	self allowspectateteam( "axis", 1 );
	self allowspectateteam( "freelook", 0 );
	self allowspectateteam( "none", 1 );
}

function grief_game_end_check_func()
{
	return 0;
}

function zgrief_player_bled_out_msg()
{
	level endon( "end_game" );
	self endon( "disconnect" );
	if ( !(isDefined( level.grief_ffa ) && level.grief_ffa ) )
	{
		while ( true )
		{
			self waittill( "bled_out" );

			level thread update_players_on_bleedout_or_disconnect( self );
		}
	}
}

function show_grief_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
	self endon( "disconnect" );

	while ( isdefined( level.hostmigrationtimer ) )
		wait 0.05;

	zgrief_hudmsg = newclienthudelem( self );
	zgrief_hudmsg.alignx = "center";
	zgrief_hudmsg.aligny = "middle";
	zgrief_hudmsg.horzalign = "center";
	zgrief_hudmsg.vertalign = "middle";
	zgrief_hudmsg.y -= 130;
	if ( isdefined( offset ) )
		zgrief_hudmsg.y += offset;

	zgrief_hudmsg.foreground = 1;
	zgrief_hudmsg.fontscale = 5;
	zgrief_hudmsg.alpha = 0;
	zgrief_hudmsg.color = ( 1, 1, 1 );
	zgrief_hudmsg.hidewheninmenu = 1;
	zgrief_hudmsg.font = "default";

	if ( isdefined( cleanup_end_game ) && cleanup_end_game )
	{
		level endon( "end_game" );
		zgrief_hudmsg thread show_grief_hud_msg_cleanup();
	}

	if ( isdefined( msg_parm ) )
		zgrief_hudmsg settext( msg, msg_parm );
	else
		zgrief_hudmsg settext( msg );

	zgrief_hudmsg changefontscaleovertime( 0.25 );
	zgrief_hudmsg fadeovertime( 0.25 );
	zgrief_hudmsg.alpha = 1;
	zgrief_hudmsg.fontscale = 2;
	wait 3.25;
	zgrief_hudmsg changefontscaleovertime( 1 );
	zgrief_hudmsg fadeovertime( 1 );
	zgrief_hudmsg.alpha = 0;
	zgrief_hudmsg.fontscale = 5;
	wait 1;
	zgrief_hudmsg notify( "death" );

	if ( isdefined( zgrief_hudmsg ) )
		zgrief_hudmsg destroy();
}

function show_grief_hud_msg_cleanup()
{
	self endon( "death" );

	level waittill( "end_game" );

	if ( isdefined( self ) )
		self destroy();
}

function grief_laststand_weapon_save( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration )
{
	self.grief_savedweapon_weapons = self getweaponslist();
	self.grief_savedweapon_weaponsammo_stock = [];
	self.grief_savedweapon_weaponsammo_clip = [];
	self.grief_savedweapon_currentweapon = self getcurrentweapon();
	self.grief_savedweapon_grenades = self zm_utility::get_player_lethal_grenade();

	if ( isdefined( self.grief_savedweapon_grenades ) && self.grief_savedweapon_grenades != level.weaponnone )
		self.grief_savedweapon_grenades_clip = self getweaponammoclip( self.grief_savedweapon_grenades );

	self.grief_savedweapon_tactical = self zm_utility::get_player_tactical_grenade();

	if ( isdefined( self.grief_savedweapon_tactical ) && self.grief_savedweapon_tactical != level.weaponnone )
		self.grief_savedweapon_tactical_clip = self getweaponammoclip( self.grief_savedweapon_tactical );

	for ( i = 0; i < self.grief_savedweapon_weapons.size; i++ )
	{
		self.grief_savedweapon_weaponsammo_clip[i] = self getweaponammoclip( self.grief_savedweapon_weapons[i] );
		self.grief_savedweapon_weaponsammo_stock[i] = self getweaponammostock( self.grief_savedweapon_weapons[i] );
	}
}

function grief_laststand_weapons_return()
{
	if ( !( isdefined( level.isresetting_grief ) && level.isresetting_grief ) )
		return false;

	if ( !isdefined( self.grief_savedweapon_weapons ) )
		return false;

	primary_weapons_returned = 0;

	i = 0;
	while ( i < self.grief_savedweapon_weapons.size )
	{
		weapon = self.grief_savedweapon_weapons[ i ];
		if ( isdefined( self.grief_savedweapon_grenades ) && weapon == self.grief_savedweapon_grenades || isdefined( self.grief_savedweapon_tactical ) && weapon == self.grief_savedweapon_tactical )
		{
			i++;
			continue;
		}
		self giveweapon( weapon );

		if ( isdefined( self.grief_savedweapon_weaponsammo_clip[i] ) )
			self setweaponammoclip( weapon, self.grief_savedweapon_weaponsammo_clip[i] );

		if ( isdefined( self.grief_savedweapon_weaponsammo_stock[i] ) )
			self setweaponammostock( weapon, self.grief_savedweapon_weaponsammo_stock[i] );
		i++;
	}

	if ( isdefined( self.grief_savedweapon_grenades ) )
	{
		self giveweapon( self.grief_savedweapon_grenades );

		if ( isdefined( self.grief_savedweapon_grenades_clip ) )
			self setweaponammoclip( self.grief_savedweapon_grenades, self.grief_savedweapon_grenades_clip );
	}

	if ( isdefined( self.grief_savedweapon_tactical ) )
	{
		self giveweapon( self.grief_savedweapon_tactical );

		if ( isdefined( self.grief_savedweapon_tactical_clip ) )
			self setweaponammoclip( self.grief_savedweapon_tactical, self.grief_savedweapon_tactical_clip );
	}
	primaries = self getweaponslistprimaries();

	foreach ( weapon in primaries )
	{
		if ( isdefined( self.grief_savedweapon_currentweapon ) && self.grief_savedweapon_currentweapon == weapon )
		{
			self switchtoweapon( weapon );
			return true;
		}
	}

	if ( primaries.size > 0 )
	{
		self switchtoweapon( primaries[0] );
		return true;
	}
	return false;
}

function update_players_on_bleedout_or_disconnect( excluded_player )
{
	other_team = undefined;
	players = getPlayers();
	players_remaining = 0;

	foreach ( player in players )
	{
		if ( player == excluded_player )
		{
			continue;
		}
		if ( player.team == excluded_player.team )
		{
			if ( zm_utility::is_player_valid( player ) )
				players_remaining++;
		}
	}

	foreach ( player in players )
	{
		if ( player == excluded_player )
		{
			continue;
		}
		if ( player.team != excluded_player.team )
		{
			other_team = player.team;

			if ( players_remaining < 1 )
			{
				//player thread show_grief_hud_msg( &"ZOMBIE_ZGRIEF_ALL_PLAYERS_DOWN", undefined, undefined, 1 );
				//player delay_thread_watch_host_migrate( 2, ::show_grief_hud_msg, &"ZOMBIE_ZGRIEF_SURVIVE", undefined, 30, 1 );
			}
			else 
			{
				//player thread show_grief_hud_msg( &"ZOMBIE_ZGRIEF_PLAYER_BLED_OUT", players_remaining );
			}
		}
	}
}

function delay_thread_watch_host_migrate( timer, func, param1, param2, param3, param4, param5, param6 )
{
	self thread _delay_thread_watch_host_migrate_proc( func, timer, param1, param2, param3, param4, param5, param6 );
}

function _delay_thread_watch_host_migrate_proc( func, timer, param1, param2, param3, param4, param5, param6 )
{
	self endon( "death" );
	self endon( "disconnect" );
	wait( timer );

	if ( isdefined( level.hostmigrationtimer ) )
	{
		while ( isdefined( level.hostmigrationtimer ) )
			wait 0.05;

		wait( timer );
	}

	util::single_thread( self, func, param1, param2, param3, param4, param5, param6 );
}

function grief_round_end_custom_logic()
{
	waittillframeend;

	if ( isdefined( level.gamemodulewinningteam ) )
		level notify( "end_round_think" );
}

function autoassign_override( comingFromMenu )
{
	if ( !isDefined( level.grief_team_members ) )
	{
		level.grief_team_members = [];
		level.grief_team_members[ "allies" ] = [];
		level.grief_team_members[ "axis" ] = [];
		level.grief_team_members[ "allies" ][ 0 ] = self;
		self.team = "allies";
		self.sessionteam = "allies";
		self.pers[ "team" ] = "allies";
		self._encounters_team = "B";
	}
	else if ( level.grief_team_members[ "axis" ].size == 0 )
	{
		level.grief_team_members[ "axis" ][ 0 ] = self;
		self.team = "axis";
		self.sessionteam = "axis";
		self.pers[ "team" ] = "axis";
		self._encounters_team = "A";
	}
	else 
	{
		if ( level.grief_team_members[ "axis" ].size > level.grief_team_members[ "allies" ].size )
		{
			level.grief_team_members[ "allies" ][ level.grief_team_members[ "allies" ].size ] = self;
			self.team = "allies";
			self.sessionteam = "allies";
			self.pers[ "team" ] = "allies";
			self._encounters_team = "B";
		}
		else if ( level.grief_team_members[ "allies" ].size > level.grief_team_members[ "axis" ].size )
		{
			level.grief_team_members[ "axis" ][ level.grief_team_members[ "axis" ].size ] = self;
			self.team = "axis";
			self.sessionteam = "axis";
			self.pers[ "team" ] = "axis";
			self._encounters_team = "A";
		}
		else 
		{
			level.grief_team_members[ "allies" ][ level.grief_team_members[ "allies" ].size ] = self;
			self.team = "allies";
			self.sessionteam = "allies";
			self.pers[ "team" ] = "allies";
			self._encounters_team = "B";
		}
	}
	// teamplayersallies = getPlayers( "allies").size;
	// teamplayersaxis = getPlayers( "axis").size;
	// if ( teamplayersallies > teamplayersaxis )
	// {
	// 	self.team = "axis";
	// 	self.sessionteam = "axis";
	// 	self.pers[ "team" ] = "axis";
	// 	self._encounters_team = "A";
	// }
	// else if ( teamplayersallies < teamplayersaxis )
	// {
	// 	self.team = "allies";
	// 	self.sessionteam = "allies";
	// 	self.pers[ "team" ] = "allies";
	// 	self._encounters_team = "B";
	// }
	// else
	// {
	// 	self.team = "allies";
	// 	self.sessionteam = "allies";
	// 	self.pers[ "team" ] = "allies";
	// 	self._encounters_team = "B";
	// }
	logprint( "teamplayersallies: " + level.grief_team_members[ "allies" ].size + " teamplayersaxis: " + level.grief_team_members[ "axis" ].size + " " + self.name + " team: " + self.team + "\n" );
	self.pers["class"] = undefined;
	self.curClass = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self globallogic_ui::updateObjectiveText();
	if ( !isAlive( self ) )
		self.statusicon = "hud_status_dead";
	
	self notify("joined_team");
	level notify( "joined_team" );
	self callback::callback( #"on_joined_team" );
	self notify("end_respawn");
	
	self globallogic_ui::beginClassChoice();	
	self SetClientScriptMainMenu( game[ "menu_start_menu" ] );
}

function wait_for_team_death_and_round_end_override()
{
	level flag::wait_till("initial_blackscreen_passed");
	if ( isDefined( level.grief_ffa ) && level.grief_ffa ) 
	{
		level thread round_system_ffa();
		return;
	}

	level endon( "game_module_ended" );
	level endon( "end_game" );

	checking_for_round_end = 0;
	checking_for_round_tie = 0;
	level.isresetting_grief = 0;
 
	level.grief_score = [];
	level.grief_score["A"] = 0;
	level.grief_score["B"] = 0;

	//waiting_for_players();

	// if ( level.grief_gamerules[ "auto_balance_teams" ].current )
	// {
	// 	scripts\zm\promod_grief\_teams::auto_balance_teams();
	// }

	//scripts\zm\promod_grief\_hud::hud_init();

	round_start_wait();
	//level flag::set( "grief_begin" );

	while ( 1 )
	{
		cdc_alive = 0;
		cia_alive = 0;
		players = getPlayers();
		for ( i = 0; i < players.size; i++ )
		{
			if ( !isDefined( players[ i ]._encounters_team ) )
			{
				i++;
				continue;
			}
			if ( players[ i ]._encounters_team == "A" )
			{
				if ( zm_utility::is_player_valid( players[ i ] ) )
				{
					cia_alive++;
				}
				i++;
				continue;
			}
			if ( zm_utility::is_player_valid( players[ i ] ) )
			{
				cdc_alive++;
			}
		}

		if ( !checking_for_round_tie )
		{
			if(cia_alive == 0 && cdc_alive == 0)
			{
				level notify( "stop_round_end_check" );
				level thread check_for_round_end();
				checking_for_round_tie = 1;
				checking_for_round_end = 1;
			}
		}

		if ( !checking_for_round_end )
		{
			if ( cia_alive == 0 )
			{
				level thread check_for_round_end( "B" );
				checking_for_round_end = 1;
			}
			else if ( cdc_alive == 0 )
			{
				level thread check_for_round_end( "A" );
				checking_for_round_end = 1;
			}
		}

		if ( cia_alive > 0 && cdc_alive > 0 )
		{
			level notify( "stop_round_end_check" );
			checking_for_round_end = 0;
			checking_for_round_tie = 0;
		}

		wait 0.05;
	}
}

function round_system_ffa()
{
	level endon( "game_module_ended" );
	level endon( "end_game" );

	checking_for_round_end = 0;
	checking_for_round_tie = 0;
	level.isresetting_grief = 0;

	//waiting_for_players();

	//HUDELEM_SERVER_ADD( "grief_countdown_timer", ::grief_countdown );

	round_start_wait();
	//level flag::set( "grief_begin" );

	while ( 1 )
	{
		players_alive = 0;
		players = getPlayers();
		for ( i = 0; i < players.size; i++ )
		{
			if ( zm_utility::is_player_valid( players[ i ] ) )
			{
				alive_player = players[ i ];
				players_alive++;
			}
		}

		if ( !checking_for_round_tie )
		{
			if( players_alive == 0 )
			{
				level notify( "stop_round_end_check" );
				level thread check_for_round_end();
				checking_for_round_tie = 1;
				checking_for_round_end = 1;
			}
		}

		if ( !checking_for_round_end )
		{
			if ( players_alive == 1 )
			{
				level thread check_for_round_end( alive_player );
				checking_for_round_end = 1;
			}
		}

		if ( players_alive > 1 )
		{
			level notify( "stop_round_end_check" );
			checking_for_round_end = 0;
			checking_for_round_tie = 0;
		}
		wait 0.05;
	}
}

function check_for_round_end(winner)
{
	level endon( "stop_round_end_check" );
	level endon( "end_game" );

	if(isDefined(winner))
	{
		//wait level.grief_gamerules[ "suicide_check_time" ].current;
		wait 3;
	}
	else
	{
		wait 0.5;
	}

	level thread round_end(winner);
}

function round_end(winner)
{
	if(isDefined( level.grief_ffa ) && level.grief_ffa)
	{
		if(isDefined(winner))
		{
			winner.survived++;
			//if ( winner.survived >= level.grief_gamerules[ "scorelimit" ].current )
			if ( winner.survived >= 3 )
			{
				game_won(winner);
				return;
			}
		}
	}
	else
	{
		team = undefined;
		if(isDefined(winner))
		{
			if(winner == "A")
			{
				team = "axis";
			}
			else
			{
				team = "allies";
			}
		}

		if(isDefined(winner))
		{
			level.grief_score[winner]++;
			//level.server_hudelems[ "grief_score_" + winner ].hudelem SetValue( level.grief_score[ winner ] );
			setteamscore(team, level.grief_score[winner]);

			//if(level.grief_score[winner] >= level.grief_gamerules[ "scorelimit" ].current)
			if ( level.grief_score[winner] >= 3 )
			{
				game_won(winner);
				return;
			}
		}
	}


	players = getPlayers();
	foreach(player in players)
	{
		if(zm_utility::is_player_valid(player))
		{
			// don't give perk
			player notify("perk_abort_drinking");
			// save weapons
			player [[level._game_module_player_laststand_callback]]();
		}
	}

	level.isresetting_grief = 1;
	level notify( "end_round_think" );
	level.zombie_vars[ "spectators_respawn" ] = 1;
	level notify( "keep_griefing" );
	level notify( "restart_round" );

	if(isDefined(winner))
	{
		if(isDefined( level.grief_ffa ) && level.grief_ffa)
		{
			foreach(player in players)
			{
				if(player.name == winner.name)
				{
					//player thread show_grief_hud_msg( "You won the round" );
				}
				else
				{
					//player thread show_grief_hud_msg( "You lost the round" );
				}
			}
		}
		else
		{
			foreach(player in players)
			{
				if(player.team == team)
				{
					//player thread show_grief_hud_msg( "You won the round" );
				}
				else
				{
					//player thread show_grief_hud_msg( "You lost the round" );
				}
			}
		}
	}
	else
	{
		foreach(player in players)
		{
			//level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog( "grief_restarted" );
			//player thread show_grief_hud_msg( &"ZOMBIE_GRIEF_RESET" );
		}
	}

	zombie_goto_round( level.round_number );
	wait 1;
	level.isresetting_grief = 0;
	level thread zm::round_think( 1 );
	level.zombie_vars[ "spectators_respawn" ] = 0;
}

function game_won(winner)
{
	level.grief_ffa_winner = winner.name;
	level.gamemodulewinningteam = winner;
	level.zombie_vars[ "spectators_respawn" ] = 0;
	if(!(isDefined( level.grief_ffa ) && level.grief_ffa))
	{
		players = getPlayers();
		i = 0;
		while ( i < players.size )
		{
			players[ i ] freezecontrols( 1 );
			if ( players[ i ]._encounters_team == winner )
			{
				//players[ i ] thread maps\mp\zombies\_zm_audio_announcer::leaderdialogonplayer( "grief_won" );
				i++;
				continue;
			}
			//players[ i ] thread maps\mp\zombies\_zm_audio_announcer::leaderdialogonplayer( "grief_lost" );
			i++;
		}
		//maps\mp\gametypes_zm\_zm_gametype::track_encounters_win_stats( level.gamemodulewinningteam );
	}
	level._game_module_game_end_check = undefined;
	level notify( "game_module_ended", winner );
	level notify( "end_game" );
}

function zombie_goto_round(target_round)
{
	level endon( "end_game" );

	if ( target_round < 1 )
	{
		target_round = 1;
	}

	level.zombie_total = 0;
	zombies = zombie_utility::get_round_enemy_array();
	if ( isDefined( zombies ) )
	{
		for ( i = 0; i < zombies.size; i++ )
		{
			zombies[ i ] dodamage( zombies[ i ].health + 666, zombies[ i ].origin );
		}
	}

	respawn_players();
	wait 0.05; // let all players fully respawn

	level thread zm::award_grenades_for_survivors();

	level thread round_start_wait();
}

function round_start_wait()
{
	level endon("end_game");

	//level flag::clear("spawn_zombies");
	freeze_all_players_controls();

	//round_start_countdown_hud(level.grief_gamerules[ "next_round_time" ].current);
	wait 5;
	unfreeze_all_players_controls();

	//wait level.grief_gamerules[ "spawn_zombies_wait_time" ].current;
	wait 5;
	//level flag::set("spawn_zombies");
}


function respawn_players() 
{
	players = getPlayers();
	foreach ( player in players )
	{
		player [[ level.spawnplayer ]]();
		// player freeze_player_controls( 1 );
	}
}

function all_surviving_players_vulnerable()
{
	players = getPlayers();
	foreach ( player in players )
	{
		if ( zm_utility::is_player_valid( player ) )
		{
			player disableInvulnerability();
		}
	}
}

function freeze_all_players_controls()
{
	players = getPlayers();
	foreach ( player in players )
	{
		player freezeControls( 1 );
	}
}

function unfreeze_all_players_controls()
{
	players = getPlayers();
	foreach ( player in players )
	{
		player freezeControls( 0 );
		player notify( "controls_unfrozen");
	}
}

function custom_end_screen_override()
{
	players = getPlayers();
	i = 0;
	while ( i < players.size )
	{
		players[ i ].game_over_hud = newclienthudelem( players[ i ] );
		players[ i ].game_over_hud.alignx = "center";
		players[ i ].game_over_hud.aligny = "middle";
		players[ i ].game_over_hud.horzalign = "center";
		players[ i ].game_over_hud.vertalign = "middle";
		players[ i ].game_over_hud.y -= 130;
		players[ i ].game_over_hud.foreground = 1;
		players[ i ].game_over_hud.fontscale = 3;
		players[ i ].game_over_hud.alpha = 0;
		players[ i ].game_over_hud.color = ( 1, 1, 1 );
		players[ i ].game_over_hud.hidewheninmenu = 1;
		players[ i ].game_over_hud settext( &"ZOMBIE_GAME_OVER" );
		players[ i ].game_over_hud fadeovertime( 1 );
		players[ i ].game_over_hud.alpha = 1;
		players[ i ].survived_hud = newclienthudelem( players[ i ] );
		players[ i ].survived_hud.alignx = "center";
		players[ i ].survived_hud.aligny = "middle";
		players[ i ].survived_hud.horzalign = "center";
		players[ i ].survived_hud.vertalign = "middle";
		players[ i ].survived_hud.y -= 100;
		players[ i ].survived_hud.foreground = 1;
		players[ i ].survived_hud.fontscale = 2;
		players[ i ].survived_hud.alpha = 0;
		players[ i ].survived_hud.color = ( 1, 1, 1 );
		players[ i ].survived_hud.hidewheninmenu = 1;
		if(isDefined( level.grief_ffa ) && level.grief_ffa)
		{
			players[ i ].survived_hud settext( level.grief_ffa_winner + " WINS!" );
		}
		else
		{
			if ( isDefined( level.gamemodulewinningteam ) && players[ i ]._encounters_team == level.gamemodulewinningteam )
			{
				players[ i ].survived_hud settext( "YOU WIN!" );
			}
			else
			{
				players[ i ].survived_hud settext( "YOU LOSE!" );
			}
		}
		players[ i ].survived_hud fadeovertime( 1 );
		players[ i ].survived_hud.alpha = 1;
		i++;
	}
}


function callback_playermelee(eattacker, idamage, weapon, vorigin, vdir, boneindex, shieldhit, frombehind)
{
	hit = 1;
    if ( !(isDefined( level.grief_ffa ) && level.grief_ffa) && level.teambased && self.team == eattacker.team )
    {
        if ( level.friendlyfire == 0 )
            hit = 0;
    }
	self finishmeleehit(eattacker, weapon, vorigin, vdir, boneindex, shieldhit, hit, frombehind);
}