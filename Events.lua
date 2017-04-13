local _, e = ...

local akEvents = CreateFrame('FRAME')

akEvents:SetScript("OnEvent", function(self, event, ...)
		akEvents[event](self, ...)
end)


function e.RegisterEvent(event, func)
	akEvents:RegisterEvent(event)
	akEvents[event] = function(self, ...)
	func(...)
	end
end