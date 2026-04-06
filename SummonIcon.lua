local addonName, ns = ...

local Mounts = ns.Mounts
local SummonIcon = {}
ns.SummonIcon = SummonIcon

local ICON_TEXTURE = 413588
local MACRO_NAME = "CMF"
local MACRO_BODY = "/cmf summon"

local function EnsureMacro()
	local macroIndex = GetMacroIndexByName(MACRO_NAME)
	if macroIndex and macroIndex > 0 then
		EditMacro(macroIndex, MACRO_NAME, ICON_TEXTURE, MACRO_BODY)
		return macroIndex
	end

	local numGlobal, numCharacter = GetNumMacros()
	if numGlobal < MAX_ACCOUNT_MACROS then
		return CreateMacro(MACRO_NAME, ICON_TEXTURE, MACRO_BODY, false)
	end

	if numCharacter < MAX_CHARACTER_MACROS then
		return CreateMacro(MACRO_NAME, ICON_TEXTURE, MACRO_BODY, true)
	end

	ns:Message("No free macro slots are available for the action-bar shortcut.")
	return nil
end

function SummonIcon:Create(parent, anchorPoint, relativeTo, relativePoint, xOffset, yOffset, labelText)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(32, 32)
	button:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	button:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	button:SetBackdropBorderColor(0.45, 0.37, 0.16, 0.9)

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetPoint("TOPLEFT", 5, -5)
	button.Icon:SetPoint("BOTTOMRIGHT", -5, 5)
	button.Icon:SetTexture(ICON_TEXTURE)
	button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	button.Highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.Highlight:SetAllPoints()
	button.Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	button.Highlight:SetBlendMode("ADD")

	button.Pushed = button:CreateTexture(nil, "ARTWORK")
	button.Pushed:SetAllPoints()
	button.Pushed:SetColorTexture(1, 1, 1, 0.12)
	button:SetPushedTexture(button.Pushed)

	button:SetScript("OnClick", function()
		Mounts:SummonRandomCharacterFavorite()
	end)

	button:SetScript("OnDragStart", function()
		local macroIndex = EnsureMacro()
		if macroIndex then
			PickupMacro(macroIndex)
		end
	end)

	button:SetScript("OnEnter", function(selfButton)
		GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Summon Character Favorite Mount")
		GameTooltip:AddLine("Click: Summon a random usable character favorite mount.", 0.9, 0.9, 0.9, true)
		GameTooltip:AddLine("Drag: Put an action-bar shortcut on a bar.", 0.9, 0.9, 0.9, true)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", GameTooltip_Hide)

	if labelText then
		button.Label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.Label:SetPoint("LEFT", button, "RIGHT", 8, 0)
		button.Label:SetJustifyH("LEFT")
		button.Label:SetText(labelText)
	end

	return button
end
