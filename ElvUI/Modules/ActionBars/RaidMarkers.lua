local E, L, V, P, G = unpack(select(2, ...))
local AB = E:GetModule("ActionBars")

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetRaidTargetIndex = GetRaidTargetIndex
local InCombatLockdown = InCombatLockdown
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local UnitExists = UnitExists
local ceil = math.ceil
local floor = math.floor

local MARKER_COUNT = 8
local BUTTON_COUNT = MARKER_COUNT + 1

local function IsMarkerActive(marker)
	local function HasMarker(unit)
		return UnitExists(unit) and GetRaidTargetIndex(unit) == marker
	end

	if HasMarker("target") or HasMarker("targettarget") or HasMarker("mouseover") or HasMarker("focus") or HasMarker("player") or HasMarker("pet") or HasMarker("pettarget") then
		return true
	end

	local raidCount = GetNumRaidMembers()
	if raidCount > 0 then
		for index = 1, raidCount do
			local unit = "raid"..index
			local pet = "raidpet"..index
			if HasMarker(unit) or HasMarker(unit.."target") or HasMarker(pet) or HasMarker(pet.."target") then
				return true
			end
		end
	else
		for index = 1, GetNumPartyMembers() do
			local unit = "party"..index
			local pet = "partypet"..index
			if HasMarker(unit) or HasMarker(unit.."target") or HasMarker(pet) or HasMarker(pet.."target") then
				return true
			end
		end
	end
end

function AB:UpdateRaidMarkersStatus()
	if not self.raidMarkers or not self.raidMarkers.buttons then return end

	for index = 1, MARKER_COUNT do
		local active = IsMarkerActive(index)
		self.raidMarkers.buttons[index].icon:SetDesaturated(not active)
	end
end

function AB:UpdateRaidMarkersBar(resetPosition)
	local frame = self.raidMarkers
	if not frame then return end
	if InCombatLockdown() then
		self.NeedsUpdateRaidMarkersBar = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local settings = E.db.actionbar.raidmarkers
	local size = settings.buttonSize
	local spacing = settings.buttonSpacing
	local buttonsPerRow = math.max(1, math.min(settings.buttonsPerRow, BUTTON_COUNT))
	local rows, columns
	if settings.orientation == "VERTICAL" then
		rows = math.min(BUTTON_COUNT, buttonsPerRow)
		columns = ceil(BUTTON_COUNT / buttonsPerRow)
	else
		rows = ceil(BUTTON_COUNT / buttonsPerRow)
		columns = math.min(BUTTON_COUNT, buttonsPerRow)
	end
	local width = (size * columns) + (spacing * (columns + 1))
	local height = (size * rows) + (spacing * (rows + 1))

	frame:SetSize(width, height)
	for index = 1, BUTTON_COUNT do
		local button = frame.buttons[index]
		local row, column
		if settings.orientation == "VERTICAL" then
			column = floor((index - 1) / buttonsPerRow)
			row = (index - 1) % buttonsPerRow
			if settings.sort == "DESCENDING" then
				row = buttonsPerRow - row - 1
			end
		else
			row = floor((index - 1) / buttonsPerRow)
			column = (index - 1) % buttonsPerRow
			if settings.sort == "DESCENDING" then
				column = buttonsPerRow - column - 1
			end
		end

		button:ClearAllPoints()
		button:SetSize(size, size)
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", spacing + column * (size + spacing), -spacing - row * (size + spacing))
	end

	if resetPosition then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", E.UIParent, "CENTER")
	end

	if settings.enabled then
		frame:Show()
		if settings.mouseover and not frame:IsMouseOver() then
			frame:SetAlpha(0)
		else
			frame:SetAlpha(1)
		end
		if frame.mover then E:EnableMover(frame.mover:GetName()) end
	else
		frame:Hide()
		if frame.mover then E:DisableMover(frame.mover:GetName()) end
	end

	self:UpdateRaidMarkersStatus()
end

function AB:SetupRaidMarkersBar()
	local frame = CreateFrame("Frame", "ElvUI_RaidMarkers", E.UIParent)
	frame:EnableMouse(true)
	frame:SetFrameStrata("MEDIUM")
	frame:SetTemplate("Transparent")
	frame.buttons = {}
	self.raidMarkers = frame

	for index = 1, BUTTON_COUNT do
		local button = CreateFrame("Button", "ElvUI_RaidMarkersButton"..index, frame, "SecureActionButtonTemplate")
		button:SetTemplate("Default", true)
		button:SetID(index)
		button:RegisterForClicks("AnyDown")
		button:SetAttribute("type1", "macro")
		button:SetAttribute("macrotext1", index == BUTTON_COUNT and "/tm 0" or "/tm "..index)
		button.icon = button:CreateTexture(nil, "ARTWORK")
		button.icon:SetAllPoints()

		if index == BUTTON_COUNT then
			button.icon:SetTexture([[Interface\BUTTONS\UI-GroupLoot-Pass-Up]])
			button.icon:SetDesaturated(true)
		else
			button.icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
			SetRaidTargetIconTexture(button.icon, index)
		end

		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:AddLine(self:GetID() == BUTTON_COUNT and L["Clear Raid Marker"] or L["Raid Marker"].." "..self:GetID(), 1, 1, 1)
			GameTooltip:Show()
			if E.db.actionbar.raidmarkers.mouseover then
				frame:SetAlpha(1)
			end
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
			if E.db.actionbar.raidmarkers.mouseover and not frame:IsMouseOver() then
				frame:SetAlpha(0)
			end
		end)
		button:StyleButton()
		frame.buttons[index] = button
	end

	frame:SetScript("OnEnter", function()
		if E.db.actionbar.raidmarkers.mouseover then
			frame:SetAlpha(1)
		end
	end)
	frame:SetScript("OnLeave", function()
		if E.db.actionbar.raidmarkers.mouseover then
			frame:SetAlpha(0)
		end
	end)

	self:UpdateRaidMarkersBar(true)
	E:CreateMover(frame, "ElvUI_RaidMarkersMover", L["Raid Markers"], nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,raidmarkers")
	self:UpdateRaidMarkersBar()

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("PLAYER_TARGET_CHANGED")
	events:RegisterEvent("RAID_TARGET_UPDATE")
	events:RegisterEvent("PARTY_MEMBERS_CHANGED")
	events:RegisterEvent("RAID_ROSTER_UPDATE")
	events:RegisterEvent("UNIT_TARGET")
	events:SetScript("OnEvent", function()
		AB:UpdateRaidMarkersStatus()
	end)
end
