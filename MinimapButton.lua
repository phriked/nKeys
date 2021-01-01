local e, L = unpack(select(2, ...))

local addon = LibStub("AceAddon-3.0"):NewAddon("nKeys", "AceConsole-3.0")

local nkeysLDB = LibStub("LibDataBroker-1.1"):NewDataObject("nKeys", {
	type = "data source",
	text = "nKeys",
	icon = "Interface\\AddOns\\nKeys\\Media\\Texture\\nKeyslogo",
	OnClick = function(self, button)
		if button == 'LeftButton' then 
			e.nToggle()
		elseif button == 'RightButton' then
			nOptionsFrame:SetShown( not nOptionsFrame:IsShown())
		end  
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine("n Keys")
		tooltip:AddLine('Left click to toggle main window')
		tooltip:AddLine('Right Click to toggle options')
	end,
})

e.icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	local showButton = true
	if nKeysSettings.general and not nKeysSettings.general.show_minimap_button.isEnabled then
		showButton = false
	end
	self.db = LibStub("AceDB-3.0"):New("nMinimap", {
		profile = {
			minimap = {
				hide = not showButton,
			},
		},
	})
	e.icon:Register("nKeys", nkeysLDB, self.db.profile.minimap)
end