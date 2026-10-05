local E, _, _, _, _ = unpack(ElvUI)

local function SetOrder(name, order)
	local option = E.Options.args[name]
	if option then
		option.order = order
	end
end

SetOrder("general", 1)
SetOrder("enhanced", 2)
SetOrder("Tweaker", 3)
SetOrder("addOnSkins", 4)

-- Keep the main settings sections together after the addon-specific options.
SetOrder("actionbar", 5)
SetOrder("auras", 5)
SetOrder("bags", 5)
SetOrder("chat", 5)
SetOrder("cooldown", 5)
SetOrder("databars", 5)
SetOrder("datatexts", 5)
SetOrder("maps", 5)
SetOrder("nameplate", 5)
SetOrder("skins", 5)
SetOrder("tooltip", 5)
SetOrder("unitframe", 5)

-- Dividers are disabled for now.
-- AddDivider("navigationDividerFrames", 3)
-- AddDivider("navigationDividerData", 3)
-- AddDivider("navigationDividerSkins", 3)
-- AddDivider("navigationDividerTools", 3)

SetOrder("tagGroup", 5)
SetOrder("modulecontrol", 6)
SetOrder("filters", 6)
SetOrder("profiles", 5)