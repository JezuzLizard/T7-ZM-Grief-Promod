
Lobby.Process.CreateDedicatedModsLobby = function (f8_arg0, f8_arg1)
	local lobby = {}
	lobby.id = 402.000000
	lobby.name = "ZMLobbyOnlineCustomGame"
	lobby.title = "MENU_PRIVATE_GAME_CAPS"
	lobby.kicker = "MENU_FILESHARE_CUSTOMGAMES"
	lobby.room = "zm"
	lobby.isPrivate = true
	lobby.isGame = true
	lobby.isAdvertised = true
	lobby.maxClients = Dvar.com_maxclients:get()
	lobby.maxLocalClients = 2
	lobby.maxLocalClientsNetwork = 2
	lobby.mainMode = Enum.LobbyMainMode.LOBBY_MAINMODE_ZM
	lobby.networkMode = Enum.LobbyNetworkMode.LOBBY_NETWORKMODE_LIVE
	lobby.lobbyType = Enum.LobbyType.LOBBY_TYPE_GAME
	lobby.lobbyMode = Enum.LobbyMode.LOBBY_MODE_CUSTOM
	lobby.eGameModes = Enum.eGameModes.MODE_GAME_MANUAL_PLAYLIST
	lobby.lobbyTimerType = LuaEnums.TIMER_TYPE.MANUAL
	lobby.menuMusic = "zm_frontend"
	lobby.joinPartyPrivacyCheck = false
	f8_arg1 = lobby
	local f8_local0 = Dvar.sv_playlist
	Engine.SetPlaylistID(f8_local0:get())
	local f8_local1 = Lobby.Actions.ExecuteScript(function ()
		Lobby.ProcessNavigate.SetupLobbyMapAndGameType(f8_arg0, f8_arg1)
	end)
	local f8_local2 = Lobby.Actions.SetNetworkMode(f8_arg0, Enum.LobbyNetworkMode.LOBBY_NETWORKMODE_LIVE)
	local f8_local3 = Lobby.Actions.LobbySettings(f8_arg0, f8_arg1)
	local f8_local4 = Lobby.Actions.UpdateUI(f8_arg0, f8_arg1)
	local f8_local5 = Lobby.Actions.LobbyHostStart(f8_arg0, f8_arg1.mainMode, f8_arg1.lobbyType, f8_arg1.lobbyMode, f8_arg1.maxClients)
	local f8_local6 = Lobby.Actions.AdvertiseLobby(true)
	local f8_local7 = Lobby.Actions.ExecuteScript(function ()
		Engine.QoSProbeListenerEnable(f8_arg1.lobbyType, true)
		Engine.SetDvar("live_dedicatedReady", 1)
		Engine.RunPlaylistRules(f8_arg0)
		Engine.RunPlaylistSettings(f8_arg0)
		Lobby.Timer.HostingLobby({controller = f8_arg0, lobbyType = f8_arg1.lobbyType, mainMode = f8_arg1.mainMode, lobbyTimerType = f8_arg1.lobbyTimerType})
		-- Engine.Exec(0, "launchgame")
	end)
	Lobby.Process.AddActions(f8_local2, f8_local3)
	Lobby.Process.AddActions(f8_local3, f8_local1)
	Lobby.Process.AddActions(f8_local1, f8_local4)
	Lobby.Process.AddActions(f8_local4, f8_local5)
	Lobby.Process.AddActions(f8_local5, f8_local6)
	Lobby.Process.AddActions(f8_local6, f8_local7)
	Lobby.Process.AddActions(f8_local7, nil)
	return {head = f8_local2, interrupt = Lobby.Interrupt.NONE, force = true, cancellable = true}
end

Lobby.TeamSelection.ShouldAssignToTeam = function ( LobbyData )
	-- local LobbyMenuTarget = LobbyData.GetCurrentMenuTarget()
	-- if LobbyMenuTarget.mainMode ~= Enum.LobbyMainMode.LOBBY_MAINMODE_MP then
	-- 	return false
	-- elseif LobbyData.lobbyModule == Enum.LobbyModule.LOBBY_MODULE_HOST and LobbyData.lobbyType == Enum.LobbyType.LOBBY_TYPE_GAME then
	-- 	if f2_arg0.lobbyMode == Enum.LobbyMode.LOBBY_MODE_CUSTOM then
	-- 		if not CoDShared.IsGametypeTeamBased() then
	-- 			return false
	-- 		elseif Engine.IsInGame() then
	-- 			return false
	-- 		elseif Enum.GameServerStatus.GAME_SERVER_STATUS_IDLE < Engine.LobbyHostLaunchGetServerStatus() then
	-- 			return false
	-- 		elseif Enum.LobbyPregameState.LOBBY_PREGAME_STATE_IDLE ~= Engine.GetLobbyPregameState() ~= true and Engine.GetGametypeSetting( "teamAssignment" ) == LuaEnums.TEAM_ASSIGNMENT.AUTO and Lobby.Timer.GetTimerStatus() ~= Lobby.Timer.LOBBY_STATUS.STARTING then
	-- 			return false
	-- 		else
	-- 			return true
	-- 		end
	-- 	elseif LobbyData.lobbyMode == Enum.LobbyMode.LOBBY_MODE_PUBLIC or LobbyData.lobbyMode == Enum.LobbyMode.LOBBY_MODE_ARENA then
	-- 		if Lobby.Timer.GetTimerStatus() == Lobby.Timer.LOBBY_STATUS.STARTING then
	-- 			return true
	-- 		elseif Engine.IsInGame() then
	-- 			return true
	-- 		elseif Enum.GameServerStatus.GAME_SERVER_STATUS_IDLE < Engine.LobbyHostLaunchGetServerStatus() then
	-- 			return true
	-- 		else
	-- 			return 
	-- 		end
	-- 	end
	-- end
	-- return false
	return true
end