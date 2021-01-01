local e, L = unpack(select(2, ...))

local nOptionsFrame = CreateFrame('FRAME', 'nOptionsFrame', UIParent)
nOptionsFrame:SetFrameStrata('DIALOG')
nOptionsFrame:SetFrameLevel(5)
nOptionsFrame:SetHeight(455)
nOptionsFrame:SetWidth(650)
nOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
nOptionsFrame:SetMovable(true)
nOptionsFrame:EnableMouse(true)
nOptionsFrame:RegisterForDrag('LeftButton')
nOptionsFrame:EnableKeyboard(true)
nOptionsFrame:SetPropagateKeyboardInput(true)
nOptionsFrame:SetClampedToScreen(true)
nOptionsFrame.background = nOptionsFrame:CreateTexture(nil, 'BACKGROUND')
nOptionsFrame.background:SetAllPoints(nOptionsFrame)
nOptionsFrame.background:SetColorTexture(0, 0, 0, 0.8)
nOptionsFrame:Hide()

local menuBar = CreateFrame('FRAME', '$parentMenuBar', nOptionsFrame)
menuBar:SetWidth(50)
menuBar:SetHeight(455)
menuBar:SetPoint('TOPLEFT', nOptionsFrame, 'TOPLEFT')
menuBar.texture = menuBar:CreateTexture(nil, 'BACKGROUND')
menuBar.texture:SetAllPoints(menuBar)
menuBar.texture:SetColorTexture(33/255, 33/255, 33/255, 0.8)

nOptionsFrame:SetScript('OnDragStart', function(self)
	self:StartMoving()
	end)

nOptionsFrame:SetScript('OnDragStop', function(self)
	self:StopMovingOrSizing()
	end)

local logo_Key = menuBar:CreateTexture(nil, 'ARTWORK')
logo_Key:SetSize(32, 32)
logo_Key:SetTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\key-white@2x')
logo_Key:SetVertexColor(0.8, 0.8, 0.8, 0.8)
logo_Key:SetPoint('TOPLEFT', menuBar, 'TOPLEFT', 10, -10)

local divider = menuBar:CreateTexture(nil, 'ARTWORK')
divider:SetSize(20, 1)
divider:SetColorTexture(.6, .6, .6, .8)
divider:SetPoint('TOP', logo_Key, 'BOTTOM', 0, -20)

local logo_n = menuBar:CreateTexture(nil, 'ARTWORK')
logo_n:SetAlpha(0.8)
logo_n:SetSize(32, 32)
logo_n:SetTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\Logo@2x')
logo_n:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)

local closeButton = CreateFrame('BUTTON', '$parentCloseButton', nOptionsFrame)
closeButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-close-24px@2x.tga')
closeButton:SetSize(12, 12)
closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
closeButton:SetScript('OnClick', function()
	nOptionsFrame:Hide()
end)
closeButton:SetPoint('TOPRIGHT', nOptionsFrame, 'TOPRIGHT', -14, -14)
closeButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
closeButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)

-- Content frame to anchor all option panels
-- 
local contentFrame = CreateFrame('FRAME', 'nFrame_OptionContent', nOptionsFrame)
contentFrame:SetPoint('TOPLEFT', menuBar, 'TOPRIGHT', 15, -15)
contentFrame:SetSize(550, 360)

local generalHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
generalHeader:SetText(L['GENERAL OPTIONS'])
generalHeader:SetPoint('TOPLEFT', contentFrame, 'TOPLEFT')

local showOffLine = e.CreateCheckBox(contentFrame, L['Show offline players'])
showOffLine:SetPoint('TOPLEFT', generalHeader, 'BOTTOMLEFT', 10, -10)
showOffLine:SetScript('OnClick', function(self)
	nKeysSettings.frame.show_offline.isEnabled = self:GetChecked()
	e.UpdateFrames()
	HybridScrollFrame_SetOffset(nKeyFrameListContainer, 0)
	end)

local showMinimap = e.CreateCheckBox(contentFrame, L['Show Minimap button'])
showMinimap:SetPoint('LEFT', showOffLine, 'RIGHT', 10, 0)
showMinimap:SetScript('OnClick', function(self)
	nKeysSettings.general.show_minimap_button.isEnabled = self:GetChecked()
	if nKeysSettings.general.show_minimap_button.isEnabled then
		e.icon:Show('nKeys')
	else
		e.icon:Hide('nKeys')
	end
	if IsAddOnLoaded('ElvUI_Enhanced') then -- Update the layout for the minimap buttons
		ElvUI[1]:GetModule('MinimapButtons'):UpdateLayout()
	end
	end)

local showTooltip = e.CreateCheckBox(contentFrame, L['Show current key in tooltip'])
showTooltip:SetPoint('TOPLEFT', showOffLine, 'BOTTOMLEFT', 0, -5)
showTooltip:SetScript('OnClick', function(self)
	nKeysSettings.general.show_tooltip_key.isEnabled = self:GetChecked()
	end)

local mingleOffline = e.CreateCheckBox(contentFrame, L['Display offline below online'])
mingleOffline:SetPoint('LEFT', showTooltip, 'RIGHT', 10, 0)
mingleOffline:SetScript('OnClick', function(self)
	nKeysSettings.frame.mingle_offline.isEnabled = not nKeysSettings.frame.mingle_offline.isEnabled
	e.UpdateFrames()
	end)

local announceParty = e.CreateCheckBox(contentFrame, L['Announce new keys to party'])
announceParty:SetPoint('TOPLEFT', showTooltip, 'BOTTOMLEFT', 0, -5)
announceParty:SetScript('OnClick', function(self)
	nKeysSettings.general.announce_party.isEnabled = not nKeysSettings.general.announce_party.isEnabled
	end)

local announceGuild = e.CreateCheckBox(contentFrame, L['Announce new keys to guild'])
announceGuild:SetPoint('LEFT', announceParty, 'RIGHT', 10, 0)
announceGuild:SetScript('OnClick', function(self)
	nKeysSettings.general.announce_guild.isEnabled = not nKeysSettings.general.announce_guild.isEnabled
	end)

local expandedTooltip = e.CreateCheckBox(contentFrame, L['EXPANDED_TOOLTIP'])
expandedTooltip:SetPoint('TOPLEFT', announceParty, 'BOTTOMLEFT', 0, -5)
expandedTooltip:SetScript('OnClick', function (self)
	nKeysSettings.general.expanded_tooltip.isEnabled = not nKeysSettings.general.expanded_tooltip.isEnabled
end)

local chatHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
chatHeader:SetText(L['!keys chat command'])
chatHeader:SetPoint('TOPLEFT', expandedTooltip, 'BOTTOMLEFT', -10, -20)

local chatDesc = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIRegular_Small')
chatDesc:SetText(L['!KEYS_DESC'])
chatDesc:SetPoint('TOPLEFT', chatHeader, 'BOTTOMLEFT', 5, -5)

local commandRespondParty = e.CreateCheckBox(contentFrame, L['PARTY'])
commandRespondParty:SetPoint('TOPLEFT', chatDesc, 'BOTTOMLEFT', 5, -10)
commandRespondParty:SetScript('OnClick', function (self)
	nKeysSettings.general.report_on_message['party'] = not nKeysSettings.general.report_on_message['party']
end)

local commandRespondGuild = e.CreateCheckBox(contentFrame, L['GUILD'])
commandRespondGuild:SetPoint('LEFT', commandRespondParty, 'RIGHT', 10, 0)
commandRespondGuild:SetScript('OnClick', function (self)
	nKeysSettings.general.report_on_message['guild'] = not nKeysSettings.general.report_on_message['guild']
end)

local commandRespondRaid = e.CreateCheckBox(contentFrame, L['RAID'])
commandRespondRaid:SetPoint('LEFT', commandRespondGuild, 'RIGHT', 10, 0)
commandRespondRaid:SetScript('OnClick', function (self)
	nKeysSettings.general.report_on_message['raid'] = not nKeysSettings.general.report_on_message['raid']
end)

local commandRespondNoKey = e.CreateCheckBox(contentFrame, L['KEYS_RESPOND_ON_NO_KEY'])
commandRespondNoKey:SetPoint('TOPLEFT', commandRespondParty, 'BOTTOMLEFT', 0, -5)
commandRespondNoKey:SetScript('OnClick', function (self)
	nKeysSettings.general.report_on_message['no_key'] = not nKeysSettings.general.report_on_message['no_key']
end)


local syncHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
syncHeader:SetText(L['SYNC OPTIONS'])
syncHeader:SetPoint('TOPLEFT', commandRespondNoKey, 'BOTTOMLEFT', -10, -20)

local syncFriends = e.CreateCheckBox(contentFrame, L['Sync with friends'])
syncFriends:SetPoint('TOPLEFT', syncHeader, 'BOTTOMLEFT', 10, -10)
syncFriends:SetScript('OnClick', function(self)
	nKeysSettings.friendOptions.friend_sync.isEnabled = self:GetChecked()
	nKeyFrame:ToggleLists()
	e.ToggleFriendSync()
	end)

local otherFaction = e.CreateCheckBox(contentFrame, L['Show other faction'])
otherFaction:SetPoint('LEFT', syncFriends, 'RIGHT', 10, 0)
otherFaction:SetScript('OnClick', function(self)
	nKeysSettings.friendOptions.show_other_faction.isEnabled = self:GetChecked()
	e.UpdateFrames()
	end)

local rankFilterHeader = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
rankFilterHeader:SetText(L['Rank Filter'])
rankFilterHeader:SetPoint('TOPLEFT', syncFriends, 'BOTTOMLEFT', -10, -20)

local filter_descript = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIRegular_Small')
filter_descript:SetText(L['Include these ranks in the guild listing'])
filter_descript:SetPoint('TOPLEFT', rankFilterHeader, 'BOTTOMLEFT', 5, -5)

local _ranks = {}
for i = 1, 10 do
	_ranks[i] = e.CreateCheckBox(contentFrame, ' ')
	_ranks[i].id = i
end

function InitializeOptionSettings()
	showMinimap:SetChecked(nKeysSettings.general.show_minimap_button.isEnabled)
	showTooltip:SetChecked(nKeysSettings.general.show_tooltip_key.isEnabled)
	announceParty:SetChecked(nKeysSettings.general.announce_party.isEnabled)
	announceGuild:SetChecked(nKeysSettings.general.announce_guild.isEnabled)
	expandedTooltip:SetChecked(nKeysSettings.general.expanded_tooltip.isEnabled)
	commandRespondParty:SetChecked(nKeysSettings.general.report_on_message['party'])
	commandRespondGuild:SetChecked(nKeysSettings.general.report_on_message['guild'])
	commandRespondRaid:SetChecked(nKeysSettings.general.report_on_message['raid'])
	commandRespondNoKey:SetChecked(nKeysSettings.general.report_on_message['no_key'])

	showOffLine:SetChecked(nKeysSettings.frame.show_offline.isEnabled)
	mingleOffline:SetChecked(nKeysSettings.frame.mingle_offline.isEnabled)

	syncFriends:SetChecked(nKeysSettings.friendOptions.friend_sync.isEnabled)
	otherFaction:SetChecked(nKeysSettings.friendOptions.show_other_faction.isEnabled)

	for i = 1, GuildControlGetNumRanks() do
		_ranks[i]:SetText(GuildControlGetRankName(i))

		for i = GuildControlGetNumRanks() + 1, 10 do
			_ranks[i]:Hide()
		end

		if i == 1 then
			_ranks[i]:SetPoint('TOPLEFT', filter_descript, 'BOTTOMLEFT', 5, -10)
		elseif (i % 3 == 1) then
			_ranks[i]:SetPoint('TOPLEFT', _ranks[i-3], 'BOTTOMLEFT', 0, -5)
		else
			_ranks[i]:SetPoint('LEFT', _ranks[i-1], 'RIGHT', 10, 0)
		end

		_ranks[i]:SetChecked(nKeysSettings.frame.rank_filter[i])

		_ranks[i]:SetScript('OnClick', function(self)
			nKeysSettings.frame.rank_filter[self.id] = self:GetChecked()
			if nKeysSettings.frame.list_shown == 'GUILD' then
				e.UpdateFrames()
			end
			end)
	end
end
nEvents:Register('PLAYER_LOGIN', InitializeOptionSettings, 'initOptions')

nOptionsFrame:SetScript('OnKeyDown', function(self, key)
	if key == 'ESCAPE' then
		self:SetPropagateKeyboardInput(false)
		nOptionsFrame:Hide()
	end
	end)

nOptionsFrame:SetScript('OnShow', function(self)
	self:SetPropagateKeyboardInput(true)

	showMinimap:SetChecked(nKeysSettings.general.show_minimap_button.isEnabled)
	showTooltip:SetChecked(nKeysSettings.general.show_tooltip_key.isEnabled)
	announceParty:SetChecked(nKeysSettings.general.announce_party.isEnabled)
	announceGuild:SetChecked(nKeysSettings.general.announce_guild.isEnabled)
	expandedTooltip:SetChecked(nKeysSettings.general.expanded_tooltip.isEnabled)
	commandRespondParty:SetChecked(nKeysSettings.general.report_on_message['party'])
	commandRespondGuild:SetChecked(nKeysSettings.general.report_on_message['guild'])
	commandRespondRaid:SetChecked(nKeysSettings.general.report_on_message['raid'])
	commandRespondNoKey:SetChecked(nKeysSettings.general.report_on_message['no_key'])

	showOffLine:SetChecked(nKeysSettings.frame.show_offline.isEnabled)
	mingleOffline:SetChecked(nKeysSettings.frame.mingle_offline.isEnabled)

	syncFriends:SetChecked(nKeysSettings.friendOptions.friend_sync.isEnabled)
	otherFaction:SetChecked(nKeysSettings.friendOptions.show_other_faction.isEnabled)
	end)