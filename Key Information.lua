local e, L = unpack(select(2, ...))
local strformat = string.format

local COLOUR = {}
COLOUR[1] = 'ffffffff' -- Common
COLOUR[2] = 'ff0070dd' -- Rare
COLOUR[3] = 'ffa335ee' -- Epic
COLOUR[4] = 'ffff8000' -- Legendary
COLOUR[5] = 'ffe6cc80' -- Artifact

e.MYTHICKEY_ITEMID = 158923

local MapIds = {}

local function UpdateWeekly()
	e.UpdateCharacterBest()
	local characterID = e.GetCharacterID(e.Player())
	local characterWeeklyBest = e.GetCharacterBestLevel(characterID)
	if IsInGuild() then
		nComs:NewMessage('nKeys', 'updateWeekly ' .. characterWeeklyBest, 'GUILD')
	else
		local id = e.UnitID(e.Player())
		if id then
			nKeys[id][5] = characterWeeklyBest
			e.UpdateFrames()
		end
	end
	e.UpdateCharacterFrames()
end

-- Blizzard has the same event being triggered for requesting the map information and the current M+ rewards. 
local rewardsRequested = false
local function InitData()
	MapIds = C_ChallengeMode.GetMapTable()
	if not rewardsRequested then
		rewardsRequested = true
		C_MythicPlus.RequestRewards()
		return
	end
	nEvents:Unregister('CHALLENGE_MODE_MAPS_UPDATE', 'initData')
	C_ChatInfo.RegisterAddonMessagePrefix('nKeys')
	e.FindKeyStone(true, false)
	e.UpdateCharacterBest() 	
	if IsInGuild() then
		nComs:NewMessage('nKeys', 'request', 'GUILD')
	end

	if UnitLevel('player') < e.EXPANSION_LEVEL then return end
	nEvents:Register('CHALLENGE_MODE_MAPS_UPDATE', UpdateWeekly, 'weeklyCheck')
end
nEvents:Register('CHALLENGE_MODE_MAPS_UPDATE', InitData, 'initData')

--|cffa335ee|Hkeystone:158923:251:12:10:5:13:117|h[Keystone: The Underrot (12)]|h|r
-- COLOUR[3] returns epic color hex code
function e.CreateKeyLink(mapID, keyLevel)
	local mapName
	if mapID == 369 or mapID == 370 then
		mapName = C_ChallengeMode.GetMapUIInfo(mapID)		
	else
		mapName = e.GetMapName(mapID)
	end
	return strformat('|c' .. COLOUR[3] .. '|Hkeystone:158923:%d:%d:%d:%d:%d:%d|h[Keystone: %s (%d)]|h|r', mapID, keyLevel, e.AffixOne(), e.AffixTwo(), e.AffixThree(), e.AffixFour(), mapName, keyLevel):gsub('\124\124', '\124')
end

nEvents:Register('CHALLENGE_MODE_COMPLETED', function()
	C_Timer.After(3, function()
		C_MythicPlus.RequestRewards()
		e.FindKeyStone(true, true)
	end)
end, 'dungeonCompleted')

local function ParseLootMsgForKey(...)
	local msg = ...
	local unit = select(5, ...)
	if not unit == e.PlayerName() then return end

	if string.lower(msg):find('keystone') then -- Look a key, let's bind a function to bag_update event to find that key
		nEvents:Register('BAG_UPDATE', function()
			e.FindKeyStone(true, true)
			nEvents:Unregister('BAG_UPDATE', 'bagUpdate')
			nEvents:Unregister('CHAT_MSG_LOOT', 'lootCheck')
			end, 'bagUpdate')
	end
end

function e.FindKeyStone(sendUpdate, anounceKey)
	if UnitLevel('player') < e.EXPANSION_LEVEL then return end

	local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
	local weeklyBest = 0
	local isChestAvailable = C_MythicPlus.IsWeeklyRewardAvailable()
	

	local runHistory = C_MythicPlus.GetRunHistory(false, true)


	for i = 1, #runHistory do
		if runHistory[i].thisWeek then
			if runHistory[i].level > weeklyBest then
				weeklyBest = runHistory[i].level
			end
		end
	end

	local msg = ''

	if mapID then 
		msg = string.format('%s:%s:%d:%d:%d:%d:%s', e.Player(), e.PlayerClass(), mapID, keyLevel, weeklyBest, e.Week, e.FACTION)
	end

	if not mapID and not nEvents:IsRegistered('CHAT_MSG_LOOT', 'loot_msg_parse') then
		nEvents:Register('CHAT_MSG_LOOT', ParseLootMsgForKey, 'loot_msg_parse')
	end

	local oldMap, oldLevel = e.UnitMapID(e.UnitID(e.Player())), e.UnitKeyLevel(e.UnitID(e.Player()))

	-- Key found, unregister function, no longer needed
	if mapID and nEvents:IsRegistered('BAG_UPDATE', 'bagUpdate') then
		nEvents:Unregister('BAG_UPDATE', 'bagUpdate')
	end

	if sendUpdate and msg ~= '' then
		e.PushKeyDataToFriends(msg)
		if IsInGuild() then
			nComs:NewMessage('nKeys', strformat('%s %s', e.UPDATE_VERSION, msg), 'GUILD')
		else -- Not in a guild, who are you people? Whatever, gotta make it work for them as well
			local id = e.UnitID(e.Player())
			if id then -- Are we in the DB already?
				nKeys[id][3] = tonumber(mapID)
				nKeys[id][4] = tonumber(keyLevel)
				nKeys[id][6] = e.Week
				nKeys[id][7] = e.WeekTime()
			else -- Nope, ok, let's add them to the DB manually.
				nKeys[#nKeys + 1] = {e.Player(), e.PlayerClass(), tonumber(mapID), tonumber(keyLevel), e.Week, e.WeekTime()}
				e.SetUnitID(e.Player(), #nKeys)
			end
		end
	end
	msg = nil

	-- Ok, time to check if we need to announce a new key or not
	if tonumber(oldMap) == tonumber(mapID) and tonumber(oldLevel) == tonumber(keyLevel) then return end

	if anounceKey then
		e.AnnounceNewKey(e.CreateKeyLink(mapID, keyLevel))
	end
end

-- Finds best map clear fothe week for logged on character. If character already is in database
-- updates the information, else creates new entry for character
function e.UpdateCharacterBest()
	if UnitLevel('player') < e.EXPANSION_LEVEL then return end

	local weeklyBest = 0
	local runHistory = C_MythicPlus.GetRunHistory(false, true)


	for i = 1, #runHistory do
		if runHistory[i].thisWeek then
			if runHistory[i].level > weeklyBest then
				weeklyBest = runHistory[i].level
			end
		end
	end

	local found = false

	for i = 1, #nCharacters do
		if nCharacters[i].unit == e.Player() then
			found = true
			nCharacters[i].weekly_best = weeklyBest
			break
		end
	end

	if not found then
		table.insert(nCharacters, {unit = e.Player(), class = e.PlayerClass(), weekly_best = weeklyBest, faction = e.FACTION})
		e.SetCharacterID(e.Player(), #nCharacters)
	end
end

local function MythicPlusStart()
	e.FindKeyStone(true, false)
end

nEvents:Register('CHALLENGE_MODE_START', MythicPlusStart, 'PlayerEnteredMythic')

function e.GetDifficultyColour(keyLevel)
	if type(keyLevel) ~= 'number' then return COLOUR[1] end -- return white for any strings or non-number values
	if keyLevel <= 4 then
		return COLOUR[1]
	elseif keyLevel <= 9 then
		return COLOUR[2]
	elseif keyLevel <= 14 then
		return COLOUR[3]
	elseif keyLevel <= 19 then
		return COLOUR[4]
	else
		return COLOUR[5]
	end
end