local addonName, ns = ...

local Mounts = ns.Mounts
local Manager = {}
ns.Manager = Manager

local ROW_HEIGHT = 28
local ROW_COUNT = 11

local function CreateHeaderButton(parent, text, width, anchorPoint, relativeTo, relativePoint, xOffset, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, 18)
	button:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, 0)

	button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Label:SetAllPoints()
	button.Label:SetJustifyH("LEFT")
	button.Label:SetText(text)

	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(self)
		self.Label:SetTextColor(1, 0.82, 0)
	end)
	button:SetScript("OnLeave", function(self)
		self.Label:SetTextColor(1, 1, 1)
	end)

	return button
end

local function SetTooltipForMount(owner, mountData)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetMountBySpellID(mountData.spellID)

	if ns.settings.enableTooltipLine then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Character Favorite: " .. (Mounts:IsCharacterFavorite(mountData.mountID) and YES or NO), 0.25, 0.82, 1)
	end

	GameTooltip:Show()
end

function Manager:CreateRow(index)
	local row = CreateFrame("Button", nil, self.frame.ListInset)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", self.frame.ListInset, "TOPLEFT", 10, -28 - ((index - 1) * ROW_HEIGHT))
	row:SetPoint("TOPRIGHT", self.frame.ListInset, "TOPRIGHT", -28, -28 - ((index - 1) * ROW_HEIGHT))
	row:RegisterForClicks("LeftButtonUp")

	row.Background = row:CreateTexture(nil, "BACKGROUND")
	row.Background:SetAllPoints()
	row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.02 or 0.06)

	row.Icon = row:CreateTexture(nil, "ARTWORK")
	row.Icon:SetSize(22, 22)
	row.Icon:SetPoint("LEFT", 4, 0)

	row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 8, 0)
	row.Name:SetWidth(360)
	row.Name:SetJustifyH("LEFT")

	row.Type = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.Type:SetPoint("LEFT", row.Name, "RIGHT", 8, 0)
	row.Type:SetWidth(160)
	row.Type:SetJustifyH("LEFT")

	row.Favorite = CreateFrame("CheckButton", nil, row)
	row.Favorite:SetSize(22, 22)
	row.Favorite:SetPoint("RIGHT", -8, 0)
	row.Favorite:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	row.Favorite:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	row.Favorite:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	row.Favorite:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	row.Favorite:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	row.Favorite:SetScript("OnClick", function(button)
		if not row.mountData then
			return
		end

		Mounts:SetCharacterFavorite(row.mountData.mountID, button:GetChecked())
		ns:RefreshAll()
	end)
	row.Favorite:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		GameTooltip:AddLine("Character Favorite")
		GameTooltip:AddLine("Stored only for " .. ns.Database:GetCharacterDisplayName(), 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	row.Favorite:SetScript("OnLeave", GameTooltip_Hide)

	row:SetScript("OnClick", function()
		if row.mountData then
			local newValue = Mounts:ToggleCharacterFavorite(row.mountData.mountID)
			row.Favorite:SetChecked(newValue)
			ns:RefreshAll()
		end
	end)

	row:SetScript("OnEnter", function()
		if row.mountData then
			row.Background:SetColorTexture(1, 1, 1, 0.10)
			SetTooltipForMount(row, row.mountData)
		end
	end)

	row:SetScript("OnLeave", function()
		row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.02 or 0.06)
		GameTooltip:Hide()
	end)

	return row
end

function Manager:UpdateStatusText()
	local favoriteCount = ns.Database:GetFavoriteCount()
	local totalCount = #self.filteredEntries
	self.frame.CharacterLabel:SetText("Character Favorites for " .. ns.Database:GetCharacterDisplayName())
	self.frame.StatusText:SetText(string.format("%d collected mounts shown, %d character favorites saved.", totalCount, favoriteCount))
end

function Manager:RefreshRows()
	if not self.frame or not self.frame:IsShown() then
		return
	end

	self.filteredEntries = Mounts:GetManagerEntries(self.searchText, self.filters, self.sortState)
	self.scrollOffset = math.min(self.scrollOffset, math.max(0, #self.filteredEntries - ROW_COUNT))
	self.scrollOffset = math.max(self.scrollOffset, 0)

	self.frame.ScrollBar:SetMinMaxValues(0, math.max(0, #self.filteredEntries - ROW_COUNT))
	self.suspendScrollUpdate = true
	self.frame.ScrollBar:SetValue(self.scrollOffset)
	self.suspendScrollUpdate = false
	self.frame.EmptyText:SetShown(#self.filteredEntries == 0)

	for index, row in ipairs(self.rows) do
		local dataIndex = index + self.scrollOffset
		local mountData = self.filteredEntries[dataIndex]

		row.mountData = mountData
		row:SetShown(mountData ~= nil)

		if mountData then
			row.Icon:SetTexture(mountData.icon)
			row.Name:SetText(mountData.name)
			row.Type:SetText(Mounts:GetMountTypeLabel(mountData))
			row.Favorite:SetChecked(Mounts:IsCharacterFavorite(mountData.mountID))
		end
	end

	self:UpdateSortHeaderText()
	self:UpdateStatusText()
end

function Manager:UpdateSortHeaderText()
	local directionText = self.sortState.descending and "v" or "^"
	self.frame.NameHeader.Label:SetText("Name" .. (self.sortState.key == "name" and (" " .. directionText) or ""))
	self.frame.TypeHeader.Label:SetText("Type" .. (self.sortState.key == "type" and (" " .. directionText) or ""))
	self.frame.FavoriteHeader.Label:SetText("Favorite" .. (self.sortState.key == "favorite" and (" " .. directionText) or ""))
end

function Manager:SetSortKey(key)
	if self.sortState.key == key then
		self.sortState.descending = not self.sortState.descending
	else
		self.sortState.key = key
		self.sortState.descending = false
	end

	self:RefreshRows()
end

function Manager:CreateFrame()
	if self.frame then
		return
	end

	self.searchText = ""
	self.filters = {
		ground = false,
		aquatic = false,
		dragonriding = false,
		usableOnly = false,
	}
	self.sortState = {
		key = "name",
		descending = false,
	}
	self.scrollOffset = 0
	self.filteredEntries = {}
	self.rows = {}

	local frame = CreateFrame("Frame", "CharacterMountFavoritesManagerFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(880, 620)
	frame:SetPoint("CENTER")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	frame:SetFrameStrata("DIALOG")

	frame.TitleText:SetText("Character Mount Favorites")

	frame.CharacterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	frame.CharacterLabel:SetPoint("TOPLEFT", 16, -34)
	frame.CharacterLabel:SetJustifyH("LEFT")

	frame.StatusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.StatusText:SetPoint("TOPLEFT", frame.CharacterLabel, "BOTTOMLEFT", 0, -6)
	frame.StatusText:SetTextColor(0.85, 0.85, 0.85)

	frame.SearchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	frame.SearchBox:SetSize(240, 20)
	frame.SearchBox:SetPoint("TOPRIGHT", -32, -38)
	frame.SearchBox:SetScript("OnTextChanged", function(editBox)
		SearchBoxTemplate_OnTextChanged(editBox)
		self.searchText = editBox:GetText() or ""
		self.scrollOffset = 0
		self:RefreshRows()
	end)

	frame.FilterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.FilterLabel:SetPoint("TOPLEFT", frame.StatusText, "BOTTOMLEFT", 0, -18)
	frame.FilterLabel:SetText("Filters")

	local function CreateFilterCheckbox(key, label, anchorPoint, relativeTo, relativePoint, xOffset)
		local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
		check:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, 0)
		check.text:SetText(label)
		check:SetScript("OnClick", function(button)
			self.filters[key] = button:GetChecked()
			self.scrollOffset = 0
			self:RefreshRows()
		end)
		return check
	end

	frame.GroundFilter = CreateFilterCheckbox("ground", "Ground", "TOPLEFT", frame.FilterLabel, "BOTTOMLEFT", -4)
	frame.AquaticFilter = CreateFilterCheckbox("aquatic", "Aquatic", "LEFT", frame.GroundFilter, "RIGHT", 160)
	frame.DragonridingFilter = CreateFilterCheckbox("dragonriding", "Dragonriding / Skyriding", "LEFT", frame.AquaticFilter, "RIGHT", 96)
	frame.UsableOnlyFilter = CreateFilterCheckbox("usableOnly", "Usable only", "LEFT", frame.DragonridingFilter, "RIGHT", 156)

	frame.ListInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	frame.ListInset:SetPoint("TOPLEFT", frame.GroundFilter, "BOTTOMLEFT", 4, -14)
	frame.ListInset:SetPoint("BOTTOMRIGHT", -28, 96)

	frame.NameHeader = CreateHeaderButton(frame.ListInset, "Name", 230, "TOPLEFT", frame.ListInset, "TOPLEFT", 12, function()
		self:SetSortKey("name")
	end)
	frame.TypeHeader = CreateHeaderButton(frame.ListInset, "Type", 110, "LEFT", frame.NameHeader, "RIGHT", 148, function()
		self:SetSortKey("type")
	end)
	frame.FavoriteHeader = CreateHeaderButton(frame.ListInset, "Favorite", 70, "TOPRIGHT", frame.ListInset, "TOPRIGHT", -10, function()
		self:SetSortKey("favorite")
	end)

	self.frame = frame

	for index = 1, ROW_COUNT do
		table.insert(self.rows, self:CreateRow(index))
	end

	frame.EmptyText = frame.ListInset:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
	frame.EmptyText:SetPoint("CENTER")
	frame.EmptyText:SetText("No mounts match the current filters.")
	frame.EmptyText:Hide()

	frame.ScrollBar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
	frame.ScrollBar:SetPoint("TOPRIGHT", frame.ListInset, "TOPRIGHT", 20, -28)
	frame.ScrollBar:SetPoint("BOTTOMRIGHT", frame.ListInset, "BOTTOMRIGHT", 20, 8)
	frame.ScrollBar:SetMinMaxValues(0, 0)
	frame.ScrollBar:SetValueStep(1)
	frame.ScrollBar:SetObeyStepOnDrag(true)
	frame.ScrollBar:SetScript("OnValueChanged", function(_, value)
		if self.suspendScrollUpdate then
			return
		end
		self.scrollOffset = math.floor(value + 0.5)
		self:RefreshRows()
	end)

	frame:SetScript("OnMouseWheel", function(_, delta)
		local currentValue = frame.ScrollBar:GetValue()
		frame.ScrollBar:SetValue(currentValue - delta)
	end)
	frame:EnableMouseWheel(true)

	frame.Footer = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	frame.Footer:SetPoint("BOTTOMLEFT", 12, 12)
	frame.Footer:SetPoint("BOTTOMRIGHT", -12, 12)
	frame.Footer:SetHeight(58)

	frame.SummonIcon = ns.SummonIcon:Create(
		frame.Footer,
		"LEFT",
		frame.Footer,
		"LEFT",
		10,
		0,
		nil
	)

	frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.CloseButton:SetSize(90, 24)
	frame.CloseButton:SetPoint("RIGHT", frame.Footer, "RIGHT", -12, 0)
	frame.CloseButton:SetText(CLOSE)
	frame.CloseButton:SetScript("OnClick", function()
		frame:Hide()
	end)

end

function Manager:Open()
	self:CreateFrame()
	self.frame:Show()
	self:RefreshRows()
end

function Manager:Toggle()
	self:CreateFrame()
	self.frame:SetShown(not self.frame:IsShown())
	if self.frame:IsShown() then
		self:RefreshRows()
	end
end

function Manager:Refresh()
	if self.frame and self.frame:IsShown() then
		self:RefreshRows()
	end
end
