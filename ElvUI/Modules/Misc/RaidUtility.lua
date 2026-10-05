local E, L = unpack(select(2, ...)); --Import: Engine, Locales
local RU = E:GetModule("RaidUtility")
local S = E:GetModule("Skins")
local RaidUtilityPanel, RaidUtility_ShowButton
local DisbandRaidButton, MainTankButton, MainAssistButton
local ReadyCheckButton, RaidControlButton, ConvertRaidButton
local CountdownButton, RoleCheckButton, DifficultyButton, RaidTargetIcons, RoleCountText

--Lua functions
local format = string.format
--WoW API / Variables
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local IsInInstance = IsInInstance
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local IsPartyLeader = IsPartyLeader
local IsRaidLeader = IsRaidLeader
local IsRaidOfficer = IsRaidOfficer
local InCombatLockdown = InCombatLockdown
local DoReadyCheck = DoReadyCheck
local ToggleFriendsFrame = ToggleFriendsFrame
local GetPartyAssignment = GetPartyAssignment
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitName = UnitName
local UnitExists = UnitExists
local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTarget = SetRaidTarget
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local SendChatMessage = SendChatMessage
local GetDungeonDifficulty = GetDungeonDifficulty
local SetDungeonDifficulty = SetDungeonDifficulty
local GetRaidDifficulty = GetRaidDifficulty
local SetRaidDifficulty = SetRaidDifficulty
local ResetInstances = ResetInstances
local EasyMenu = EasyMenu
local CloseDropDownMenus = CloseDropDownMenus
local GameTooltip = GameTooltip

local BUTTON_HEIGHT = 18
local BUTTON_SPACING = 5
local PANEL_PADDING = 10
local ICON_SIZE = 22
local ICON_SPACING = 2
local MARKER_COUNT = 9
local ICON_ROW_HEIGHT = ICON_SIZE + 4
local ROLE_ROW_HEIGHT = 16
local BUTTON_ROWS = 6
local countdownInProgress = false
local ANCHOR_TARGETS = {
	MINIMAP = function() return Minimap end,
	PLAYER = function() return _G.ElvUF_Player end,
	FOCUS = function() return _G.ElvUF_Focus end,
	TARGET = function() return _G.ElvUF_Target end,
}

for index = 1, 10 do
	local barIndex = index
	ANCHOR_TARGETS["ACTIONBAR"..barIndex] = function() return _G["ElvUI_Bar"..barIndex] end
end

local SIDE_POINTS = {
	TOP = {"BOTTOM", "TOP", 0, 1},
	BOTTOM = {"TOP", "BOTTOM", 0, -1},
	LEFT = {"RIGHT", "LEFT", -1, 0},
	RIGHT = {"LEFT", "RIGHT", 1, 0},
}

local EXPANSION_POINTS = {
	UP = {"BOTTOM", "TOP"},
	DOWN = {"TOP", "BOTTOM"},
}

local PANEL_POINTS = {
	TOP = {"TOP", "BOTTOM"},
	BOTTOM = {"BOTTOM", "TOP"},
	LEFT = {"LEFT", "RIGHT"},
	RIGHT = {"RIGHT", "LEFT"},
}

local SCREEN_POINTS = {
	TOP = {"TOP", "TOP", 0, -1},
	BOTTOM = {"BOTTOM", "BOTTOM", 0, 1},
	LEFT = {"LEFT", "LEFT", 1, 0},
	RIGHT = {"RIGHT", "RIGHT", -1, 0},
}

local function GetRaidControlSettings()
	return E.db.CustomTweaks.RaidControl
end

local function GetPanelHeight()
	return PANEL_PADDING * 2
		+ (BUTTON_HEIGHT * BUTTON_ROWS)
		+ (BUTTON_SPACING * BUTTON_ROWS)
		+ BUTTON_SPACING
		+ ICON_ROW_HEIGHT
		+ BUTTON_SPACING
		+ ROLE_ROW_HEIGHT
end

function RU:ApplyRaidControlSettings()
	if not self.Initialized then return end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ApplyRaidControlSettings")
		return
	end

	local settings = GetRaidControlSettings()
	local panel, showButton = RaidUtilityPanel, RaidUtility_ShowButton
	local width = math.max(180, math.min(settings.width or 230, 500))
	settings.width = width
	local scale = settings.scale or 1
	local spacing = math.max(0, math.min(settings.spacing or 5, 50))
	settings.spacing = spacing
	local contentWidth = math.max(1, width - (PANEL_PADDING * 2))
	local buttonWidth = (contentWidth - BUTTON_SPACING) / 2
	local rowTop = -PANEL_PADDING

	panel:SetSize(width, GetPanelHeight())

	DisbandRaidButton:SetSize(contentWidth, BUTTON_HEIGHT)
	DisbandRaidButton:ClearAllPoints()
	DisbandRaidButton:Point("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, rowTop)

	MainTankButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	MainTankButton:ClearAllPoints()
	MainTankButton:Point("TOPLEFT", DisbandRaidButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
	MainAssistButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	MainAssistButton:ClearAllPoints()
	MainAssistButton:Point("TOPLEFT", MainTankButton, "TOPRIGHT", BUTTON_SPACING, 0)

	ReadyCheckButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	ReadyCheckButton:ClearAllPoints()
	ReadyCheckButton:Point("TOPLEFT", MainTankButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
	RaidControlButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	RaidControlButton:ClearAllPoints()
	RaidControlButton:Point("TOPLEFT", ReadyCheckButton, "TOPRIGHT", BUTTON_SPACING, 0)

	ConvertRaidButton:SetSize(contentWidth, BUTTON_HEIGHT)
	ConvertRaidButton:ClearAllPoints()
	ConvertRaidButton:Point("TOPLEFT", ReadyCheckButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
	CountdownButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	CountdownButton:ClearAllPoints()
	CountdownButton:Point("TOPLEFT", ConvertRaidButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
	RoleCheckButton:SetSize(buttonWidth, BUTTON_HEIGHT)
	RoleCheckButton:ClearAllPoints()
	RoleCheckButton:Point("TOPLEFT", CountdownButton, "TOPRIGHT", BUTTON_SPACING, 0)

	DifficultyButton:SetSize(contentWidth, BUTTON_HEIGHT)
	DifficultyButton:ClearAllPoints()
	DifficultyButton:Point("TOPLEFT", CountdownButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
	rowTop = rowTop - BUTTON_ROWS * (BUTTON_HEIGHT + BUTTON_SPACING)

	RaidTargetIcons:ClearAllPoints()
	RaidTargetIcons:SetSize(contentWidth, ICON_ROW_HEIGHT)
	RaidTargetIcons:Point("TOP", panel, "TOP", 0, rowTop - BUTTON_SPACING)

	local iconSize = math.min(ICON_SIZE, (contentWidth - (ICON_SPACING * (MARKER_COUNT - 1))) / MARKER_COUNT)
	local firstIcon = _G.RaidUtility_TargetIcon1
	if firstIcon then
		firstIcon:SetSize(iconSize, iconSize)
		firstIcon:ClearAllPoints()
		firstIcon:Point("LEFT", RaidTargetIcons, "LEFT", (contentWidth - (iconSize * MARKER_COUNT) - (ICON_SPACING * (MARKER_COUNT - 1))) / 2, 0)
		for index = 2, MARKER_COUNT do
			local icon = _G["RaidUtility_TargetIcon"..index]
			icon:SetSize(iconSize, iconSize)
			icon:ClearAllPoints()
			icon:Point("LEFT", _G["RaidUtility_TargetIcon"..(index - 1)], "RIGHT", ICON_SPACING, 0)
		end
	end

	RoleCountText:ClearAllPoints()
	RoleCountText:SetWidth(contentWidth)
	RoleCountText:Point("TOP", RaidTargetIcons, "BOTTOM", 0, -BUTTON_SPACING)
	self:UpdateRoleCounts()
	self:UpdateDifficultyButton()

	showButton:SetSize(width, BUTTON_HEIGHT)
	showButton:SetScale(scale)
	panel:SetScale(scale)
	if showButton.mover then showButton.mover:SetScale(scale) end

	local side = SIDE_POINTS[settings.anchorSide] and settings.anchorSide or "TOP"
	showButton:SetAttribute("anchorSide", side)
	local expansion = EXPANSION_POINTS[settings.openDirection]
	showButton:SetAttribute("openDirection", expansion and settings.openDirection)
	local panelPoint, buttonPoint = unpack(expansion or PANEL_POINTS[side])
	panel:ClearAllPoints()
	panel:SetPoint(panelPoint, showButton, buttonPoint)

	if settings.anchor ~= "FREE" then
		local mover = showButton.mover
		local target = settings.anchor == "SCREEN" and E.UIParent or ANCHOR_TARGETS[settings.anchor] and ANCHOR_TARGETS[settings.anchor]()
		if not target then
			E:Print(format(L["Raid Control anchor target %s is unavailable."], settings.anchor))
		elseif mover then
			local point, relativePoint, x, y = unpack(settings.anchor == "SCREEN" and SCREEN_POINTS[side] or SIDE_POINTS[side])
			mover:ClearAllPoints()
			mover:Point(point, target, relativePoint, x * spacing, y * spacing)
			E:SaveMoverPosition("RaidUtility_ShowButtonMover")
		end
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "ApplyRaidControlSettings")
end

local function CheckRaidStatus()
	local inInstance, instanceType = IsInInstance()
	if (((IsRaidLeader() or IsRaidOfficer()) and GetNumRaidMembers() > 0) or (IsPartyLeader() and GetNumPartyMembers() > 0)) and not (inInstance and (instanceType == "pvp" or instanceType == "arena")) then
		return true
	else
		return false
	end
end

function RU:UpdateRoleCounts()
	if not RoleCountText then return end

	local tanks, healers, damage = 0, 0, 0
	local roleNames = {TANK = {}, HEALER = {}, DAMAGER = {}}
	local function CountUnit(unit)
		if not UnitExists(unit) then return end

		local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
		local _, class = UnitClass(unit)
		local roleKey
		if role == "TANK" or (GetPartyAssignment and GetPartyAssignment("MAINTANK", unit)) or (GetPartyAssignment and GetPartyAssignment("MAINASSIST", unit)) then
			tanks = tanks + 1
			roleKey = "TANK"
		elseif role == "HEALER" or ((not role or role == "NONE") and (class == "PRIEST" or class == "DRUID" or class == "SHAMAN" or class == "PALADIN")) then
			healers = healers + 1
			roleKey = "HEALER"
		else
			damage = damage + 1
			roleKey = "DAMAGER"
		end

		local name = UnitName(unit)
		local color = class and _G.RAID_CLASS_COLORS[class]
		if name and color then
			roleNames[roleKey][#roleNames[roleKey] + 1] = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
		elseif name then
			roleNames[roleKey][#roleNames[roleKey] + 1] = name
		end
	end

	local raidCount = GetNumRaidMembers()
	if raidCount > 0 then
		for index = 1, raidCount do
			CountUnit("raid"..index)
		end
	else
		CountUnit("player")
		for index = 1, GetNumPartyMembers() do
			CountUnit("party"..index)
		end
	end

	RoleCountText:SetText(format("%s: %d  %s: %d  %s: %d", L["Tank"], tanks, L["Healer"], healers, L["Damager"], damage))
	self.roleCounts = {tanks, healers, damage}
	self.roleNames = roleNames
end

function RU:OnRoleCountEnter()
	local roleNames = RU.roleNames
	if not roleNames then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:ClearLines()
	for _, role in ipairs({"TANK", "HEALER", "DAMAGER"}) do
		local label = role == "TANK" and L["Tank"] or role == "HEALER" and L["Healer"] or L["Damager"]
		GameTooltip:AddLine(label, 1, 1, 1)
		if #roleNames[role] == 0 then
			GameTooltip:AddLine(L["None"], 0.7, 0.7, 0.7)
		else
			for _, name in ipairs(roleNames[role]) do
				GameTooltip:AddLine(name, 1, 1, 1)
			end
		end
	end
	GameTooltip:Show()
end

function RU:OnRoleCountLeave()
	GameTooltip:Hide()
end

function RU:UpdateDifficultyButton()
	if not DifficultyButton then return end

	local isRaid = GetNumRaidMembers() > 0
	local currentDifficulty
	if isRaid then
		if GetRaidDifficulty then currentDifficulty = GetRaidDifficulty() end
	elseif GetDungeonDifficulty then
		currentDifficulty = GetDungeonDifficulty()
	end
	local difficultyName = currentDifficulty and _G[(isRaid and "RAID_DIFFICULTY" or "DUNGEON_DIFFICULTY")..currentDifficulty]
	DifficultyButton.text:SetText(format("%s: %s", L["Difficulty"], difficultyName or ""))
end

function RU:OpenDifficultyMenu()
	if not EasyMenu then
		E:Print(L["Difficulty controls are unavailable on this client."])
		return
	end

	local isRaid = GetNumRaidMembers() > 0
	local menu = {}
	local difficultyCount = isRaid and 4 or 2
	local getter = isRaid and GetRaidDifficulty or GetDungeonDifficulty
	local setter = isRaid and SetRaidDifficulty or SetDungeonDifficulty
	local prefix = isRaid and "RAID_DIFFICULTY" or "DUNGEON_DIFFICULTY"
	if not getter or not setter then
		E:Print(L["Difficulty controls are unavailable on this client."])
		return
	end

	for index = 1, difficultyCount do
		local difficulty = index
		menu[#menu + 1] = {
			text = _G[prefix..difficulty] or tostring(difficulty),
			checked = function() return getter and getter() == difficulty end,
			func = function()
				if setter then setter(difficulty) end
				CloseDropDownMenus()
				self:UpdateDifficultyButton()
			end,
		}
	end

	if ResetInstances then
		menu[#menu + 1] = {text = _G.RESET_INSTANCES, notCheckable = true, func = ResetInstances}
	end
	EasyMenu(menu, _G.RaidUtilityDifficultyMenu, "cursor", 0, 0, "MENU", 2)
end

function RU:OnTargetIconEnter()
	if not GetRaidControlSettings().showTooltip then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:ClearLines()
	if self:GetID() == 0 then
		GameTooltip:SetText(L["Clear target marker"], 1, 1, 1, 1)
	else
		GameTooltip:SetText(format(L["Mark target with %s"], _G["RAID_TARGET_"..self:GetID()] or self:GetID()), 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

function RU:OnTargetIconLeave()
	GameTooltip:Hide()
end

function RU:OnTargetIconClick()
	SetRaidTarget("target", self:GetID())
end

function RU:OnRoleCheckClick()
	RU:UpdateRoleCounts()
	local counts = RU.roleCounts
	E:Print(format("%s: %d | %s: %d | %s: %d", L["Tank"], counts[1], L["Healer"], counts[2], L["Damager"], counts[3]))
	E:Print(format("%s: %d", L["Total"], counts[1] + counts[2] + counts[3]))
end

function RU:OnCountdownClick()
	if countdownInProgress or not CheckRaidStatus() then return end

	countdownInProgress = true
	local targetIndex = GetRaidTargetIndex and GetRaidTargetIndex("target")
	local count = 10
	local function Countdown()
		if count == 10 then
			SendChatMessage(format(L["Pulling %s in %d seconds!"], targetIndex and format("{rt%s}", targetIndex) or "", count), GetNumRaidMembers() > 0 and "RAID_WARNING" or "PARTY")
		elseif count == 5 then
			SendChatMessage(format(L["%d more seconds!"], count), GetNumRaidMembers() > 0 and "RAID_WARNING" or "PARTY")
		elseif count <= 3 and count > 0 then
			SendChatMessage(tostring(count), GetNumRaidMembers() > 0 and "RAID_WARNING" or "PARTY")
		elseif count == 0 then
			SendChatMessage(L["Pulling!"], GetNumRaidMembers() > 0 and "RAID_WARNING" or "PARTY")
			countdownInProgress = false
			return
		end

		count = count - 1
		RU:ScheduleTimer(Countdown, 1)
	end

	Countdown()
end

-- Function to create buttons in this module
function RU:CreateUtilButton(name, parent, template, width, height, point, relativeto, point2, xOfs, yOfs, text, texture)
	local button = CreateFrame("Button", name, parent, template)
	button:Width(width)
	button:Height(height)
	button:Point(point, relativeto, point2, xOfs, yOfs)
	S:HandleButton(button)

	if text then
		button.text = button:CreateFontString(nil, "OVERLAY", button)
		button.text:FontTemplate()
		button.text:Point("CENTER", button, "CENTER", 0, -1)
		button.text:SetJustifyH("CENTER")
		button.text:SetText(text)
		button:SetFontString(button.text)
	elseif texture then
		button.texture = button:CreateTexture(nil, "OVERLAY", nil)
		button.texture:SetTexture(texture)
		button.texture:Point("TOPLEFT", button, "TOPLEFT", E.mult, -E.mult)
		button.texture:Point("BOTTOMRIGHT", button, "BOTTOMRIGHT", -E.mult, E.mult)
	end

	return button
end

function RU:ToggleRaidUtil(event)
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ToggleRaidUtil")
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		self:ApplyRaidControlSettings()
	end

	if E.private.CustomTweaks.RaidControl and E.db.CustomTweaks.RaidControl.hide then
		RaidUtility_ShowButton:Hide()
		RaidUtilityPanel:Hide()
		if event == "PLAYER_REGEN_ENABLED" then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "ToggleRaidUtil")
		end
		return
	end

	if CheckRaidStatus() then
		RaidUtility_ShowButton:Show()
	else
		RaidUtility_ShowButton:Hide()
		RaidUtilityPanel:Hide()
	end

	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "ToggleRaidUtil")
	end
end

function RU:UpdateCustomRaidControl()
	if not self.Initialized then return end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateCustomRaidControl")
		return
	end

	if E.private.CustomTweaks.RaidControl then
		local template = E.db.CustomTweaks.RaidControl.transparent and "Transparent" or "Default"
		RaidUtility_ShowButton:SetTemplate(template, template == "Default")
		RaidUtilityPanel:SetTemplate(template, template == "Default")
	end

	self:ApplyRaidControlSettings()
	self:ToggleRaidUtil()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateCustomRaidControl")
end

function RU:Initialize()
	if not E.private.general.raidUtility then return end
	self.Initialized = true

	--Create main frame
	RaidUtilityPanel = CreateFrame("Frame", "RaidUtilityPanel", E.UIParent, "SecureHandlerClickTemplate")
	RaidUtilityPanel:SetTemplate("Transparent")
	RaidUtilityPanel:Width(GetRaidControlSettings().width or 230)
	RaidUtilityPanel:Height(GetPanelHeight())
	RaidUtilityPanel:Point("TOP", E.UIParent, "TOP", -400, 1)
	RaidUtilityPanel:SetFrameLevel(3)
	RaidUtilityPanel.toggled = false
	RaidUtilityPanel:SetFrameStrata("HIGH")
	RaidUtilityPanel:SetScript("OnShow", function()
		RU:ApplyRaidControlSettings()
		RaidUtilityPanel.toggled = true
	end)
	RaidUtilityPanel:SetScript("OnHide", function() RaidUtilityPanel.toggled = false end)
	RaidUtilityPanel:Hide()

	local launcherWidth = math.max(180, math.min(GetRaidControlSettings().width or 230, 500))
	RaidUtility_ShowButton = self:CreateUtilButton("RaidUtility_ShowButton", E.UIParent, "SecureHandlerClickTemplate", launcherWidth, 18, "TOP", E.UIParent, "TOP", -400, E.Border, RAID_CONTROL, nil)
	RaidUtility_ShowButton:SetFrameRef("RaidUtilityPanel", RaidUtilityPanel)
	RaidUtility_ShowButton:SetAttribute("_onclick", ([=[
		local raidUtil = self:GetFrameRef("RaidUtilityPanel")
		if raidUtil:IsShown() then
			raidUtil:Hide()
		else
			local side = self:GetAttribute("anchorSide")
			local direction = self:GetAttribute("openDirection")
			local raidUtilPoint, buttonPoint
			if direction == "UP" then
				raidUtilPoint, buttonPoint = "BOTTOM", "TOP"
			elseif direction == "DOWN" then
				raidUtilPoint, buttonPoint = "TOP", "BOTTOM"
			elseif side == "BOTTOM" then
				raidUtilPoint, buttonPoint = "BOTTOM", "TOP"
			elseif side == "LEFT" then
				raidUtilPoint, buttonPoint = "LEFT", "RIGHT"
			elseif side == "RIGHT" then
				raidUtilPoint, buttonPoint = "RIGHT", "LEFT"
			else
				raidUtilPoint, buttonPoint = "TOP", "BOTTOM"
			end

			raidUtil:ClearAllPoints()
			raidUtil:SetPoint(raidUtilPoint, self, buttonPoint)
			raidUtil:Show()
		end
	]=]))
	RaidUtility_ShowButton:SetFrameStrata("HIGH")
	E:CreateMover(RaidUtility_ShowButton, "RaidUtility_ShowButtonMover", L["Raid Control"], nil, nil, nil, "ALL,GENERAL", nil, "general,blizzUIImprovements,raidControl")

	DisbandRaidButton = self:CreateUtilButton("DisbandRaidButton", RaidUtilityPanel, nil, RaidUtilityPanel:GetWidth() * 0.8, 18, "TOP", RaidUtilityPanel, "TOP", 0, -5, L["Disband Group"], nil)
	DisbandRaidButton:SetScript("OnMouseUp", function()
		if CheckRaidStatus() then
			E:StaticPopup_Show("DISBAND_RAID")
		end
	end)

	MainTankButton = self:CreateUtilButton("MainTankButton", RaidUtilityPanel, "SecureActionButtonTemplate", (DisbandRaidButton:GetWidth() / 2) - 2, 18, "TOPLEFT", DisbandRaidButton, "BOTTOMLEFT", 0, -5, MAINTANK, nil)
	MainTankButton:SetAttribute("type", "maintank")
	MainTankButton:SetAttribute("unit", "target")
	MainTankButton:SetAttribute("action", "toggle")

	MainAssistButton = self:CreateUtilButton("MainAssistButton", RaidUtilityPanel, "SecureActionButtonTemplate", (DisbandRaidButton:GetWidth() / 2) - 2, 18, "TOPRIGHT", DisbandRaidButton, "BOTTOMRIGHT", 0, -5, MAINASSIST, nil)
	MainAssistButton:SetAttribute("type", "mainassist")
	MainAssistButton:SetAttribute("unit", "target")
	MainAssistButton:SetAttribute("action", "toggle")

	ReadyCheckButton = self:CreateUtilButton("ReadyCheckButton", RaidUtilityPanel, nil, RaidUtilityPanel:GetWidth() * 0.8, 18, "TOPLEFT", MainTankButton, "BOTTOMLEFT", 0, -5, READY_CHECK, nil)
	ReadyCheckButton:SetScript("OnMouseUp", function()
		if CheckRaidStatus() then
			DoReadyCheck()
		end
	end)
	ReadyCheckButton:SetScript("OnEvent", function(btn)
		if not (IsRaidLeader("player") or IsRaidOfficer("player")) then
			btn:Disable()
		else
			btn:Enable()
		end
	end)
	ReadyCheckButton:RegisterEvent("RAID_ROSTER_UPDATE")
	ReadyCheckButton:RegisterEvent("PARTY_MEMBERS_CHANGED")
	ReadyCheckButton:RegisterEvent("PLAYER_ENTERING_WORLD")

	RaidControlButton = self:CreateUtilButton("RaidControlButton", RaidUtilityPanel, nil, ReadyCheckButton:GetWidth(), 18, "TOPLEFT", ReadyCheckButton, "BOTTOMLEFT", 0, -5, L["Raid Menu"], nil)
	RaidControlButton:SetScript("OnMouseUp", function()
		if InCombatLockdown() then E:Print(ERR_NOT_IN_COMBAT) return end
		ToggleFriendsFrame(5)
	end)

	ConvertRaidButton = self:CreateUtilButton("ConvertRaidButton", RaidUtilityPanel, nil, MainAssistButton:GetWidth(), 18, "TOPRIGHT", ReadyCheckButton, "BOTTOMRIGHT", 0, -5, CONVERT_TO_RAID, nil)
	ConvertRaidButton:SetScript("OnMouseUp", function()
		if CheckRaidStatus() then
			ConvertToRaid()
			SetLootMethod("master", "player")
		end
	end)
	ConvertRaidButton:SetScript("OnEvent", function(btn)
		if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 and IsPartyLeader() then
			btn:Show()
		elseif btn:IsShown() then
			btn:Hide()
		end
	end)
	ConvertRaidButton:RegisterEvent("RAID_ROSTER_UPDATE")
	ConvertRaidButton:RegisterEvent("PARTY_MEMBERS_CHANGED")
	ConvertRaidButton:RegisterEvent("PLAYER_ENTERING_WORLD")

	CountdownButton = self:CreateUtilButton("RaidUtility_CountdownButton", RaidUtilityPanel, nil, 100, BUTTON_HEIGHT, "TOPLEFT", RaidControlButton, "BOTTOMLEFT", 0, -BUTTON_SPACING, L["Countdown"], nil)
	CountdownButton:SetScript("OnMouseUp", function() RU:OnCountdownClick() end)

	RoleCheckButton = self:CreateUtilButton("RaidUtility_RoleCheckButton", RaidUtilityPanel, nil, 100, BUTTON_HEIGHT, "TOPRIGHT", ConvertRaidButton, "BOTTOMRIGHT", 0, -BUTTON_SPACING, L["Role Check"], nil)
	RoleCheckButton:SetScript("OnMouseUp", function() RU:OnRoleCheckClick() end)

	DifficultyButton = self:CreateUtilButton("RaidUtility_DifficultyButton", RaidUtilityPanel, nil, 210, BUTTON_HEIGHT, "TOPLEFT", CountdownButton, "BOTTOMLEFT", 0, -BUTTON_SPACING, L["Difficulty"], nil)
	DifficultyButton:SetScript("OnMouseUp", function() RU:OpenDifficultyMenu() end)
	DifficultyButton:RegisterEvent("RAID_ROSTER_UPDATE")
	DifficultyButton:RegisterEvent("PARTY_MEMBERS_CHANGED")
	DifficultyButton:RegisterEvent("CHAT_MSG_SYSTEM")
	DifficultyButton:SetScript("OnEvent", function() RU:UpdateDifficultyButton() end)
	CreateFrame("Frame", "RaidUtilityDifficultyMenu", E.UIParent, "UIDropDownMenuTemplate")

	RaidTargetIcons = CreateFrame("Frame", "RaidUtility_TargetIcons", RaidUtilityPanel)
	RaidTargetIcons:SetTemplate("Transparent")
	for index = 1, MARKER_COUNT do
		local marker = index == MARKER_COUNT and 0 or index
		local icon = CreateFrame("Button", "RaidUtility_TargetIcon"..index, RaidTargetIcons)
		icon:SetID(marker)
		icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		icon:SetScript("OnClick", RU.OnTargetIconClick)
		icon:SetScript("OnEnter", RU.OnTargetIconEnter)
		icon:SetScript("OnLeave", RU.OnTargetIconLeave)
		if marker > 0 then
			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
			SetRaidTargetIconTexture(icon.texture, marker)
		else
			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexture([[Interface\Buttons\UI-GroupLoot-Pass-Up]])
		end
		S:HandleButton(icon)
	end

	RoleCountText = RaidUtilityPanel:CreateFontString(nil, "OVERLAY")
	RoleCountText:FontTemplate()
	RoleCountText:SetJustifyH("CENTER")
	RoleCountText:SetHeight(ROLE_ROW_HEIGHT)
	RoleCountText:SetTextColor(1, 1, 1)
	RoleCountText:EnableMouse(true)
	RoleCountText:SetScript("OnEnter", RU.OnRoleCountEnter)
	RoleCountText:SetScript("OnLeave", RU.OnRoleCountLeave)
	RaidUtilityPanel:RegisterEvent("RAID_ROSTER_UPDATE")
	RaidUtilityPanel:RegisterEvent("PARTY_MEMBERS_CHANGED")
	RaidUtilityPanel:RegisterEvent("PLAYER_ENTERING_WORLD")
	RaidUtilityPanel:SetScript("OnEvent", function() RU:UpdateRoleCounts() end)

	--Automatically show/hide the frame if we have RaidLeader or RaidOfficer
	self:RegisterEvent("RAID_ROSTER_UPDATE", "ToggleRaidUtil")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ToggleRaidUtil")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ToggleRaidUtil")
	if not self.profileHooked then
		hooksecurefunc(E, "UpdateAll", function()
			self:UpdateCustomRaidControl()
		end)
		self.profileHooked = true
	end
	self:UpdateCustomRaidControl()
	E:Delay(0.1, self.ApplyRaidControlSettings, self)
end

local function InitializeCallback()
	RU:Initialize()
end

E:RegisterModule(RU:GetName(), InitializeCallback)
