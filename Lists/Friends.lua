local e, L = unpack(select(2, ...))

local SYNC_VERSION = 'sync4'
local UPDATE_VERSION = 'update4'

local COLOR_BLUE_BNET = 'ff82c5ff'

local strformat, find = string.format, string.find
local tremove = table.remove

local NonBNFriend_List = {}
local BNFriendList = {}
local FRIEND_LIST = {}
local BNET_GAID_TO_BATTLETAG = {}

----------------------------------------------------
----------------------------------------------------
-- BNet Friend's list API
-- Collect and store pressence, game pressence IDs

local BNGetFriendInfo = BNGetFriendInfo

-- BNGetNumFOF(BNetID) -- Seems to take first return value from BNGetFriendInfo

--local isConnected = BNConnected() -- Determine if connected to BNet, if not disable all comms, check for BN_CONNECTED to re-enable communications, BN_DISCONNECTED disable communications on this event

-- Returns a player's game account ID
-- @param characterName string Full character name of the player being looked up
-- Only used for inviting people through the AK interface. Not worth the resources to invert the table for a quicker look up time since it would need to be inverted each time the friends list is upodated
function e.GetFriendGaID(characterName)
	for gaID, target in pairs(BNFriendList) do
		if target == characterName then
			return gaID
		end
	end
	return nil
end

-- Updates BNFriendList for friend update
-- @param index int Friend's list index that was updated
function e.BNFriendUpdate(index)
	if not index then return end -- No index, event fired from player

	local accountInfo = C_BattleNet.GetFriendAccountInfo(index)

	for gameIndex = 1, C_BattleNet.GetFriendNumGameAccounts(index) do		
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(index, gameIndex)		
		if BNFriendList[gameAccountInfo.gameAccountID] and gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW and gameAccountInfo.wowProjectID ~= 1 then -- They are logged into the client, but they are not logged into retail WoW
			BNFriendList[gameAccountInfo.gameAccountID] = nil
		end
		if gameAccountInfo and gameAccountInfo.clientProgram == BNET_CLIENT_WOW and gameAccountInfo.wowProjectID == 1 then --1 is used for retail
			local realmName
			if gameAccountInfo.realmName then
				realmName = gameAccountInfo.realmName
			elseif gameAccountInfo.realmDisplayName then
				realmName = gameAccountInfo.realmDisplayName:gsub('%s+', '')
			elseif gameAccountInfo.richPresence and gameAccountInfo.richPresence:find('-') then
				realmName = gameAccountInfo.richPresence:sub(gameAccountInfo.richPresence:find('-') + 1, -1):gsub('%s+', '') -- Character - Realm Name stripped down to RealmName
			else
				return
			end

			local fullName = gameAccountInfo.characterName .. '-' .. realmName
			BNFriendList[gameAccountInfo.gameAccountID] = fullName
			if FRIEND_LIST[fullName] then
				FRIEND_LIST[fullName].account_name = accountInfo.accountName
				FRIEND_LIST[fullName].battle_tag = accountInfo.battleTag
				FRIEND_LIST[fullName].isConnected = true
			else
				FRIEND_LIST[fullName] = {}
				FRIEND_LIST[fullName].account_name = accountInfo.accountName
				FRIEND_LIST[fullName].battle_tag = accountInfo.battleTag
				FRIEND_LIST[fullName].isConnected = true
			end
			if NonBNFriend_List[fullName] then
				NonBNFriend_List[fullName] = nil
			end
		end
		if gameAccountInfo.gameAccountID then
			BNET_GAID_TO_BATTLETAG[gameAccountInfo.gameAccountID] = accountInfo.battleTag
		end
	end
end
nEvents:Register('BN_FRIEND_INFO_CHANGED', e.BNFriendUpdate, 'update_BNFriend')

----------------------------------------------------
----------------------------------------------------
function e.FriendGUID(unit)
	if not FRIEND_LIST[unit] then return nil end
	return FRIEND_LIST[unit].guid
end

function e.FriendPresName(unit)
	if not FRIEND_LIST[unit] then return nil end
	return FRIEND_LIST[unit].account_name
end

function e.WipeFriendList()
	wipe(FRIEND_LIST)
end

function e.IsFriendOnline(unit)
	if not FRIEND_LIST[unit] then
		return false
	else
		return FRIEND_LIST[unit].isConnected
	end
end
----------------------------------------------------
----------------------------------------------------
---- Non BNet Friend stuff

local function serverRequestRespond(gameAccountID)
	if not gameAccountID or type(gameAccountID) ~= 'number' then
		return
	end

	local realm = unitRealm('player')

	if realm then
		realm = realm:gsub('%s+', '')
	end

	nComs:NewMessage('nKeys', 'serverRespond', realm, gameAccountID)
end

local function UpdateNonBNetFriendList()
	wipe(NonBNFriend_List)

	for k,v in pairs(FRIEND_LIST) do
		v.isConnected = false
	end

	for i = 1, C_FriendList.GetNumOnlineFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		local name = strformat('%s-%s', friendInfo.name, e.PlayerRealm())
		NonBNFriend_List[name] = {isConnected = friendInfo.connected}
		if FRIEND_LIST[name] then
			FRIEND_LIST[name].isConnected = true
			FRIEND_LIST[name].guid = guid
		end
	end

	for index = 1, BNGetNumFriends() do
		e.BNFriendUpdate(index)
	end
end
nEvents:Register('FRIENDLIST_UPDATE', UpdateNonBNetFriendList, 'update_non_bnet_list')

----------------------------------------------------
----------------------------------------------------
-- Friend Syncing

local function RecieveKey(msg, sender)
	if not nKeysSettings.friendOptions.friend_sync.isEnabled then return end
	
	local timeStamp = e.WeekTime()
	local unit, class, dungeonID, keyLevel, weekly_best, week, faction = strsplit(':', msg)

	local btag

	if type(sender) == 'number' then
		btag = BNET_GAID_TO_BATTLETAG[sender]
	end

	dungeonID = tonumber(dungeonID)
	keyLevel = tonumber(keyLevel)
	week = tonumber(week)
	weekly_best = tonumber(weekly_best)

	local id = e.UnitID(unit)

	if id then
		nKeys[id].dungeon_id = dungeonID
		nKeys[id].key_level = keyLevel
		nKeys[id].week = week
		nKeys[id].time_stamp = timeStamp
		nKeys[id].weekly_best = weekly_best
		nKeys[id].btag = btag
	else
		table.insert(nKeys, {
			unit = unit,
			btag = btag,
			class = class,
			dungeon_id = dungeonID,
			key_level = keyLevel,
			week = week,
			time_stamp = timeStamp,
			faction = faction,
			weekly_best = weekly_best,
			source = 'friend',
		})
		e.SetUnitID(unit, #nKeys)
		C_FriendList.ShowFriends()
	end
	e.AddUnitToSortTable(unit, btag, class, faction, dungeonID, keyLevel, weekly_best, 'FRIENDS')
	e.AddUnitToList(unit, 'FRIENDS', btag)

	msg = nil
	if e.FrameListShown() == 'FRIENDS' then 
		e.UpdateFrames()
	end
end
nComs:RegisterPrefix('BNET', UPDATE_VERSION, RecieveKey)
nComs:RegisterPrefix('WHISPER', UPDATE_VERSION, RecieveKey)

local function SyncFriendUpdate(entry, sender)
	if not nKeysSettings.friendOptions.friend_sync.isEnabled then return end

	if nKeyFrame:IsShown() then
		nKeyFrame:SetScript('OnUpdate', nKeyFrame.OnUpdate)
		nKeyFrame.updateDelay = 0
	end

	local btag
	if type(sender) == 'number' then
		btag = BNET_GAID_TO_BATTLETAG[sender]
	end

	if nKeyFrame:IsShown() then
		nKeyFrame:SetScript('OnUpdate', nKeyFrame.OnUpdate)
		nKeyFrame.updateDelay = 0
	end

	local unit, class, dungeonID, keyLevel, week, timeStamp

	local _pos = 0
	while find(entry, '_', _pos) do

		class, dungeonID, keyLevel, week, timeStamp, faction, weekly_best = entry:match(':(%a+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)', entry:find(':', _pos))
		unit = entry:sub(_pos, entry:find(':', _pos) - 1)
		_pos = find(entry, '_', _pos) + 1

		dungeonID = tonumber(dungeonID)
		keyLevel = tonumber(keyLevel)
		week = tonumber(week)
		timeStamp = tonumber(timeStamp)
		weekly_best = tonumber(weekly_best)

		if week >= e.Week then
			local id = e.UnitID(unit)
			if id then
				nKeys[id].dungeon_id = dungeonID
				nKeys[id].key_level = keyLevel
				nKeys[id].week = week
				nKeys[id].time_stamp = timeStamp
				nKeys[id].weekly_best = weekly_best
				nKeys[id].btag = btag
			else
				table.insert(nKeys, {
					unit = unit,
					btag = btag,
					class = class,
					dungeon_id = dungeonID,
					key_level = keyLevel,
					week = week,
					time_stamp = timeStamp,
					faction = faction,
					weekly_best = weekly_best,
					source = 'friend'
				})
				e.SetUnitID(unit, #nKeys)
				C_FriendList.ShowFriends()
			end
			e.AddUnitToList(unit, 'FRIENDS', btag)
			e.AddUnitToSortTable(unit, btag, class, faction, dungeonID, keyLevel, weekly_best, 'FRIENDS')
			--e.AddUnitToTable(unit, class, faction, 'FRIENDS', dungeonID, keyLevel, weekly_best, btag)
		end
	end
	entry = nil
end
nComs:RegisterPrefix('BNET', SYNC_VERSION, SyncFriendUpdate)
nComs:RegisterPrefix('WHISPER', SYNC_VERSION, SyncFriendUpdate)

local function UpdateWeekly(msg)
	local unit, weekly_best = strsplit(':', msg)

	local id = e.UnitID(unit)
	if id then
		nKeys[id].weekly_best = tonumber(weekly_best)
		nKeys[id].time_stamp = e.WeekTime()
	end
end
nComs:RegisterPrefix('BNET', 'friendWeekly', UpdateWeekly)
nComs:RegisterPrefix('WHISPER', 'friendWeekly', UpdateWeekly)

local messageStack = {}
local messageQueue = {}

local function PushKeysToFriends(target)
	if not nKeysSettings.friendOptions.friend_sync.isEnabled then return end
	wipe(messageStack)
	wipe(messageQueue)

	for i = 1, #nCharacters do
		local id = e.UnitID(nCharacters[i].unit)
		if id then -- We have a key for this character, let's get the message and queue it up
			local map, level = e.UnitMapID(id), e.UnitKeyLevel(id)			
			messageStack[#messageStack + 1] = strformat('%s_', strformat('%s:%s:%d:%d:%d:%d:%d:%d', nCharacters[i].unit, e.UnitClass(id), map, level, e.Week, nKeys[id][7], nCharacters[i].faction, nCharacters[i].weekly_best)) -- name-server:class:mapID:keyLevel:week#:weekTime:faction:weekly
		end
	end

	local index = 1
	messageQueue[index] = ''
	while(messageStack[1]) do
		local nextMessage = strformat('%s%s', messageQueue[index], messageStack[1])
		if nextMessage:len() < 2000 then
			messageQueue[index] = nextMessage
			table.remove(messageStack, 1)
		else
			index = index + 1
			messageQueue[index] = ''
		end
	end

	e.PushKeyDataToFriends(messageQueue, target)
end

-- Sends data to BNeT friends and Non-BNet friends
-- @param data table Sync data that includes all keys for all of person's characters
-- @param data string Update string including only logged in person's characters
function e.PushKeyDataToFriends(data, target)
	if not target then
		for gaID in pairs(BNFriendList) do
			if type(data) == 'table' then
				for i = 1, #data do
					nComs:NewMessage('nKeys', strformat('%s %s', SYNC_VERSION, data[i]), 'BNET', gaID)
				end
			else
				nComs:NewMessage('nKeys', strformat('%s %s', UPDATE_VERSION, data), 'BNET', gaID)
			end
		end
		for player in pairs(NonBNFriend_List) do
			if type(data) == 'table' then
				for i = 1, #data do
					nComs:NewMessage('nKeys', strformat('%s %s', SYNC_VERSION, data[i]), 'WHISPER', player)
				end
			else
				nComs:NewMessage('nKeys', strformat('%s %s', UPDATE_VERSION, data), 'WHISPER', player)
			end
		end
	else
		if type(data) == 'table' then
			for i = 1, #data do
				nComs:NewMessage('nKeys', strformat('%s %s', SYNC_VERSION, data[i]), tonumber(target) and 'BNET' or 'WHISPER', target)
			end
		else
			nComs:NewMessage('nKeys',  strformat('%s %s', UPDATE_VERSION, data), tonumber(target) and 'BNET' or 'WHISPER', target)
		end
	end
end


-- Let's find out which friends are using n Keys, no need to spam every friend, just the ones using n keys
local function PingFriendsFornKeys()
	if not nKeysSettings.friendOptions.friend_sync.isEnabled then return end
	for i = 1, C_FriendList.GetNumOnlineFriends() do -- Only parse over online friends
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		local name = strformat('%s-%s', friendInfo.name, e.PlayerRealm())

		NonBNFriend_List[name] = {isConnected = friendInfo.connected}
	end

	for index = 1, BNGetNumFriends() do
		e.BNFriendUpdate(index)
	end

	for gaID in pairs(BNFriendList) do
		nComs:NewMessage('nKeys', 'BNet_query ping', 'BNET', gaID)
	end

	for player in pairs(NonBNFriend_List) do
		nComs:NewMessage('nKeys', 'BNet_query ping', 'WHISPER', player)
	end

	nEvents:Unregister('FRIENDLIST_UPDATE', 'pingFriends')
end

-- Figures out who is using AK on friends list, sends them a response and key data
local function PingResponse(msg, sender)
	if msg:find('ping') then
		nComs:NewMessage('nKeys', 'BNet_query response', type(sender) == 'number' and 'BNET' or 'WHISPER', sender)
	end
	PushKeysToFriends(sender)
end
nComs:RegisterPrefix('WHISPER', 'BNet_query', PingResponse)
nComs:RegisterPrefix('BNET', 'BNet_query', PingResponse)

local function Init()
	C_FriendList.ShowFriends()
	nEvents:Unregister('PLAYER_ENTERING_WORLD', 'InitFriends')
end
nEvents:Register('FRIENDLIST_UPDATE', PingFriendsFornKeys, 'pingFriends')
nEvents:Register('PLAYER_ENTERING_WORLD', Init, 'InitFriends')


function e.ToggleFriendSync()
	if nKeysSettings.friendOptions.friend_sync.isEnabled then
		nComs:RegisterPrefix('WHISPER', 'BNet_query', PingResponse)
		nComs:RegisterPrefix('BNET', 'BNet_query', PingResponse)
		nComs:RegisterPrefix('BNET', SYNC_VERSION, SyncFriendUpdate)
		nComs:RegisterPrefix('WHISPER', SYNC_VERSION, SyncFriendUpdate)
		nComs:RegisterPrefix('BNET', UPDATE_VERSION, RecieveKey)
		nComs:RegisterPrefix('WHISPER', UPDATE_VERSION, RecieveKey)
		nEvents:Register('FRIENDLIST_UPDATE', UpdateNonBNetFriendList, 'update_non_bnet_list')
		nEvents:Register('BN_FRIEND_INFO_CHANGED', e.BNFriendUpdate, 'update_BNFriend')
		PingFriendsFornKeys()
	else
		nComs:UnregisterPrefix('WHISPER', 'BNet_query', PingResponse)
		nComs:UnregisterPrefix('BNET', 'BNet_query', PingResponse)
		nComs:UnregisterPrefix('BNET', SYNC_VERSION, SyncFriendUpdate)
		nComs:UnregisterPrefix('WHISPER', SYNC_VERSION, SyncFriendUpdate)
		nComs:UnregisterPrefix('BNET', UPDATE_VERSION, RecieveKey)
		nComs:UnregisterPrefix('WHISPER', UPDATE_VERSION, RecieveKey)
		nEvents:Unregister('FRIENDLIST_UPDATE', UpdateNonBNetFriendList, 'update_non_bnet_list')
		nEvents:Unregister('BN_FRIEND_INFO_CHANGED', e.BNFriendUpdate, 'update_BNFriend')
	end
end

----------------------------------------------------
----------------------------------------------------
-- Friend Filtering and sorting
-- Needs non-generic filering for names as well!
local function FriendFilter(A, filters)
	if not type(A) == 'table' then return end
	
	local keyLevelLowerBound, keyLevelUpperBound = 2, 999 -- Lowest key possible, some high enough number

	if filters['key_level'] ~= '' and filters['key_level'] ~= '1' then
		local keyFilterText = filters['key_level']
		if tonumber(keyFilterText) then -- only input a single key level
			keyLevelLowerBound = tonumber(keyFilterText)
			keyLevelUpperBound = tonumber(keyFilterText)
		elseif string.match(keyFilterText, '%d+%+') then -- Text input is <number>+, looking for any key at least <number>
			keyLevelLowerBound = tonumber(string.match(keyFilterText, '%d+'))
		elseif string.match(keyFilterText, '%d+%-') then -- Text input is <number>-, looking for a key no higher than <number>
			keyLevelUpperBound = tonumber(string.match(keyFilterText, '%d+'))
		end
	end

	for i = 1, #A do
		if nKeysSettings.frame.show_offline.isEnabled then
			A[i].isShown = true
		else
			A[i].isShown = e.IsFriendOnline(A[i].character_name)
		end

		if not nKeysSettings.friendOptions.show_other_faction.isEnabled then
			A[i].isShown = A[i].isShown and tonumber(A[i].faction) == e.FACTION
		end

		local isShownInFilter = true -- Assume there is no filter taking place
		
		for field, filterText in pairs(filters) do
				if filterText ~= '' then
					isShownInFilter = false -- There is a filter, now assume this unit is not to be shown
					if field == 'dungeon_name' then
						local mapName = e.GetMapName(A[i]['mapID'])
						if strfind(strlower(mapName), strlower(filterText)) then
							isShownInFilter = true
						end
					elseif field == 'key_level' then
						if A[i][field] >= keyLevelLowerBound and A[i][field] <= keyLevelUpperBound then
							isShownInFilter = true
						end
					else
						if strfind(strlower(A[i][field]):sub(1, A[i][field]:find('-') - 1), strlower(filterText)) or strfind(strlower(A[i].btag), strlower(filterText)) then
							isShownInFilter = true
						end
					end
				end
				A[i].isShown = A[i].isShown and isShownInFilter
			end

		if A[i].isShown then
			A.num_shown = A.num_shown + 1
		end
	end
end
e.AddListFilter('FRIENDS', FriendFilter)

local function CompareFriendNames(a, b)
	local s = string.lower(a.btag or '|')
	local t = string.lower(b.btag or '|')
	if nKeysSettings.frame.orientation == 0 then
		if s > t then
			return true
		elseif
			s < t then
			return false
		else
			return string.lower(a.character_name) > string.lower(b.character_name)
		end
	else
		if s < t then
			return true
		elseif
			s > t then
			return false
		else
			return string.lower(a.character_name) < string.lower(b.character_name)
		end
	end
end

local function FriendSort(A, v)
	if v == 'dungeon_name' then
		table.sort(A, function(a, b)
			local aOnline = e.IsFriendOnline(a.character_name) and 1 or 0
			local bOnline = e.IsFriendOnline(b.character_name) and 1 or 0
			if not nKeysSettings.frame.mingle_offline.isEnabled then
				aOnline = true
				bOnline = true
			end
			if aOnline == bOnline then
				if nKeysSettings.frame.orientation == 0 then
					if e.GetMapName(a.mapID) > e.GetMapName(b.mapID) then
						return true
					elseif e.GetMapName(b.mapID) > e.GetMapName(a.mapID) then
						return false
					else
						return a.character_name < b.character_name
					end
				else
					if e.GetMapName(a.mapID) > e.GetMapName(b.mapID) then
						return false
					elseif e.GetMapName(b.mapID) > e.GetMapName(a.mapID) then
						return true
					else
						return CompareFriendNames(a, b)
					end
				end
			else
				return aOnline > bOnline
			end
		end)
	else
		if v == 'character_name' then
			table.sort(A, function(a, b)
				local aOnline = e.IsFriendOnline(a.character_name) and 1 or 0
				local bOnline = e.IsFriendOnline(b.character_name) and 1 or 0
				if not nKeysSettings.frame.mingle_offline.isEnabled then
					aOnline = true
					bOnline = true
				end
				if aOnline == bOnline then
					return CompareFriendNames(a, b)
				else
					return aOnline > bOnline
				end
			end)
		else
			table.sort(A, function(a, b) 
				local aOnline = e.IsFriendOnline(a.character_name) and 1 or 0
				local bOnline = e.IsFriendOnline(b.character_name) and 1 or 0
				if not nKeysSettings.frame.mingle_offline.isEnabled then
					aOnline = true
					bOnline = true
				end
				if aOnline == bOnline then
					if nKeysSettings.frame.orientation == 0 then
						if a[v] > b[v] then
							return true
						elseif
							a[v] < b[v]  then
							return false
						else
							return CompareFriendNames(a, b)
						end
					else
						if a[v] < b[v] then
							return true
						elseif
							a[v] > b[v]  then
							return false
						else
							return CompareFriendNames(a, b)
						end
					end
				else
					return aOnline > bOnline
				end
			end)
		end
	end
end

e.AddListSort('FRIENDS', FriendSort)

-- Friend's list Hooking
do
	for i = 1, 5 do
		local textString = FriendsTooltip:CreateFontString('FriendsTooltipnKeysInfo' .. i, 'ARTWORK', 'FriendsFont_Small')
		textString:SetJustifyH('LEFT')
		textString:SetSize(168, 0)
		textString:SetTextColor(0.486, 0.518, 0.541)
	end

	local OnEnter, OnHide
	function OnEnter(self)
		if not self.id then return end -- Friend Groups adds fake units with no ide for group heeaders
		if not nKeysSettings.general.show_tooltip_key.isEnabled then return end

		local left = FRIENDS_TOOLTIP_MAX_WIDTH - FRIENDS_TOOLTIP_MARGIN_WIDTH - FriendsTooltipnKeysInfo1:GetWidth()
		local stringShown = false

		for gameIndex = 1, C_BattleNet.GetFriendNumGameAccounts(self.id) do
			if gameIndex > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS then break end -- Blizzard only wrote lines for 5 game indices
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(self.id, gameIndex)
			local characterNameString = _G['FriendsTooltipGameAccount' .. gameIndex .. 'Name']
			local gameInfoString = _G['FriendsTooltipGameAccount' .. gameIndex .. 'Info']
			local nKeyString = _G['FriendsTooltipnKeysInfo' .. gameIndex]
			if not FriendsTooltip.maxWidth then return end -- Why? Who knows

			if (gameAccountInfo) and (gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and (gameAccountInfo.wowProjectID == 1) then -- They are playing retail WoW

				if gameAccountInfo.gameAccountID then
					local realmName
					if gameAccountInfo.realmName then
						realmName = gameAccountInfo.realmName
					elseif gameAccountInfo.realmDisplayName then
						realmName = gameAccountInfo.realmDisplayName:gsub('%s+', '')
					elseif gameAccountInfo.richPresence and gameAccountInfo.richPresence:find('-') then
						realmName = gameAccountInfo.richPresence:sub(gameAccountInfo.richPresence:find('-') + 1, -1):gsub('%s+', '') -- Character - Realm Name stripped down to RealmName
					else
						-- I really don't know what is going on with their API....
					end
					if realmName then
						local fullName = gameAccountInfo.characterName .. '-' .. realmName
						local id = e.UnitID(fullName)
						if id then
							local keyLevel, dungeonID = nKeys[id].key_level, nKeys[id].dungeon_id
							nKeyString:SetWordWrap(false)
							nKeyString:SetFormattedText("|cffffd200Current Keystone|r\n%d - %s", keyLevel, e.GetMapName(dungeonID))
							nKeyString:SetWordWrap(true)
							nKeyString:SetPoint('TOP', characterNameString, 'BOTTOM', 3, -4)
							gameInfoString:SetPoint('TOP', nKeyString, 'BOTTOM', 0, 0)
							nKeyString:Show()
							stringShown = true
							FriendsTooltip.height = FriendsTooltip:GetHeight() + nKeyString:GetStringHeight() + 8
							FriendsTooltip.maxWidth = max(FriendsTooltip.maxWidth, nKeyString:GetStringWidth() + left)
						else
							nKeyString:SetText('')
							nKeyString:Hide()
							gameInfoString:SetPoint('TOP', characterNameString, 'BOTTOM', 0, -4)
						end
					end
				end
			else
				nKeyString:SetText('')
				nKeyString:Hide()
			end
		end
		
		FriendsTooltip:SetWidth(min(FRIENDS_TOOLTIP_MAX_WIDTH, FriendsTooltip.maxWidth + FRIENDS_TOOLTIP_MARGIN_WIDTH));
		FriendsTooltip:SetHeight(FriendsTooltip.height + (stringShown and 0 or (FRIENDS_TOOLTIP_MARGIN_WIDTH + 8)))
	end

	function OnHide()
		FriendsTooltipnKeysInfo1:SetText('')
		FriendsTooltipnKeysInfo1:Hide()
	end

	local buttons = FriendsListFrameScrollFrame.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		local oldOnEnter = button.OnEnter
		function button:OnEnter()
			oldOnEnter(self)
			OnEnter(self)
		end
		button:HookScript("OnEnter", OnEnter)
	end

	FriendsTooltip:HookScript('OnHide', OnHide)
	FriendsTooltip:HookScript('OnEnter', OnEnter)
	--hooksecurefunc('FriendsFrameTooltip_Show', OnEnter)
end

local function TooltipHook(self)
    if not nKeysSettings.general.show_tooltip_key.isEnabled then return end

    local _, uid = self:GetUnit()
    if not UnitIsPlayer(uid) then return end

    local unitName, unitRealm = UnitFullName(uid)
    unitRealm = ((unitRealm ~= '' and unitRealm) or GetRealmName()):gsub('%s+', '')
    local unit = string.format('%s-%s', unitName, (unitRealm or GetRealmName()):gsub('%s+', ''))

    local id = e.UnitID(unit)
    if id then
    	GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Current Keystone')
        GameTooltip:AddDoubleLine(e.GetMapName(e.UnitMapID(id)), e.UnitKeyLevel(id), 1, 1, 1, 1, 1, 1)
        return
    end

    local id = e.UnitID(unit)
    if id then
    	GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Current Keystone')
        GameTooltip:AddDoubleLine(e.GetMapName(nKeys[id].dungeon_id), nKeys[id].key_level, 1, 1, 1, 1, 1, 1)
        return
    end
end

GameTooltip:HookScript('OnTooltipSetUnit', TooltipHook)

local function FriendUnitFunction(self, unit, class, mapID, keyLevel, weekly_best, faction, btag)
	self.unitID = e.UnitID(unit)
	self.levelString:SetText(keyLevel)
	self.dungeonString:SetText(e.GetMapName(mapID))
	if weekly_best and weekly_best > 1 then
		local color_code = e.GetDifficultyColour(weekly_best)
		self.bestString:SetText(WrapTextInColorCode(weekly_best, color_code))
	else
		self.bestString:SetText(nil)
	end
	--self.weeklyTexture:SetShown(cache == 1)
	if btag then
		if tonumber(faction) == e.FACTION then
			self.nameString:SetText( string.format('%s (%s)', WrapTextInColorCode(btag:sub(1, btag:find('#') - 1), COLOR_BLUE_BNET), WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), select(4, GetClassColor(class)))))
		else
			self.nameString:SetText( string.format('%s (%s)', WrapTextInColorCode(btag:sub(1, btag:find('#') - 1), COLOR_BLUE_BNET), WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), 'ff9d9d9d')))
		end
	else
		self.nameString:SetText(WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), select(4, GetClassColor(class))))
	end
	if e.IsUnitOnline(unit) then
		self:SetAlpha(1)
	else
		self:SetAlpha(0.4)
	end
end

e.AddUnitFunction('FRIENDS', FriendUnitFunction)