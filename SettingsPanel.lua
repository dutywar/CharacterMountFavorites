local addonName, ns = ...

local Mounts = ns.Mounts
local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local FALLBACK_OPTIONS = {
	{ value = "ALL_USABLE", text = "All usable mounts" },
	{ value = "BLIZZARD_FAVORITES", text = "Blizzard favorites" },
	{ value = "NONE", text = "None" },
}

local function CreateSection(parent, title, width, height, anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	local frame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate3")
	frame:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	frame:SetSize(width, height)

	frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.Title:SetPoint("TOPLEFT", 12, -10)
	frame.Title:SetText(title)

	return frame
end

local function CreateInfoText(parent, text, anchorPoint, relativeTo, relativePoint, xOffset, yOffset, width)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	label:SetWidth(width)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("TOP")
	label:SetTextColor(0.85, 0.85, 0.85)
	label:SetText(text)
	return label
end

local function CreateCheckbox(parent, text, tooltip, anchorPoint, relativeTo, relativePoint, xOffset, yOffset, getValue, setValue)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	check.text:SetText(text)

	if tooltip and tooltip ~= "" then
		check:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(text)
			GameTooltip:AddLine(tooltip, 0.9, 0.9, 0.9, true)
			GameTooltip:Show()
		end)
		check:SetScript("OnLeave", GameTooltip_Hide)
	end

	check:SetScript("OnClick", function(button)
		setValue(button:GetChecked())
	end)

	check.RefreshValue = function(self)
		self:SetChecked(getValue())
	end

	return check
end

local function CreateActionButton(parent, text, width, anchorPoint, relativeTo, relativePoint, xOffset, yOffset, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 24)
	button:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
	button:SetText(text)
	button:SetScript("OnClick", onClick)
	return button
end

local function InitializeFallbackDropdown(dropdown)
	UIDropDownMenu_Initialize(dropdown, function()
		for _, option in ipairs(FALLBACK_OPTIONS) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.text
			info.value = option.value
			info.func = function()
				ns.settings.fallbackBehavior = option.value
				UIDropDownMenu_SetSelectedValue(dropdown, option.value)
				ns.SettingsPanel:Refresh()
			end
			info.checked = option.value == ns.settings.fallbackBehavior
			UIDropDownMenu_AddButton(info)
		end
	end)
end

function SettingsPanel:Refresh()
	if not self.frame then
		return
	end

	self.enableCheckbox:RefreshValue()
	self.minimapCheckbox:RefreshValue()
	self.journalCheckbox:RefreshValue()
	self.tooltipCheckbox:RefreshValue()
	self.useOnlyCheckbox:RefreshValue()
	self.preferRegionCheckbox:RefreshValue()
	self.avoidUnusableCheckbox:RefreshValue()

	local selectedText = "All usable mounts"
	for _, option in ipairs(FALLBACK_OPTIONS) do
		if option.value == ns.settings.fallbackBehavior then
			selectedText = option.text
			break
		end
	end

	UIDropDownMenu_SetSelectedValue(self.fallbackDropdown, ns.settings.fallbackBehavior)
	UIDropDownMenu_SetText(self.fallbackDropdown, selectedText)
	UIDropDownMenu_DisableDropDown(self.fallbackDropdown)
	if not ns.settings.useOnlyCharacterFavorites then
		UIDropDownMenu_EnableDropDown(self.fallbackDropdown)
	end
end

function SettingsPanel:Create()
	if self.frame then
		return
	end

	local frame = CreateFrame("Frame", addonName .. "SettingsPanel", UIParent)
	frame.name = "Character Mount Favorites"
	frame:SetSize(900, 720)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Character Mount Favorites")

	local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetText("Per-character mount favorites that do not modify Blizzard's account-wide favorites.")
	subtitle:SetTextColor(0.85, 0.85, 0.85)

	local generalSection = CreateSection(frame, "General", 390, 190, "TOPLEFT", subtitle, "BOTTOMLEFT", 0, -18)
	local summonSection = CreateSection(frame, "Summon Behavior", 390, 190, "TOPLEFT", generalSection, "TOPRIGHT", 14, 0)
	local managementSection = CreateSection(frame, "Mount Management", 794, 170, "TOPLEFT", generalSection, "BOTTOMLEFT", 0, -16)

	local generalInfo = CreateInfoText(
		generalSection,
		"Basic visibility and integration options for this character-favorites system.",
		"TOPLEFT",
		generalSection.Title,
		"BOTTOMLEFT",
		0,
		-6,
		350
	)

	self.enableCheckbox = CreateCheckbox(
		generalSection,
		"Enable addon",
		"Disables CharacterMountFavorites summon behavior without removing saved data.",
		"TOPLEFT",
		generalInfo,
		"BOTTOMLEFT",
		-4,
		-12,
		function() return ns.settings.enabled end,
		function(value) ns.settings.enabled = value; ns:RefreshAll() end
	)

	self.minimapCheckbox = CreateCheckbox(
		generalSection,
		"Show minimap button",
		"Left-click summons a Character Favorite mount. Right-click opens the manager.",
		"TOPLEFT",
		generalInfo,
		"BOTTOMLEFT",
		184,
		-12,
		function() return ns.settings.showMinimapButton end,
		function(value) ns.settings.showMinimapButton = value; ns:RefreshAll() end
	)

	self.journalCheckbox = CreateCheckbox(
		generalSection,
		"Show Character Favorite marker in Mount Journal",
		"Adds a Character Favorite toggle to mount rows and a labeled checkbox on the selected mount display.",
		"TOPLEFT",
		self.minimapCheckbox,
		"BOTTOMLEFT",
		-184,
		-14,
		function() return ns.settings.showJournalMarker end,
		function(value) ns.settings.showJournalMarker = value; ns:RefreshAll() end
	)

	self.tooltipCheckbox = CreateCheckbox(
		generalSection,
		"Enable tooltip line",
		"Adds 'Character Favorite: Yes/No' to Mount Journal and addon list tooltips.",
		"TOPLEFT",
		self.minimapCheckbox,
		"BOTTOMLEFT",
		0,
		-14,
		function() return ns.settings.enableTooltipLine end,
		function(value) ns.settings.enableTooltipLine = value; ns:RefreshAll() end
	)

	local summonInfo = CreateInfoText(
		summonSection,
		"Control how the random summon chooses mounts and what happens when this character has no favorites.",
		"TOPLEFT",
		summonSection.Title,
		"BOTTOMLEFT",
		0,
		-6,
		350
	)

	self.useOnlyCheckbox = CreateCheckbox(
		summonSection,
		"Use only character favorites",
		"When enabled, the summon button will never fall back to non-character-favorite mounts.",
		"TOPLEFT",
		summonInfo,
		"BOTTOMLEFT",
		-4,
		-12,
		function() return ns.settings.useOnlyCharacterFavorites end,
		function(value) ns.settings.useOnlyCharacterFavorites = value; self:Refresh() end
	)

	local fallbackLabel = summonSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fallbackLabel:SetPoint("TOPLEFT", summonInfo, "BOTTOMLEFT", 188, -12)
	fallbackLabel:SetText("Fallback behavior")

	self.fallbackDropdown = CreateFrame("Frame", addonName .. "FallbackDropdown", summonSection, "UIDropDownMenuTemplate")
	self.fallbackDropdown:SetPoint("TOPLEFT", fallbackLabel, "BOTTOMLEFT", -16, -2)
	UIDropDownMenu_SetWidth(self.fallbackDropdown, 170)
	InitializeFallbackDropdown(self.fallbackDropdown)

	self.preferRegionCheckbox = CreateCheckbox(
		summonSection,
		"Prefer region-appropriate mounts",
		"Prefers aquatic mounts while swimming, flying or skyriding mounts in flyable areas, and ground mounts elsewhere when available.",
		"TOPLEFT",
		self.useOnlyCheckbox,
		"BOTTOMLEFT",
		0,
		-14,
		function() return ns.settings.preferRegionAppropriate end,
		function(value) ns.settings.preferRegionAppropriate = value end
	)

	self.avoidUnusableCheckbox = CreateCheckbox(
		summonSection,
		"Avoid unusable mounts in current zone",
		"Checks current mount usability before random selection so zone restrictions are respected.",
		"TOPLEFT",
		self.fallbackDropdown,
		"BOTTOMLEFT",
		16,
		-14,
		function() return ns.settings.avoidUnusableMounts end,
		function(value) ns.settings.avoidUnusableMounts = value end
	)

	local managementInfo = CreateInfoText(
		managementSection,
		"Open the full manager, summon a random character favorite, or clear this character's saved favorites.",
		"TOPLEFT",
		managementSection.Title,
		"BOTTOMLEFT",
		0,
		-6,
		760
	)

	local summonIcon = ns.SummonIcon:Create(
		managementSection,
		"TOPLEFT",
		managementInfo,
		"BOTTOMLEFT",
		12,
		-14,
		nil
	)

	local openManagerButton = CreateActionButton(
		managementSection,
		"Open Character Favorites Manager",
		230,
		"TOPLEFT",
		summonIcon,
		"TOPRIGHT",
		16,
		4,
		function() ns.Manager:Open() end
	)

	CreateActionButton(
		managementSection,
		"Clear character favorites for this character",
		260,
		"TOPLEFT",
		openManagerButton,
		"BOTTOMLEFT",
		0,
		-10,
		function()
			StaticPopup_Show("CHARACTER_MOUNT_FAVORITES_CLEAR_CONFIRM")
		end
	)

	frame:SetScript("OnShow", function()
		self:Refresh()
	end)

	local category = Settings.RegisterCanvasLayoutCategory(frame, "Character Mount Favorites")
	Settings.RegisterAddOnCategory(category)

	self.frame = frame
	self.category = category
end

function SettingsPanel:Open()
	if not self.category then
		self:Create()
	end

	Settings.OpenToCategory(self.category:GetID())
end
