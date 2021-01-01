local e, L = unpack(select(2, ...))

-- MixIns
nKeysCharacterMixin = {}
nKeysListMixin = {}
-- Red color code
-- #C72329

-- Background
-- Left #000000 ALPHA 0.8
-- Right #212121 ALPHA 0.8
local COLOR_GRAY = 'ff9d9d9d'
local COLOR_BLUE_BNET = 'ff82c5ff'

-- Scroll bar texture alpha settings
local SCROLL_TEXTURE_ALPHA_MIN = 0.25
local SCROLL_TEXTURE_ALPHA_MAX = 0.6

local FRAME_WIDTH_EXPANDED = 725
local FRAME_WIDTH_MINIMIZED = 500

local FILTER_FIELDS = {}
FILTER_FIELDS['key_level'] = ''
FILTER_FIELDS['mapID'] = ''
FILTER_FIELDS['character_name'] = ''

local BACKDROPBUTTON = {
bgFile = nil,
edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16, edgeSize = 1,
insets = {left = 0, right = 0, top = 0, bottom = 0}
}
-- Used for filtering, sorting, and displaying units on lists
local sortTable = {}
sortTable.num_shown = 0

local selectedUnits = {}

local CreateNewTab, UpdateTabs, RemoveTab, tabFrame

local function ClearSelectedUnits()
	wipe(selectedUnits)
end

function nKeysCharacterMixin:UpdateUnit(characterID)
	local unit = e.CharacterName(characterID)
	local realm = e.CharacterRealm(characterID)
	local unitClass = e.GetCharacterClass(characterID)

	local bestKey = e.GetCharacterBestLevel(characterID)
	local currentMapID = e.GetCharacterMapID(unit .. '-' .. realm)
	local currentKeyLevel = e.GetCharacterKeyLevel(unit .. '-' .. realm)

	if e.CharacterRealm(characterID) ~= e.PlayerRealm() then
		unit = unit .. ' (*)'
	end
	self.nameString:SetText(WrapTextInColorCode(unit, select(4, GetClassColor(unitClass))))

	if bestKey ~= 0 then
		self.weeklyStringValue:SetText(bestKey)
	else
		self.weeklyStringValue:SetText(WrapTextInColorCode(L['CHARACTER_DUNGEON_NOT_RAN'], COLOR_GRAY))
	end

	if currentMapID then
		self.keyStringValue:SetFormattedText('%d %s', currentKeyLevel, e.GetMapName(currentMapID))
	else
		self.keyStringValue:SetFormattedText('|c%s%s|r', COLOR_GRAY, L['CHARACTER_KEY_NOT_FOUND'])
	end
end

function nKeysCharacterMixin:OnEnter()
	local scrollBar = self:GetParent():GetParent().scrollBar
	local scrollButton = _G[scrollBar:GetName() .. 'ThumbTexture']
	scrollButton:SetAlpha(SCROLL_TEXTURE_ALPHA_MAX)
end

function nKeysCharacterMixin:OnLeave()
	local scrollBar = self:GetParent():GetParent().scrollBar
	local scrollButton = _G[scrollBar:GetName() .. 'ThumbTexture']
	scrollButton:SetAlpha(SCROLL_TEXTURE_ALPHA_MIN)
end

function nKeysCharacterMixin:OnLoad()
	self.weeklyString:SetText(L['WEEKLY_BEST'])
	self.keyString:SetText(L['CURRENT_KEY'])
end

function nKeysListMixin:SetUnit(unit, class, mapID, keyLevel, weekly_best, faction, btag)
	self.unitID = e.UnitID(unit)
	self.levelString:SetText(keyLevel)
	self.dungeonString:SetText(e.GetMapName(mapID))
	if weekly_best and weekly_best > 1 then
		local color_code = e.GetDifficultyColour(weekly_best)
		self.bestString:SetText(WrapTextInColorCode(weekly_best, color_code))
	else
		self.bestString:SetText(nil)
	end

	if e.FrameListShown() == 'GUILD' then
		self.nameString:SetText(WrapTextInColorCode(Ambiguate(unit, 'GUILD'), select(4, GetClassColor(class))))
	else
		if btag then
			if tonumber(faction) == e.FACTION then
				self.nameString:SetText( string.format('%s (%s)', WrapTextInColorCode(btag:sub(1, btag:find('#') - 1), COLOR_BLUE_BNET), WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), select(4, GetClassColor(class)))))
			else
				self.nameString:SetText( string.format('%s (%s)', WrapTextInColorCode(btag:sub(1, btag:find('#') - 1), COLOR_BLUE_BNET), WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), 'ff9d9d9d')))
			end
		else
			self.nameString:SetText(WrapTextInColorCode(unit:sub(1, unit:find('-') - 1), select(4, GetClassColor(class))))
		end
	end
	
	if e.IsUnitOnline(unit) then
		self:SetAlpha(1)
	else
		self:SetAlpha(0.4)
	end
end

function nKeysListMixin:OnClick(button)
	if not IsModifierKeyDown() and button == 'RightButton' then
		wipe(selectedUnits)
		if nMenuFrameUnit1.unit == self.unitID then
			ToggleFrame(nMenuFrameUnit1)
		else
			nMenuFrameReport1:Hide()
			--nMenuFrameTabs1:Hide()
			--nMenuFrameTabs2:Hide()
			nMenuFrameUnit2:Hide()
			nMenuFrameUnit1:ClearAllPoints()
			local uiScale = UIParent:GetScale()

			local cursorX, cursorY = GetCursorPosition()
			local left, bottom, width, height = nKeyFrame:GetRect()
			cursorX = cursorX/uiScale
			cursorY =  cursorY/uiScale
			xOffset, yOffset = 20, 0

			xOffset = cursorX + xOffset
			yOffset = cursorY + yOffset

			nMenuFrameUnit1:SetUnit(self.unitID)
			nMenuFrameUnit1:SetTitle(WrapTextInColorCode(e.UnitName(self.unitID), select(4, GetClassColor(e.UnitClass(self.unitID)))))
			nMenuFrameUnit1:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', xOffset, yOffset)
			nMenuFrameUnit1:Show()
			selectedUnits[e.Unit(self.unitID)] = true
		end
	elseif IsModifierKeyDown() then
		self.Highlight:SetShown(not self.Highlight:IsShown())

		if self.Highlight:IsShown() then
			selectedUnits[e.Unit(self.unitID)] = true
		else
			selectedUnits[e.Unit(self.unitID)] = nil
		end
	end
end

function nKeysListMixin:OnEnter()
	local scrollBar = self:GetParent():GetParent().scrollBar
	local scrollButton = _G[scrollBar:GetName() .. 'ThumbTexture']
	scrollButton:SetAlpha(SCROLL_TEXTURE_ALPHA_MAX)
end

function nKeysListMixin:OnLeave()
	local scrollBar = self:GetParent():GetParent().scrollBar
	local scrollButton = _G[scrollBar:GetName() .. 'ThumbTexture']
	scrollButton:SetAlpha(SCROLL_TEXTURE_ALPHA_MIN)
end

-- Unit dropdown mneu items, whisper and invite
local unitPopup = e.CreateDropDownFrame('Unit', 1, UIParent)
local subUnitPopup = e.CreateDropDownFrame('Unit', 2, UIParent)
subUnitPopup:SetTitle(L['LIST'])

unitPopup:SetScript('OnHide', function(self)
	wipe(selectedUnits)
	self:SetUnit(nil)
	local buttons = nKeyFrameListContainer.buttons
	for _, button in pairs(buttons) do
		button.Highlight:Hide()
	end
end)

local function Whisper_OnShow(self)
	if not e.IsUnitOnline(e.Unit(nMenuFrameUnit1.unit)) then
		self:SetText(WrapTextInColorCode(self:GetText(), 'ff9d9d9d'))
	else
		self:SetText(L['Whisper'])
	end
end
-- AddButton(name, onClick, onShow, onEnter, subMenu, subFrame)

local function SendWhisper(self)
	if not e.IsUnitOnline(e.Unit(nMenuFrameUnit1.unit)) then return end
	if e.UnitBTag(nMenuFrameUnit1.unit) then
		ChatFrame_SendBNetTell(e.FriendPresName(e.Unit(nMenuFrameUnit1.unit)))
	else
		ChatFrame_SendTell(e.Unit(nMenuFrameUnit1.unit))
	end
end
unitPopup:AddButton(L['Whisper'], SendWhisper, Whisper_OnShow)

local function Invite_OnShow(self)
	local inviteType = GetDisplayedInviteType(e.UnitGUID(e.Unit(nMenuFrameUnit1.unit)))

	self:SetText(L[inviteType])
	self:GetParent():AdjustWidth()
	if not e.IsUnitOnline(e.Unit(nMenuFrameUnit1.unit)) then
		self:SetText(WrapTextInColorCode(self:GetText(), 'ff9d9d9d'))
	end

	self.inviteType = inviteType
end

local function InviteUnit(self)
	if not e.IsUnitOnline(e.Unit(nMenuFrameUnit1.unit)) then return end
	
	if e.UnitBTag(nMenuFrameUnit1.unit) then
		if self.inviteType == 'INVITE' then
			BNInviteFriend(e.GetFriendGaID(e.Unit(nMenuFrameUnit1.unit)))
		elseif self.inviteType == 'REQUEST_INVITE' then
			BNRequestInviteFriend(e.GetFriendGaID(e.Unit(nMenuFrameUnit1.unit)))
		elseif self.inviteType == 'SUGGEST_INVITE' then
			BNInviteFriend(e.GetFriendGaID(e.Unit(nMenuFrameUnit1.unit)))
		end
	else
		if self.inviteType == 'INVITE' then
			InviteToGroup(e.Unit(nMenuFrameUnit1.unit))
		elseif self.inviteType == 'REQUEST_INVITE' then
			RequestInviteFromUnit(e.Unit(nMenuFrameUnit1.unit))
		elseif self.inviteType == 'SUGGEST_INVITE' then
			InviteToGroup(e.Unit(nMenuFrameUnit1.unit))
		end
	end
end
unitPopup:AddButton(L['INVITE'],InviteUnit, Invite_OnShow)

local function CreateList_OnEnter(self)
	local text = self:GetText()

	if text == '' then return end

	local list = e.CreateNewList(text)

	CreateNewTab(text, tabFrame)
	UpdateTabs()

	if list then
		for unit in pairs(selectedUnits) do
			e.AddUnitToList(unit, text)
		end
	end

	self:Hide()
	self.buttonParent:Show()
	unitPopup:Hide()
	subUnitPopup:Hide()
	--nMenuFrameTabs1:Hide()
	--nMenuFrameTabs2:Hide()
end

local createListEditBox = CreateFrame('EditBox', nil, UIParent, "BackdropTemplate")
createListEditBox:SetFrameStrata('TOOLTIP')
createListEditBox:SetFrameLevel(25)
createListEditBox:Hide()
createListEditBox:SetSize(150, 20)
createListEditBox:SetFontObject(InterUIRegular_Normal)
createListEditBox:SetAutoFocus(true)
createListEditBox:SetMaxLetters(50)
createListEditBox:SetBackdrop(BACKDROPBUTTON)
createListEditBox:SetBackdropBorderColor(33/255, 33/255, 33/255, 0.8)

createListEditBox.description = createListEditBox:CreateFontString(nil, 'OVERLAY', 'InterUIMedium_Normal')
createListEditBox.description:SetHeight(20)
createListEditBox.description:SetJustifyH('LEFT')
createListEditBox.description:SetText(L['NEW_LIST_DESCRIPTION'])
createListEditBox.description:SetTextColor(99/255, 99/255, 99/255, 1)
createListEditBox.description:SetPoint('LEFT', createListEditBox, 'LEFT', 3, 0)
createListEditBox.description:Hide()

local createListOkayButton = CreateFrame('BUTTON', nil, createListEditBox, "BackdropTemplate")
createListOkayButton:SetNormalFontObject(InterUIMedium_Normal)
createListOkayButton:SetBackdrop(BACKDROPBUTTON)
createListOkayButton:SetBackdropBorderColor(33/255, 33/255, 33/255, 0.8)
createListOkayButton:SetHeight(20)
createListOkayButton:SetText(L['OKAY'])
createListOkayButton:GetFontString():SetTextColor(198/255, 198/255, 198/255, 1)
createListOkayButton:SetWidth(createListOkayButton:GetFontString():GetUnboundedStringWidth() + 5)
createListOkayButton:SetPoint('LEFT', createListEditBox, 'RIGHT', 5, 0)

createListOkayButton:SetScript('OnClick', function()
	CreateList_OnEnter(createListEditBox)
end)

createListEditBox:SetScript('OnTextChanged', function(self)
	if not self:GetText() or self:GetText() ~= '' then
		self.description:Hide()
	else
		self.description:Show()
	end
end)

createListEditBox:SetScript('OnShow', function(self)
	self:SetText('')
	self.description:Show()
	self.description:SetWidth(self.description:GetUnboundedStringWidth())
	self:SetWidth(self.description:GetUnboundedStringWidth() + 5)
end)

createListEditBox:SetScript('OnEscapePressed', function(self)
	self:Hide()
	self.buttonParent:Show()
	self.buttonParent:GetParent():AdjustWidth()
end)

createListEditBox:SetScript('OnEnterPressed', CreateList_OnEnter)

local function CreateList(self)
	createListEditBox:Hide()
	createListEditBox.buttonParent = self
	createListEditBox:ClearAllPoints()
	createListEditBox:SetPoint('LEFT', self, 'LEFT')
	createListEditBox:Show()
	self:GetParent():AdjustWidth(math.max(createListEditBox:GetWidth(), createListEditBox.description:GetUnboundedStringWidth()) + createListOkayButton:GetWidth())
	--self:GetParent():AdjustWidth()
	self:Hide()
end

local function BuildLists(frame)
	frame:ClearButtons()
	for i = 1, #nLists do
		if nLists[i].name ~= 'GUILD' and nLists[i].name ~= 'FRIENDS' then
			frame:AddButton(nLists[i].name, function(self)
				for unit in pairs(selectedUnits) do
					local unit = unit
					local btag e.UnitBTag(e.UnitID(unit))
					local list = self:GetText()
					e.AddUnitToList(unit, list, btag)
				end
			end, nil, nil, nil)
		end
	end
	local newListButton = frame:AddButton(L['CREATE_NEW_LIST'], CreateList)
	newListButton:SetScript('OnClick', function(self)
		CreateList(self)
	end)
end

--unitPopup:AddButton(L['ADD_TO_LIST'], nil, nil, function() BuildLists(subUnitPopup) end, true, subUnitPopup)

local function RemoveUnitsFromList()
	if e.FrameListShown() == 'GUILD' or e.FrameListShown() == 'FRIENDS' then return end
	local list = e.FrameListShown()
	for unit in pairs(selectedUnits) do
		e.RemoveUnitFromList(unit, list)
	end
	e.UpdateSortTable()
	e.UpdateFrames()
end

local function RemoveUnit_OnShow(self)
	if e.FrameListShown() == 'GUILD' or e.FrameListShown() == 'FRIENDS' then
		self:SetText(WrapTextInColorCode(self:GetText(), 'ff9d9d9d'))
	else
		self:SetText(L['REMOVE_UNIT_FROM_LIST'])
	end
end

--unitPopup:AddButton(L['REMOVE_UNIT_FROM_LIST'], RemoveUnitsFromList, RemoveUnit_OnShow)


unitPopup:AddButton(L['CANCEL'])

local nKeyFrame = CreateFrame('FRAME', 'nKeyFrame', UIParent)
nKeyFrame:SetFrameStrata('DIALOG')
nKeyFrame:SetWidth(715)
nKeyFrame:SetHeight(490)
nKeyFrame:SetPoint('CENTER', UIParent, 'CENTER')
nKeyFrame:EnableMouse(true)
nKeyFrame:SetMovable(true)
nKeyFrame:RegisterForDrag('LeftButton')
nKeyFrame:EnableKeyboard(true)
nKeyFrame:SetPropagateKeyboardInput(true)
nKeyFrame:SetClampedToScreen(true)
nKeyFrame:Hide()
nKeyFrame.updateDelay = 0
nKeyFrame.background = nKeyFrame:CreateTexture(nil, 'BACKGROUND')
nKeyFrame.background:SetAllPoints(nKeyFrame)
nKeyFrame.background:SetColorTexture(0, 0, 0, 0.8)

local nKeyToolTip = CreateFrame( "GameTooltip", "nKeyToolTip", AAFrame, "GameTooltipTemplate" )
nKeyToolTip:SetOwner(nKeyFrame, "ANCHOR_CURSOR")
nKeyToolTip:SetScript('OnShow', function(self)
	self:SetBackdrop({
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16, edgeSize = 1,
					insets = {left = 0, right = 0, top = 0, bottom = 0}
					})
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0)
end)

-- Skin the tooltip.
for i = 1, 2 do
	_G['nKeyToolTipTextRight' .. i]:SetFontObject(InterUIBold_Tiny)
	_G['nKeyToolTipTextLeft' .. i]:SetFontObject(InterUIBold_Tiny)
end

local offLineButton = e.CreateCheckBox(nKeyFrame, SHOW_OFFLINE_MEMBERS, 150)
offLineButton:SetNormalFontObject(InterUIRegular_Small)
offLineButton:SetPoint('BOTTOMRIGHT', nKeyFrame, 'BOTTOMRIGHT', -15, 10)
offLineButton:SetAlpha(0.5)
offLineButton:SetScript('OnClick', function(self)
	nKeysSettings.frame.show_offline.isEnabled = self:GetChecked()
	HybridScrollFrame_SetOffset(nKeyFrameListContainer, 0)
	e.UpdateFrames()
end)

local menuBar = CreateFrame('FRAME', '$parentMenuBar', nKeyFrame)
menuBar:SetSize(50, 490)
menuBar:SetPoint('TOPLEFT', nKeyFrame, 'TOPLEFT')
menuBar.texture = menuBar:CreateTexture(nil, 'BACKGROUND')
menuBar.texture:SetAllPoints(menuBar)
menuBar.texture:SetColorTexture(33/255, 33/255, 33/255, 0.8)

local logo_Key = menuBar:CreateTexture(nil, 'ARTWORK')
logo_Key:SetSize(32, 32)
logo_Key:SetTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\key-white@2x')
logo_Key:SetVertexColor(0.8, 0.8, 0.8, 0.8)
logo_Key:SetPoint('TOPLEFT', menuBar, 'TOPLEFT', 10, -10)

local divider = menuBar:CreateTexture(nil, 'ARTWORK')
divider:SetSize(20, 1)
divider:SetColorTexture(.6, .6, .6, .8)
divider:SetPoint('TOP', logo_Key, 'BOTTOM', 0, -20)

-- Report Key(s) to party/guild popup menu
local reportFrame = e.CreateDropDownFrame('Report', 1, UIParent)
reportFrame:SetTitle(L['REPORT_TO'])
reportFrame:AddButton(L['PARTY'], function() e.AnnounceCharacterKeys('PARTY') end)
reportFrame:AddButton(L['GUILD'], function() e.AnnounceCharacterKeys('GUILD') end)
reportFrame:AddButton(L['CANCEL'])

local reportButton = CreateFrame('BUTTON', '$parentReportButton', menuBar)
reportButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-volume_up-24px@2x')
reportButton:SetSize(20, 20)
reportButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
reportButton:SetPoint('TOP', divider, 'BOTTOM', 0, -20)
reportButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
reportButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)
reportButton:SetScript('OnClick', function(self)
	nMenuFrameUnit1:Hide()
	nMenuFrameUnit2:Hide()
	--nMenuFrameTabs1:Hide()
	--nMenuFrameTabs2:Hide()
	nMenuFrameReport1:SetPoint('TOPLEFT', self, 'TOPRIGHT', 10, -3)
	nMenuFrameReport1:SetShown( not nMenuFrameReport1:IsShown())
	end)

local settingsButton = CreateFrame('BUTTON', '$parentSettingsButton', menuBar)
settingsButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-settings-20px@2x')
settingsButton:SetSize(24, 24)
settingsButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
settingsButton:SetPoint('TOP', reportButton, 'BOTTOM', 0, -20)
settingsButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
settingsButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)
settingsButton:SetScript('OnClick', function()
	nMenuFrameUnit1:Hide()
	nOptionsFrame:SetShown( not nOptionsFrame:IsShown())
	end)

local logo_n = CreateFrame('BUTTON', nil, menuBar)
logo_n:SetSize(32, 32)
logo_n:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)
logo_n:SetAlpha(0.8)
logo_n:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\nKeyslogo.')

logo_n:SetScript('OnClick', function()
	nGuildInfo:SetShown(not nGuildInfo:IsShown())
	end)

logo_n:SetScript('OnEnter', function(self)
	self:SetAlpha(1)
	end)

logo_n:SetScript('OnLeave', function(self)
	self:SetAlpha(0.8)
	end)

local collapseButton = CreateFrame('BUTTON', '$parentCollapseButton', menuBar)
collapseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-last_page-24px@2x')
collapseButton:SetSize(20, 20)
collapseButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
collapseButton:SetPoint('BOTTOM', logo_n, 'TOP', 0, 20)
collapseButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
collapseButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)

---- List Buttons
-----------------------------------
local closeButton = CreateFrame('BUTTON', '$parentCloseButton', nKeyFrame)
closeButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-close-24px@2x')
closeButton:SetSize(12, 12)
closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
closeButton:SetScript('OnClick', function()
	nKeyFrame:Hide()
end)
closeButton:SetPoint('TOPRIGHT', nKeyFrame, 'TOPRIGHT', -14, -14)
closeButton:SetScript('OnEnter', function(self)
	self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8)
end)
closeButton:SetScript('OnLeave', function(self)
	self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
end)

-- Tab bar at the top, only show 5 and then start scrolling

-- MenuBar 50px
-- Middle Frame 215px
tabFrame = CreateFrame('FRAME', '$parentTabFrame', nKeyFrame)
tabFrame.offSet = 0
tabFrame:SetSize(420, 45)
tabFrame:SetPoint('TOPRIGHT', nKeyFrame, 'TOPRIGHT', -30, 0)
--tabFrame.t = tabFrame:CreateTexture(nil, 'ARTWORK')
--tabFrame.t:SetAllPoints(tabFrame)
--tabFrame.t:SetColorTexture(0, .5, 1)
tabFrame.buttons = {}
--[[
local newTabButton = CreateFrame('BUTTON', '$parentNewListButton', tabFrame)
newTabButton:SetSize(17, 17)
newTabButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_add_white_18dp')
newTabButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
newTabButton:SetPoint('RIGHT', tabFrame, 'RIGHT')

newTabButton:SetScript('OnClick', function(self)
	nMenuFrameUnit1:Hide()
	nMenuFrameUnit2:Hide()
	nMenuFrameReport1:Hide()
	--nMenuFrameTabs2:Hide()
	--nMenuFrameTabs1:SetPoint('TOPLEFT', self, 'TOPRIGHT', 10, -3)
	--nMenuFrameTabs1:SetShown(not nMenuFrameTabs1:IsShown())
end)
]]
-- Use arrows to display lists are on either side of curent offset
--[[
local tabFrameLeftButton = CreateFrame('BUTTON', '$parentLeftButton', tabFrame)
tabFrameLeftButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_keyboard_arrow_left_white_18dp')
tabFrameLeftButton:SetSize(12, 12)
tabFrameLeftButton:SetPoint('LEFT', tabFrame, 'LEFT', 10, -4)
tabFrameLeftButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
tabFrameLeftButton:SetScript('OnClick', function(self)
	if self:GetParent().offSet < 1 then
		return
	else
		self:GetParent().offSet = self:GetParent().offSet - 1
		UpdateTabs()
	end
end)

local tabFrameRightButton = CreateFrame('BUTTON', '$parentLeftButton', tabFrame)
tabFrameRightButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_keyboard_arrow_right_white_24dp')
tabFrameRightButton:SetSize(12, 12)
tabFrameRightButton:SetPoint('RIGHT', tabFrame, 'RIGHT', -5, -4)
tabFrameRightButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
tabFrameRightButton:SetScript('OnClick', function(self)
	if self:GetParent().buttons[#self:GetParent().buttons]:IsShown() then
	--if self:GetParent().offSet >= #self:GetParent().buttons then
		return
	else
		self:GetParent().offSet = self:GetParent().offSet + 1
		UpdateTabs()
	end
end)
]]
function UpdateTabs()
	local buttons = nKeyFrameTabFrame.buttons
	local offSet = nKeyFrameTabFrame.offSet

	local maxPossibleWidth = 410 - 15 - 20 -- Tab frame, close button, new tab button width
	local usedWidth = 0 -- initialize at 10 for padding on the left
	local buttonsUsed = 0

	for i = 1, #buttons do
		buttons[i]:ClearAllPoints()
		buttons[i]:Hide()
	end

	for i = 1 + offSet, #buttons do
		if e.FrameListShown() == buttons[i].listName then
			buttons[i].underline:Show()
			buttons[i]:SetAlpha(1)
		else
			buttons[i].underline:Hide()
			buttons[i]:SetAlpha(0.5)
		end
		if i == 1 + offSet then
			usedWidth = usedWidth + buttons[i]:GetWidth() + 10 -- Padding between buttons
			buttons[i]:SetPoint('TOPLEFT', nKeyFrameTabFrame, 'TOPLEFT', 25, -17)
			buttons[i]:Show()
		else
			usedWidth = usedWidth + buttons[i]:GetWidth() + 10 -- Padding between buttons
			if usedWidth <= maxPossibleWidth then
				buttons[i]:SetPoint('LEFT', buttons[i-1], 'RIGHT', 10, 0)
				buttons[i]:Show()
				buttonsUsed = i
			end
		end
	end
	--newTabButton:ClearAllPoints()
	--newTabButton:SetPoint('LEFT', buttons[buttonsUsed], 'RIGHT', 10, 2)
end

local function Tab_OnClick(self, button)
	if button == 'LeftButton' then
		C_FriendList.ShowFriends()
	    if e.FrameListShown() ~= self.listName then
	    	ClearSelectedUnits()
	        e.SetFrameListShown(self.listName)
	        HybridScrollFrame_SetOffset(nKeyFrameListContainer, 0)
	        UpdateTabs()
			e.UpdateSortTable()
	        e.UpdateFrames()
	        nKeyFrameListContainer.scrollBar:SetValue(0)
	    end
	end
end

function CreateNewTab(name, parent, ...)
	if not name or type(name) ~= 'string' then
		error('CreateNewTab(name, parent, ...) name: string expected, received ' .. type(name))
	end
	local buttons = parent.buttons
	local self = CreateFrame('BUTTON', '$parentTab' .. name, parent)
	self:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	self.listName = name
	self:SetNormalFontObject(InterUIBlack_Small)
	self:SetText(L[name])
	self:GetFontString():SetJustifyH('CENTER')
	self:SetWidth(50)
	self:SetHeight(15)
	self:SetScript('OnClick', function(self, button) Tab_OnClick(self, button) end)

	local textWidth = self:GetFontString():GetUnboundedStringWidth()
	self:SetWidth(textWidth + 10)
	self.underline = self:CreateTexture(nil, 'ARTWORK')
	self.underline:SetSize(textWidth, 2)
	self.underline:SetColorTexture(214/255, 38/255, 38/255)
	self.underline:SetPoint('BOTTOM', self, 'BOTTOM', 0, -1)

	self.underline:Hide()

	table.insert(buttons, self)
end

function RemoveTab(name)
	if not name or type(name) ~= 'string' then
		error('RemoveTab(name) name: string expected, received ' .. type(name))
	end
	local buttons = nKeyFrameTabFrame.buttons

	local targetName = 'nKeyFrameTabFrameTab' .. name

	for i = 1, #buttons do
		if buttons[i]:GetName() == targetName then
			local btn = table.remove(buttons, i)
			btn:Hide()
			btn:SetParent(nil)
			break
		end
	end
end
--[[
local tabPopup = e.CreateDropDownFrame('Tabs', 1, UIParent)
tabPopup:SetTitle(L['ADD_REMOVE_LIST'])
local subTabPopup = e.CreateDropDownFrame('Tabs', 2, UIParent)
subTabPopup:SetTitle(L['DELETE_LIST'])
local tabFrameNewListButton = tabPopup:AddButton(L['CREATE_NEW_LIST'], CreateList)

tabFrameNewListButton:SetScript('OnClick', CreateList)
]]
local function RemoveList(frame)
	frame:ClearButtons()
	for i = 1, #nLists do
		if nLists[i].name ~= 'GUILD' and nLists[i].name ~= 'FRIENDS' then
			frame:AddButton(nLists[i].name, function(self)
				e.DeleteList(self:GetText())
				RemoveTab(self:GetText(), tabFrame)
				UpdateTabs()
			end)
		end
	end
end
--tabPopup:AddButton(L['DELETE_LIST'], nil, nil, function () RemoveList(subTabPopup) end, true, subTabPopup)

-- Middle panel construction, Affixe info, character info, guild/version string
local characterFrame = CreateFrame('FRAME', '$parentCharacterFrame', nKeyFrame)
characterFrame:SetSize(215, 490)
characterFrame:SetPoint('TOPLEFT', nKeyFrame, 'TOPLEFT', 51, 0)

characterFrame.collapse = characterFrame:CreateAnimationGroup()
local characterCollapse = characterFrame.collapse:CreateAnimation('Alpha')
characterCollapse:SetFromAlpha(1)
characterCollapse:SetToAlpha(0)
characterCollapse:SetDuration(.12)
characterCollapse:SetSmoothing('IN_OUT')

characterCollapse:SetScript('OnFinished', function(self)
	self:GetRegionParent():Hide()
	end)

characterCollapse:SetScript('OnUpdate', function(self)
	self:GetRegionParent():SetAlpha(self:GetSmoothProgress()/2)
	local left, bottom, width = nKeyFrame:GetRect()
	local newWidth = FRAME_WIDTH_EXPANDED - (self:GetProgress() * 215) -- 215:: Character Frame Width
	nKeyFrame:ClearAllPoints()
	nKeyFrame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left + width - newWidth, bottom)
	nKeyFrame:SetWidth(newWidth)
	end)

characterFrame.expand = characterFrame:CreateAnimationGroup()
local characterExpand = characterFrame.expand:CreateAnimation('Alpha')

characterExpand:SetFromAlpha(0)
characterExpand:SetToAlpha(1)
characterExpand:SetDuration(.12)
characterExpand:SetSmoothing('IN_OUT')

characterExpand:SetScript('OnPlay', function(self)
	self:GetRegionParent():Show()
	end)

characterExpand:SetScript('OnUpdate', function(self, elapsed)
		self:GetRegionParent():SetAlpha(self:GetSmoothProgress()*2)
		local left, bottom, width = nKeyFrame:GetRect()
		local newWidth = FRAME_WIDTH_MINIMIZED + (self:GetProgress() * 215) -- 215:: Character Frame Width
		nKeyFrame:ClearAllPoints()
		nKeyFrame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left + width - newWidth, bottom)
		nKeyFrame:SetWidth(newWidth)
	end)

collapseButton:SetScript('OnClick', function(self)
	if not nKeysSettings.frame.isCollapsed.isEnabled then
		if nKeyFrameCharacterFrame.expand:IsPlaying() then
			nKeyFrameCharacterFrame.expand:Stop()
		end
		nKeyFrameCharacterFrame.collapse:Play()
		nKeysSettings.frame.isCollapsed.isEnabled = true
		self:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-first_page-24px@2x')
	else
		if nKeyFrameCharacterFrame.collapse:IsPlaying() then
			nKeyFrameCharacterFrame.collapse:Stop()
		end
		nKeyFrameCharacterFrame.expand:Play()
		nKeysSettings.frame.isCollapsed.isEnabled = false
		self:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-last_page-24px@2x')
	end
	end)

local affixTitle = characterFrame:CreateFontString('$parentAffixTitle', 'OVERLAY', 'InterUIBlack_Small')
affixTitle:SetPoint('TOPLEFT', characterFrame, 'TOPLEFT', 20, -20)
affixTitle:SetText(L['AFFIXES'])

-- Affix Frames
-----------------------------------------------------

do
	for i = 1, 4 do
		local frame = CreateFrame('FRAME', '$parentAffix' .. i, characterFrame)
		frame.id = i

		local mask = frame:CreateMaskTexture()
		mask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetSize(32, 32)
		mask:SetPoint("CENTER")

		frame.affixID = 0
		frame:SetSize(32, 32)
		frame.icon = frame:CreateTexture(nil, 'ARTWORK')
				
		frame.icon:AddMaskTexture(mask)

		if i == 1 then
			frame:SetPoint('TOPLEFT', affixTitle, 'BOTTOMLEFT', 0, -15)
		else
			frame:SetPoint('LEFT', '$parentAffix' .. (i -1), 'RIGHT', 15, 0)
		end
		frame.icon:SetAllPoints(frame)

		function frame:UpdateInfo(affixID)
			if affixID and affixID ~= 0 then
				self.affixID = affixID
				local _, _, texture = C_ChallengeMode.GetAffixInfo(affixID)
				self.icon:SetTexture(texture)
			end
		end

		frame:SetScript('OnEnter', function(self)
			if not self.affixID then return end
			nKeyToolTip:SetOwner(self, 'ANCHOR_BOTTOMLEFT', 7, -2)
			nKeyToolTip:AddLine(e.AffixName(self.affixID), 1, 1, 1)
			if nKeysSettings.general.expanded_tooltip.isEnabled then
				nKeyToolTip:AddLine(e.AffixDescription(self.affixID), 1, 1, 1, true)
			end
			nKeyToolTip:Show()
			end)
		frame:SetScript('OnLeave', function(self)
			nKeyToolTip:Hide()
		end)
	end
end


-- Affix frame for coming week's affixes
----------------------------------------------------
nKeyFrame.affixesExpanded = false
local affixFrame = CreateFrame('FRAME', '$parentAffixFrame', nKeyFrameCharacterFrame)
affixFrame:SetSize(185, 15)
affixFrame:SetPoint('TOPLEFT', nKeyFrameCharacterFrameAffix1, 'BOTTOMLEFT', 0 , -10)

local affixExpandButton = CreateFrame('BUTTON', '$parentAffixExpandButton', characterFrame)
affixExpandButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_keyboard_arrow_down_white_18dp')
affixExpandButton:SetSize(24, 14)
affixExpandButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
affixExpandButton:SetPoint('BOTTOM', affixFrame, 'BOTTOM', 0, 0)

do
	for i = 1, 8 do
		local frame = CreateFrame('FRAME', '$parentAffix' .. i, affixFrame)
		frame.id = (i % 4) == 0 and 4 or i % 4
		if i < 5 then
			frame.weekOffset = 1
		else
			frame.weekOffset = 2
		end

		local mask = frame:CreateMaskTexture()
		mask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetSize(32, 32)
		mask:SetPoint("CENTER")

		frame.affixID = 0
		frame:SetSize(32, 32)
		frame.texture = frame:CreateTexture(nil, 'ARTWORK')
				
		frame.texture:AddMaskTexture(mask)

		if i == 1 then
			frame:SetPoint('TOPLEFT', affixFrame, 'TOPLEFT', 0, 0)
		elseif i == 5 then
			frame:SetPoint('TOPLEFT', '$parentAffix1', 'BOTTOMLEFT', 0, -15)
		else
			frame:SetPoint('LEFT', '$parentAffix' .. (i -1), 'RIGHT', 15, 0)
		end
		frame.texture:SetPoint('TOPLEFT', frame, 'TOPLEFT')
		frame.texture:SetAllPoints(frame)

		function frame:UpdateInfo()
			self.affixID = e.GetAffixID(self.id, self.weekOffset)
			local _, _, texture = C_ChallengeMode.GetAffixInfo(self.affixID)
			self.texture:SetTexture(texture)
		end

		frame:SetScript('OnEnter', function(self)
			if not self.affixID then return end
			nKeyToolTip:SetOwner(self, 'ANCHOR_BOTTOMLEFT', 7, -2)			
			nKeyToolTip:AddLine(e.AffixName(self.affixID), 1, 1, 1)
			if nKeysSettings.general.expanded_tooltip.isEnabled then
				nKeyToolTip:AddLine(e.AffixDescription(self.affixID), 1, 1, 1, true)
			end
			nKeyToolTip:Show()
			end)
		frame:SetScript('OnLeave', function(self)
			nKeyToolTip:Hide()
		end)

		frame:Hide()
	end
end

affixFrame.expand = affixFrame:CreateAnimationGroup()

local affixExpand = affixFrame.expand:CreateAnimation('Alpha')
affixExpand:SetFromAlpha(0)
affixExpand:SetToAlpha(1)
affixExpand:SetDuration(.12)
affixExpand:SetSmoothing('IN_OUT')

affixExpand:SetScript('OnPlay', function(self)
	affixExpandButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_keyboard_arrow_up_white_18dp')
	affixExpandButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	nKeyFrame.affixesExpanded = true
	end)

affixExpand:SetScript('OnUpdate', function(self)
	local progress = self:GetProgress()

	nKeyFrameCharacterFrameAffixFrame:SetHeight((progress * 85) + 15)
	nKeyFrameCharacterFrameCharacterContainer:SetHeight(((1-progress) * 85) + 230)
	nKeyFrameCharacterFrameCharacterTitle:SetPoint('TOPLEFT', affixFrame, 'BOTTOMLEFT', 0, -10)
	affixExpandButton:SetPoint('BOTTOM', affixFrame, 'BOTTOM', 0, 0)
	end)

local affixIconsExpand = affixFrame.expand:CreateAnimation('Alpha')
affixIconsExpand:SetDuration(0.08)
affixIconsExpand:SetFromAlpha(0)
affixIconsExpand:SetToAlpha(1)
affixIconsExpand:SetSmoothing('IN_OUT')
affixIconsExpand:SetStartDelay(0.1)

affixIconsExpand:SetScript('OnPlay', function(self)
	for i = 1, 8 do
		_G['nKeyFrameCharacterFrameAffixFrameAffix' .. i]:Show()
	end
	end)

affixIconsExpand:SetScript('OnUpdate', function(self)
	local alpha = self:GetSmoothProgress()
	for i = 1, 8 do
		_G['nKeyFrameCharacterFrameAffixFrameAffix' .. i]:SetAlpha(alpha)
	end
	end)

affixIconsExpand:SetScript('OnFinished', function()
	end)

affixFrame.collapse = affixFrame:CreateAnimationGroup()

local affixIconsCollapse = affixFrame.collapse:CreateAnimation('Alpha')
affixIconsCollapse:SetDuration(0.08)
affixIconsCollapse:SetFromAlpha(1)
affixIconsCollapse:SetToAlpha(0)
affixIconsCollapse:SetSmoothing('IN_OUT')
affixIconsCollapse:SetStartDelay(0.1)

affixIconsCollapse:SetScript('OnFinished', function()
	for i = 1, 8 do
		_G['nKeyFrameCharacterFrameAffixFrameAffix' .. i]:Hide()
	end
	end)

affixIconsCollapse:SetScript('OnUpdate', function(self)
	local alpha = self:GetSmoothProgress()
	for i = 1, 8 do
		_G['nKeyFrameCharacterFrameAffixFrameAffix' .. i]:SetAlpha(alpha)
	end
	end)

local affixCollapse = affixFrame.collapse:CreateAnimation('Alpha')
affixCollapse:SetFromAlpha(1)
affixCollapse:SetToAlpha(0)
affixCollapse:SetDuration(.12)
affixCollapse:SetSmoothing('IN_OUT')

affixCollapse:SetScript('OnPlay', function(self)
	affixExpandButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_keyboard_arrow_down_white_18dp')
	affixExpandButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	nKeyFrame.affixesExpanded = false
	end)

affixCollapse:SetScript('OnUpdate', function(self)
	local progress = self:GetSmoothProgress()

	nKeyFrameCharacterFrameAffixFrame:SetHeight(((1-progress) * 85) + 15)
	nKeyFrameCharacterFrameCharacterContainer:SetHeight((progress * 85) + 230)
	nKeyFrameCharacterFrameCharacterTitle:SetPoint('TOPLEFT', affixFrame, 'BOTTOMLEFT', 0, -10)
	affixExpandButton:SetPoint('BOTTOM', affixFrame, 'BOTTOM', 0, 0)
	end)

affixExpandButton:SetScript('OnClick', function(self)
	if nKeyFrame.affixesExpanded then
		affixFrame.collapse:Play()		
	else
		affixFrame.expand:Play()
	end
	end)

-- Character Frames
----------------------------------------------------------------
local characterTitle = characterFrame:CreateFontString('$parentCharacterTitle', 'OVERLAY', 'InterUIBlack_Small')
characterTitle:SetPoint('TOPLEFT', affixFrame, 'BOTTOMLEFT', 0, -10)
characterTitle:SetText(L['CHARACTERS'])

local versionString = CreateFrame('BUTTON', nil, characterFrame)
versionString:SetNormalFontObject(InterUIRegular_Small)
versionString:SetSize(110, 20)
versionString:SetPoint('BOTTOM', characterFrame, 'BOTTOM', 0, 10)
versionString:SetAlpha(0.2)

versionString:SetScript('OnEnter', function(self)
	self:SetAlpha(.8)
	end)
versionString:SetScript('OnLeave', function(self)
	self:SetAlpha(0.2)
	end)

characterFrame.background = characterFrame:CreateTexture(nil, 'BACKGROUND')
characterFrame.background:SetColorTexture(33/255, 33/255, 33/255, 0.8)
characterFrame.background:SetAllPoints(characterFrame)

function CharacterScrollFrame_Update()
	local scrollFrame = nKeyFrameCharacterFrameCharacterContainer
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local numButtons = #buttons
	local button, index
	local height = scrollFrame.buttonHeight
	local usedHeight = #buttons * height

	for i = 1, #buttons do
		if nCharacters[i+offset] then
			buttons[i]:UpdateUnit(i+offset)
			buttons[i]:Show()
		else
			buttons[i]:Hide()
		end
	end

	HybridScrollFrame_Update(nKeyFrameCharacterFrameCharacterContainer, height * #nCharacters, usedHeight)
end

local function CharacterScrollFrame_OnEnter()
	nKeyFrameCharacterFrameCharacterContainerScrollBarThumbTexture:SetAlpha(SCROLL_TEXTURE_ALPHA_MAX)
end

local function CharacterScrollFrame_OnLeave()
	nKeyFrameCharacterFrameCharacterContainerScrollBarThumbTexture:SetAlpha(SCROLL_TEXTURE_ALPHA_MIN)
end

local characterScrollFrame = CreateFrame('ScrollFrame', '$parentCharacterContainer', nKeyFrameCharacterFrame, 'HybridScrollFrameTemplate')
characterScrollFrame:SetSize(180, 315)
characterScrollFrame:SetPoint('TOPLEFT', characterTitle, 'TOPLEFT', 0, -25)
characterScrollFrame:SetScript('OnEnter',  CharacterScrollFrame_OnEnter)
characterScrollFrame:SetScript('OnLeave', CharacterScrollFrame_OnLeave)

local characterScrollBar = CreateFrame('Slider', '$parentScrollBar', characterScrollFrame, 'HybridScrollBarTemplate')
characterScrollBar:SetWidth(10)
characterScrollBar:SetPoint('TOPLEFT', characterScrollFrame, 'TOPRIGHT')
characterScrollBar:SetPoint('BOTTOMLEFT', characterScrollFrame, 'BOTTOMRIGHT', 1, 0)
characterScrollBar:SetScript('OnEnter', CharacterScrollFrame_OnEnter)
characterScrollBar:SetScript('OnLeave', CharacterScrollFrame_OnLeave)

-- Re-skin the scroll Bar
characterScrollBar.ScrollBarTop:Hide()
characterScrollBar.ScrollBarMiddle:Hide()
characterScrollBar.ScrollBarBottom:Hide()
_G[characterScrollBar:GetName() .. 'ScrollDownButton']:Hide()
_G[characterScrollBar:GetName() .. 'ScrollUpButton']:Hide()

local scrollButton = _G[characterScrollBar:GetName() .. 'ThumbTexture']
scrollButton:SetHeight(50)
scrollButton:SetWidth(4)
scrollButton:SetColorTexture(204/255, 204/255, 204/255, SCROLL_TEXTURE_ALPHA_MAX)

characterScrollFrame.buttonHeight = 45
characterScrollFrame.update = CharacterScrollFrame_Update

-- Key List Frames
----------------------------------------------------------------
-- self, unit, unitClass, mapID, keyLevel, cache, faction, btag
function ListScrollFrame_Update()
	local scrollFrame = nKeyFrameListContainer
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	
	local button, index
	local height = scrollFrame.buttonHeight
	local usedHeight = 0
	local list = e.FrameListShown()
	local lastIndex = 1

	local selectCount = 0
	for unit in pairs(selectedUnits) do
		selectCount = selectCount + 1
	end
	for i = 1, math.min(sortTable.num_shown, #buttons) do
		for j = lastIndex, #sortTable do
			if sortTable[j+offset] and sortTable[j+offset].isShown then
				usedHeight = usedHeight + height
				lastIndex = j + 1
				buttons[i]:SetUnit(sortTable[j+offset].character_name, sortTable[j+offset].character_class, sortTable[j+offset].dungeon_id, sortTable[j+offset].key_level, sortTable[j+offset].weekly_best, sortTable[j+offset]['faction'], sortTable[j+offset]['btag'])
				buttons[i]:Show()
				if selectCount > 1 and selectedUnits[sortTable[j+offset].character_name] then
					buttons[i].Highlight:Show()
				else
					buttons[i].Highlight:Hide()
				end
				break
			end
		end
	end

	for i = math.min(sortTable.num_shown, #buttons) + 1, #buttons do
		buttons[i]:Hide()
	end
	nKeyFrameListContainer.stepSize = (sortTable.num_shown / #buttons) * height
	HybridScrollFrame_Update(nKeyFrameListContainer, height * sortTable.num_shown, usedHeight)
end

local function ListScrollFrame_OnEnter()
	nKeyFrameListContainerScrollBarThumbTexture:SetAlpha(SCROLL_TEXTURE_ALPHA_MAX)
end

local function ListScrollFrame_OnLeave()
	nKeyFrameListContainerScrollBarThumbTexture:SetAlpha(SCROLL_TEXTURE_ALPHA_MIN)
end

local listScrollFrame = CreateFrame('ScrollFrame', '$parentListContainer', nKeyFrame, 'HybridScrollFrameTemplate')
listScrollFrame:SetSize(415, 375)
listScrollFrame:SetPoint('TOPLEFT', tabFrame, 'BOTTOMLEFT', 10, -35)
listScrollFrame.update = ListScrollFrame_Update
listScrollFrame:SetScript('OnEnter',  ListScrollFrame_OnEnter)
listScrollFrame:SetScript('OnLeave', ListScrollFrame_OnLeave)
--[[
local listHelperText = nKeyFrame:CreateFontString('$parentListHelperText', 'OVERLAY', 'InterUIBlack_ExtraLarge')
listHelperText:SetWidth(300)
listHelperText:SetJustifyH('CENTER')
listHelperText:SetPoint('TOP', nKeyFrameListContainer, 'TOP', 0, -100)
listHelperText:SetText(L['LIST_ADD_HELPER_TEXT'])
listHelperText:SetTextColor(1, 1, 1, 0.5)
]]
local listScrollBar = CreateFrame('Slider', '$parentScrollBar', listScrollFrame, 'HybridScrollBarTemplate')
listScrollBar:SetWidth(10)
listScrollBar:SetPoint('TOPLEFT', listScrollFrame, 'TOPRIGHT')
listScrollBar:SetPoint('BOTTOMLEFT', listScrollFrame, 'BOTTOMRIGHT', 1, 0)
listScrollBar:SetScript('OnEnter', ListScrollFrame_OnEnter)
listScrollBar:SetScript('OnLeave', ListScrollFrame_OnLeave)

listScrollBar.ScrollBarTop:Hide()
listScrollBar.ScrollBarMiddle:Hide()
listScrollBar.ScrollBarBottom:Hide()
_G[listScrollBar:GetName() .. 'ScrollDownButton']:Hide()
_G[listScrollBar:GetName() .. 'ScrollUpButton']:Hide()

local listScrollButton = _G[listScrollBar:GetName() .. 'ThumbTexture']
listScrollButton:SetHeight(50)
listScrollButton:SetWidth(4)
listScrollButton:SetColorTexture(204/255, 204/255, 204/255, SCROLL_TEXTURE_ALPHA_MIN)
listScrollButton:SetAlpha(SCROLL_TEXTURE_ALPHA_MIN)
listScrollFrame.buttonHeight = 15

local contentFrame = CreateFrame('FRAME', 'nContentFrame', nKeyFrame)
contentFrame:SetSize(410, 390)
contentFrame:SetPoint('TOPLEFT', tabFrame, 'BOTTOMLEFT', 0, -30)

local function ListButton_OnClick(self)
	HybridScrollFrame_SetOffset(nKeyFrameListContainer, 0)
	nKeyFrameListContainer.scrollBar:SetValue(0)

	if self.sortMethod == nKeysSettings.frame.sorth_method then
		nKeysSettings.frame.orientation = 1 - nKeysSettings.frame.orientation
	else
		nKeysSettings.frame.orientation = 0
	end
	nKeysSettings.frame.sorth_method = self.sortMethod
	e.SortTable(sortTable, nKeysSettings.frame.sorth_method)
	e.UpdateFrames()
end

local keyLevelButton = CreateFrame('BUTTON', '$parentKeyLevelButton', contentFrame)
keyLevelButton.sortMethod = 'key_level'
keyLevelButton:SetSize(40, 20)
keyLevelButton:SetNormalFontObject(InterUIBlack_Small)
keyLevelButton:GetNormalFontObject():SetJustifyH('CENTER')
keyLevelButton:SetText(L['LEVEL'])
keyLevelButton:SetAlpha(0.5)
keyLevelButton:SetPoint('TOPLEFT', tabFrame, 'BOTTOMLEFT', 16, -5)
keyLevelButton:SetScript('OnClick', function(self) ListButton_OnClick(self) end)

local keyLevelSearchButton = CreateFrame('BUTTON', '$parentKeyLevelSearch', contentFrame)
keyLevelSearchButton:SetSize(14, 14)
keyLevelSearchButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_search_white_18dp')
keyLevelSearchButton:SetPoint('LEFT', keyLevelButton, 'RIGHT', -5, 0)
keyLevelSearchButton:SetAlpha(0)
keyLevelSearchButton:SetFrameLevel(keyLevelButton:GetFrameLevel() + 1)

local keyLevelSearchCloseButton = CreateFrame('BUTTON', '$parentKeyLevelSearchCloseButton', contentFrame)
keyLevelSearchCloseButton.filterMethod = 'key_level'
keyLevelSearchCloseButton:SetSize(8, 8)
keyLevelSearchCloseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-close-24px@2x')
keyLevelSearchCloseButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
keyLevelSearchCloseButton:SetPoint('LEFT', keyLevelButton, 'RIGHT', -5, 1)
keyLevelSearchCloseButton:SetFrameLevel(keyLevelButton:GetFrameLevel() + 1)
keyLevelSearchCloseButton:Hide()

local keyLevelSearchTextString = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBlack_Small')
keyLevelSearchTextString:SetJustifyH('LEFT')
keyLevelSearchTextString:SetPoint('LEFT', keyLevelButton, 'LEFT')
keyLevelSearchTextString:SetTextColor(1, 1, 1, 0.5)
keyLevelSearchTextString:Hide()

local keyLevelSearchTextInput = CreateFrame('EditBox', '%parentKeyLevelSearchInput', contentFrame)
keyLevelSearchTextInput.filterMethod = 'key_level'
keyLevelSearchTextInput:SetSize(30, 20)
keyLevelSearchTextInput:SetPoint('RIGHT', keyLevelSearchButton, 'LEFT')
keyLevelSearchTextInput:SetFontObject(InterUIBlack_Small)
keyLevelSearchTextInput:SetJustifyH('LEFT')
keyLevelSearchTextInput:SetTextColor(1, 1, 1, 0.5)
keyLevelSearchTextInput:SetAutoFocus(false)
keyLevelSearchTextInput:EnableKeyboard(true)
keyLevelSearchTextInput:Hide()

keyLevelSearchTextInput:SetScript('OnEscapePressed', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	e.UpdateFrames()
	self:ClearFocus()
	keyLevelSearchTextString:Hide()
	keyLevelSearchTextInput:Hide()
	keyLevelButton:Show()
	keyLevelSearchCloseButton:Hide()
	keyLevelSearchButton:Show()
	end)

-- Avaiable search patterns:
--	x		Looks for key level equating x
--	x-		Looks for key levels equal to or less than x
--	x+		Looks for key levels equal to or greater than x
--
-- Spaces will be removed from input text on search, space characters will not effect search results.
-- 

keyLevelSearchTextInput:SetScript('OnEnterPressed', function(self)
	self:ClearFocus()
	FILTER_FIELDS[self.filterMethod] = self:GetText():gsub('%s', '')
	e.UpdateFrames()
	if self:GetText() == '' then
		keyLevelSearchTextString:Hide()
		keyLevelSearchTextInput:Hide()
		keyLevelButton:Show()
		keyLevelSearchCloseButton:Hide()
		keyLevelSearchButton:Show()
	end
	end)

keyLevelSearchTextInput:SetScript('OnTextChanged', function(self)
	if not self:GetText() or self:GetText() ~= '' then
		keyLevelSearchTextString:Hide()
	else
		keyLevelSearchTextString:Show()
	end
	FILTER_FIELDS[self.filterMethod] = self:GetText()
	e.UpdateFrames()
	end)

keyLevelSearchButton:SetScript('OnClick', function(self)
	keyLevelSearchTextString:Show()
	self:Hide()
	keyLevelSearchCloseButton:Show()
	keyLevelButton:Hide()
	keyLevelSearchTextInput:Show()
	keyLevelSearchTextInput:SetFocus(true)
	keyLevelSearchTextInput:SetText('')
	end)

keyLevelSearchButton:SetScript('OnEnter', function(self)
	self:SetAlpha(0.8)
	end)
keyLevelSearchButton:SetScript('OnLeave', function(self)
	self:SetAlpha(0)
	end)

keyLevelButton:SetScript('OnEnter', function()
	keyLevelSearchButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	keyLevelSearchButton:SetAlpha(0.8)
	end)

keyLevelButton:SetScript('OnLeave', function()
	keyLevelSearchButton:SetAlpha(0)
	end)

keyLevelSearchCloseButton:SetScript('OnClick', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	keyLevelSearchCloseButton:Hide()
	keyLevelSearchButton:Show()
	keyLevelSearchTextInput:Hide()
	keyLevelSearchTextString:Hide()
	keyLevelButton:Show()
	e.UpdateFrames()
	end)

local dungeonButton = CreateFrame('BUTTON', '$parentDungeonButton', contentFrame)
dungeonButton.sortMethod = 'dungeon_name'
dungeonButton:SetSize(155, 20)
dungeonButton:SetNormalFontObject(InterUIBlack_Small)
dungeonButton:GetNormalFontObject():SetJustifyH('LEFT')
dungeonButton:SetText(L['DUNGEON'])
dungeonButton:SetAlpha(0.5)
dungeonButton:SetPoint('LEFT', keyLevelButton, 'RIGHT', 10, 0)
dungeonButton:SetScript('OnClick', function(self) ListButton_OnClick(self) end)

local dungeonSearchButton = CreateFrame('BUTTON', '$parentDungeonSearch', contentFrame)
dungeonSearchButton:SetSize(14, 14)
dungeonSearchButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_search_white_18dp')
dungeonSearchButton:SetPoint('RIGHT', dungeonButton, 'RIGHT', -5, 0)
dungeonSearchButton:SetAlpha(0)
dungeonSearchButton:SetFrameLevel(dungeonButton:GetFrameLevel() + 1)

local dungeonSearchCloseButton = CreateFrame('BUTTON', '$parentDungeonSearchCloseButton', contentFrame)
dungeonSearchCloseButton.filterMethod = 'dungeon_name'
dungeonSearchCloseButton:SetSize(8, 8)
dungeonSearchCloseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-close-24px@2x')
dungeonSearchCloseButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
dungeonSearchCloseButton:SetPoint('RIGHT', dungeonButton, 'RIGHT', -8, 1)
dungeonSearchCloseButton:SetFrameLevel(dungeonButton:GetFrameLevel() + 1)
dungeonSearchCloseButton:Hide()

local dungeonSearchTextString = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBlack_Small')
dungeonSearchTextString:SetJustifyH('LEFT')
dungeonSearchTextString:SetPoint('LEFT', dungeonButton, 'LEFT')
dungeonSearchTextString:SetTextColor(1, 1, 1, 0.5)
dungeonSearchTextString:SetText(L['FILTER_TEXT_DUNGEON'])
dungeonSearchTextString:Hide()

local dungeonSearchTextInput = CreateFrame('EditBox', '%parentDungeonSearchInput', contentFrame)
dungeonSearchTextInput.filterMethod = 'dungeon_name'
dungeonSearchTextInput:SetSize(135, 20)
dungeonSearchTextInput:SetPoint('RIGHT', dungeonSearchButton, 'LEFT')
dungeonSearchTextInput:SetFontObject(InterUIBlack_Small)
dungeonSearchTextInput:SetJustifyH('LEFT')
dungeonSearchTextInput:SetTextColor(1, 1, 1, 0.5)
dungeonSearchTextInput:SetAutoFocus(false)
dungeonSearchTextInput:EnableKeyboard(true)
dungeonSearchTextInput:Hide()

dungeonSearchTextInput:SetScript('OnEscapePressed', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	e.UpdateFrames()
	self:ClearFocus()
	dungeonSearchTextString:Hide()
	dungeonSearchTextInput:Hide()
	dungeonButton:Show()
	dungeonSearchCloseButton:Hide()
	dungeonSearchButton:Show()
	end)

dungeonSearchTextInput:SetScript('OnEnterPressed', function(self)
	self:ClearFocus()
	FILTER_FIELDS[self.filterMethod] = self:GetText()
	e.UpdateFrames()
	if self:GetText() == '' then
		dungeonSearchCloseButton:Hide()
		dungeonSearchButton:Show()
		dungeonSearchTextInput:Hide()
		dungeonSearchTextString:Hide()
		dungeonButton:Show()
	end
	end)

dungeonSearchTextInput:SetScript('OnTextChanged', function(self)
	if not self:GetText() or self:GetText() ~= '' then
		dungeonSearchTextString:Hide()
	else
		dungeonSearchTextString:Show()
	end
	FILTER_FIELDS[self.filterMethod] = self:GetText()
	e.UpdateFrames()
	end)

dungeonSearchButton:SetScript('OnClick', function(self)
	dungeonSearchTextString:Show()
	self:Hide()
	dungeonSearchCloseButton:Show()
	dungeonButton:Hide()
	dungeonSearchTextInput:Show()
	dungeonSearchTextInput:SetFocus(true)
	dungeonSearchTextInput:SetText('')
	end)

dungeonSearchButton:SetScript('OnEnter', function(self)
	self:SetAlpha(0.8)
	end)
dungeonSearchButton:SetScript('OnLeave', function(self)
	self:SetAlpha(0)
	end)

dungeonButton:SetScript('OnEnter', function()
	dungeonSearchButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	dungeonSearchButton:SetAlpha(0.8)
	end)

dungeonButton:SetScript('OnLeave', function()
	dungeonSearchButton:SetAlpha(0)
	end)

dungeonSearchCloseButton:SetScript('OnClick', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	dungeonSearchCloseButton:Hide()
	dungeonSearchButton:Show()
	dungeonSearchTextInput:Hide()
	dungeonSearchTextString:Hide()
	dungeonButton:Show()
	e.UpdateFrames()
	end)

local characterButton = CreateFrame('BUTTON', '$parentCharacterButton', contentFrame)
characterButton.sortMethod = 'character_name'
characterButton:SetSize(153, 20)
characterButton:SetNormalFontObject(InterUIBlack_Small)
characterButton:GetNormalFontObject():SetJustifyH('LEFT')
characterButton:SetText(L['CHARACTER'])
characterButton:SetAlpha(0.5)
characterButton:SetPoint('LEFT', dungeonButton, 'RIGHT')
characterButton:SetScript('OnClick', function(self) ListButton_OnClick(self) end)


local characterSearchButton = CreateFrame('BUTTON', '$parentCharacterSearch', contentFrame)
characterSearchButton:SetSize(14, 14)
characterSearchButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline_search_white_18dp')
characterSearchButton:SetPoint('RIGHT', characterButton, 'RIGHT', -10, 0)
characterSearchButton:SetAlpha(0)
characterSearchButton:SetFrameLevel(characterButton:GetFrameLevel() + 1)

local characterSearchCloseButton = CreateFrame('BUTTON', '$parentCharacterSearchCloseButton', contentFrame)
characterSearchCloseButton.filterMethod = 'character_name'
characterSearchCloseButton:SetSize(8, 8)
characterSearchCloseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-close-24px@2x')
characterSearchCloseButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
characterSearchCloseButton:SetPoint('RIGHT', characterButton, 'RIGHT', -13, 1)
characterSearchCloseButton:SetFrameLevel(characterButton:GetFrameLevel() + 1)
characterSearchCloseButton:Hide()

local characterSearchTextString = contentFrame:CreateFontString(nil, 'OVERLAY', 'InterUIBlack_Small')
characterSearchTextString:SetJustifyH('LEFT')
characterSearchTextString:SetPoint('LEFT', characterButton, 'LEFT')
characterSearchTextString:SetTextColor(1, 1, 1, 0.5)
characterSearchTextString:SetText(L['FILTER_TEXT_CHARACTER'])
characterSearchTextString:Hide()

local characterSearchTextInput = CreateFrame('EditBox', '%parentCharacterSearchInput', contentFrame)
characterSearchTextInput.filterMethod = 'character_name'
characterSearchTextInput:SetSize(133, 20)
characterSearchTextInput:SetPoint('RIGHT', characterSearchButton, 'LEFT')
characterSearchTextInput:SetFontObject(InterUIBlack_Small)
characterSearchTextInput:SetJustifyH('LEFT')
characterSearchTextInput:SetTextColor(1, 1, 1, 0.5)
characterSearchTextInput:SetAutoFocus(false)
characterSearchTextInput:EnableKeyboard(true)
characterSearchTextInput:Hide()

characterSearchTextInput:SetScript('OnEscapePressed', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	e.UpdateFrames()
	self:ClearFocus()
	characterSearchTextString:Hide()
	characterSearchTextInput:Hide()
	characterButton:Show()
	characterSearchCloseButton:Hide()
	characterSearchButton:Show()
	end)

characterSearchTextInput:SetScript('OnEnterPressed', function(self)
	self:ClearFocus()
	FILTER_FIELDS[self.filterMethod] = self:GetText()
	e.UpdateFrames()
	if self:GetText() == '' then
		characterSearchCloseButton:Hide()
		characterSearchButton:Show()
		characterSearchTextInput:Hide()
		characterSearchTextString:Hide()
		characterButton:Show()
	end
	end)

characterSearchTextInput:SetScript('OnTextChanged', function(self)
	if not self:GetText() or self:GetText() ~= '' then
		characterSearchTextString:Hide()
	else
		characterSearchTextString:Show()
	end
	FILTER_FIELDS[self.filterMethod] = self:GetText()
	e.UpdateFrames()
	end)

characterSearchButton:SetScript('OnClick', function(self)
	characterSearchTextString:Show()
	self:Hide()
	characterSearchCloseButton:Show()
	characterButton:Hide()
	characterSearchTextInput:Show()
	characterSearchTextInput:SetFocus(true)
	characterSearchTextInput:SetText('')
	end)

characterSearchButton:SetScript('OnEnter', function(self)
	self:SetAlpha(0.8)
	end)
characterSearchButton:SetScript('OnLeave', function(self)
	self:SetAlpha(0)
	end)

characterButton:SetScript('OnEnter', function()
	characterSearchButton:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8)
	characterSearchButton:SetAlpha(0.8)
	end)

characterButton:SetScript('OnLeave', function()
	characterSearchButton:SetAlpha(0)
	end)

characterSearchCloseButton:SetScript('OnClick', function(self)
	FILTER_FIELDS[self.filterMethod] = ''
	characterSearchCloseButton:Hide()
	characterSearchButton:Show()
	characterSearchTextInput:Hide()
	characterSearchTextString:Hide()
	characterButton:Show()
	e.UpdateFrames()
	end)

local weeklyBestButton = CreateFrame('BUTTON', '$parentWeeklyBestButton', contentFrame)
weeklyBestButton.sortMethod = 'weekly_best'
weeklyBestButton:SetSize(40, 20)
weeklyBestButton:SetNormalFontObject(InterUIBlack_Small)
characterButton:GetNormalFontObject():SetJustifyH('CENTER')
weeklyBestButton:SetText(L['WEEKLY_BEST'])
weeklyBestButton:SetAlpha(0.5)
weeklyBestButton:SetPoint('LEFT', characterButton, 'RIGHT')
weeklyBestButton:SetScript('OnClick', function(self) ListButton_OnClick(self) end)

function nKeyFrame:OnUpdate(elapsed)
	self.updateDelay = self.updateDelay + elapsed

	if self.updateDelay < 0.75 then
		return
	end
	self:SetScript('OnUpdate', nil)
	self.updateDelay = 0
	e.UpdateFrames()
end

function nKeyFrame:ToggleLists()
	if nKeysSettings.friendOptions.friend_sync.isEnabled then
		nKeyFrameTabFrameTabFRIENDS:Show()
	else
		nKeyFrameTabFrameTabFRIENDS:Hide()
		if e.FrameListShown() == 'FRIENDS' then
			e.SetFrameListShown('GUILD')
			UpdateTabs()
			e.UpdateFrames()
			HybridScrollFrame_SetOffset(nKeyFrameListContainer, 0)
			nKeyFrameListContainer.scrollBar:SetValue(0)

		end
	end
end

nKeyFrame:SetScript('OnKeyDown', function(self, key)
	if key == 'ESCAPE' then
		self:SetPropagateKeyboardInput(false)
		nKeyFrame:Hide()
	end
	end)

nKeyFrame:SetScript('OnShow', function(self)
	offLineButton:SetChecked(nKeysSettings.frame.show_offline.isEnabled)
	e.UpdateFrames()
	e.UpdateCharacterFrames()
	self:SetPropagateKeyboardInput(true)
	end)

nKeyFrame:SetScript('OnDragStart', function(self)
	self:StartMoving()
	unitPopup:Hide()
	subUnitPopup:Hide()
	--tabPopup:Hide()
	nMenuFrameReport1:Hide()
	end)

nKeyFrame:SetScript('OnDragStop', function(self)
	self:StopMovingOrSizing()
	end)

nKeyFrame:SetScript('OnHide', function(self)
	wipe(selectedUnits)
	nMenuFrameUnit1:Hide()
	nMenuFrameReport1:Hide()
	end)

local init = false
local function InitializeFrame()
	init = true

	for i = 1, #nLists do
		CreateNewTab(nLists[i].name, tabFrame)
	end
	UpdateTabs()

	versionString:SetFormattedText('nKeys - %s', e.CLIENT_VERSION)

	if nKeysSettings.frame.isCollapsed.isEnabled then
		collapseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-first_page-24px@2x')
		nKeyFrame:SetWidth(FRAME_WIDTH_MINIMIZED)
		nKeyFrameCharacterFrame:Hide()
	else
		collapseButton:SetNormalTexture('Interface\\AddOns\\nKeys\\Media\\Texture\\baseline-last_page-24px@2x')
	end

	if not nKeysSettings.friendOptions.friend_sync.isEnabled then
		nKeyFrameTabFrameTabFRIENDS:Hide()
	end

	offLineButton:SetChecked(nKeysSettings.frame.show_offline.isEnabled)
	HybridScrollFrame_CreateButtons(nKeyFrameCharacterFrameCharacterContainer, 'nCharacterFrameTemplate', 0, 0, 'TOPLEFT', 'TOPLEFT', 0, -10)
	HybridScrollFrame_CreateButtons(nKeyFrameListContainer, 'nListFrameTemplate', 0, 0, 'TOPLEFT', 'TOPLEFT', 0, -10)

	e.UpdateAffixes()

	e.UpdateFrames()
	UpdateTabs()
end

function e.UpdateAffixes()
	nKeyFrameCharacterFrameAffix1:UpdateInfo(e.AffixOne())
	nKeyFrameCharacterFrameAffix2:UpdateInfo(e.AffixTwo())
	nKeyFrameCharacterFrameAffix3:UpdateInfo(e.AffixThree())
	nKeyFrameCharacterFrameAffix4:UpdateInfo(e.AffixFour())

	for i = 1, 8 do
		_G['nKeyFrameCharacterFrameAffixFrameAffix' .. i]:UpdateInfo()
	end
end

function e.WipeFrames()
	wipe(sortedTable)
end

function e.UpdateLines()
	if not init then return end
	local list = e.FrameListShown()
	if e.GetListCount(list) == 0 or list ~= 'GUILD' or list ~= 'FRIENDS' then -- There haven't been any units added to the list, show the helper text
		--nKeyFrameListHelperText:Show()
	else
		--nKeyFrameListHelperText:Hide()
	end
	ListScrollFrame_Update()
end

function e.UpdateFrames()
	if not init or not nKeyFrame:IsShown() then return end

	e.UpdateTable(sortTable, FILTER_FIELDS)
	e.SortTable(sortTable, nKeysSettings.frame.sorth_method)
	e.UpdateLines()
end

function e.UpdateCharacterFrames()
	if not init then return end
	
	local id = e.GetCharacterID(e.Player())
	if id then
		local player = table.remove(nCharacters, id)
		table.sort(nCharacters, function(a,b) return a.unit < b.unit end)
		table.insert(nCharacters, 1, player)
		e.UpdateCharacterIDs()
	end
	CharacterScrollFrame_Update()
end

-- To be used when switching lists maybe?
function e.UpdateSortTable()
	local currentList = e.FrameListShown()

	wipe(sortTable)

	for i = 1, #nLists do
		if nLists[i].name == currentList then
			for unit, bt in pairs(nLists[i].units) do
				local unitID = e.UnitID(unit)

				if unitID then
					local btag
					if type(bt) == 'string' then
						btag = bt
					end

					local addToList = false

					if currentList == 'GUILD' then
						if e.UnitInGuild(unit) then
							addToList = true
						end
					else
						addToList = true
					end

					if addToList then
						table.insert(sortTable, {
							character_name = nKeys[unitID].unit,
							character_class = nKeys[unitID].class,
							dungeon_id =nKeys[unitID].dungeon_id,
							key_level = nKeys[unitID].key_level,
							weekly_best = nKeys[unitID].weekly_best,
							faction = nKeys[unitID].faction,
							btag = btag or nKeys[unitID].btag,
							source = nKeys[unitID].source
						})
					end
				end
			end
		end
	end
end

function e.AddUnitToSortTable(unit, btag, class, faction, mapID, level, weekly_best, source)
	if not e.DoesUnitBelongToList(unit, e.FrameListShown()) then return end

	if e.FrameListShown() == 'GUILD' then
		if not e.UnitInGuild(unit) then
			return
		end
	end

	local found = false
	for i = 1, #sortTable do
		if sortTable[i].character_name == unit then
			sortTable[i].dungeon_id = mapID
			sortTable[i].key_level = level
			sortTable[i].weekly_best = weekly_best
			found = true
			break
		end
	end

	if not found then
		table.insert(sortTable, {
				character_name = unit,
				btag = btag,
				character_class = class,
				faction = faction,
				dungeon_id =mapID,
				key_level = level,
				weekly_best = weekly_best,
				source = source,
			})
	end
end

		
-- Old function.
function e.AddUnitToTable(unit, class, faction, listType, mapID, level, weekly_best, btag)
	if not sortedTable[listType] then
		sortedTable[listType] = {}
	end
	local found = false
	for i = 1, #sortedTable[listType] do
		if sortedTable[listType][i].character_name == unit then
			sortedTable[listType][i].mapID = mapID
			sortedTable[listType][i].key_level = level
			sortedTable[listType][i].weekly_best = weekly_best
			found = true
			break
		end
	end

	if not found then
		sortedTable[listType][#sortedTable[listType] + 1] = {character_name = unit, character_class = class, mapID = mapID, key_level = level, weekly_best = weekly_best, faction = faction, btag = btag}
	end
end

function e.nToggle()
	if not init then InitializeFrame() end
	nKeyFrame:SetShown(not nKeyFrame:IsShown())
end

SLASH_nKEYS1 = '/nkeys'
SLASH_nKEYS2 = '/ak'
SLASH_nKEYSV1 = '/akv'

local function handler(msg)
	e.nToggle()
end

SlashCmdList['nKEYS'] = handler;
SlashCmdList['nKEYSV'] = function(msg) e.CheckGuildVersion() end