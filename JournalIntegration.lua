local addonName, ns = ...

local Mounts = ns.Mounts
local Journal = {}
ns.Journal = Journal

local function AddTooltipLine(mountID)
	if not ns.settings.enableTooltipLine or not mountID then
		return
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Character Favorite: " .. (Mounts:IsCharacterFavorite(mountID) and YES or NO), 0.25, 0.82, 1)
	GameTooltip:Show()
end

function Journal:CreateRowToggle(button)
	if button.CMFCharacterFavorite then
		return button.CMFCharacterFavorite
	end

	local toggle = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
	toggle:SetSize(20, 20)
	toggle:SetPoint("RIGHT", -6, 0)
	toggle:SetScript("OnClick", function(checkButton)
		if not button.mountID then
			return
		end

		Mounts:SetCharacterFavorite(button.mountID, checkButton:GetChecked())
		ns:RefreshAll()
	end)

	toggle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Character Favorite")
		GameTooltip:AddLine("Saved only for " .. ns.Database:GetCharacterDisplayName(), 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)

	toggle:SetScript("OnLeave", GameTooltip_Hide)
	button.CMFCharacterFavorite = toggle
	return toggle
end

function Journal:UpdateRowButton(button)
	local toggle = self:CreateRowToggle(button)
	toggle:SetShown(ns.settings.showJournalMarker)

	if button.mountID then
		toggle:SetChecked(Mounts:IsCharacterFavorite(button.mountID))
	end
end

function Journal:RefreshSelectedMount()
	if not self.selectedCheckbox or not MountJournal then
		return
	end

	local selectedMountID = MountJournal.selectedMountID
	self.selectedCheckbox:SetShown(ns.settings.showJournalMarker and selectedMountID ~= nil)
	self.selectedCheckbox:SetEnabled(ns.settings.enabled)
	self.selectedCheckbox:SetChecked(selectedMountID and Mounts:IsCharacterFavorite(selectedMountID) or false)

	if self.summonButton then
		self.summonButton:SetEnabled(ns.settings.enabled)
	end
end

function Journal:CreateSelectedMountControls()
	if self.selectedCheckbox or not MountJournal then
		return
	end

	local selectedCheckbox = CreateFrame("CheckButton", nil, MountJournal.MountDisplay, "UICheckButtonTemplate")
	selectedCheckbox:SetPoint("BOTTOMLEFT", MountJournal.MountDisplay, "BOTTOMLEFT", 12, 14)
	selectedCheckbox.text:SetText("Character Favorite")
	selectedCheckbox:SetScript("OnClick", function(button)
		if MountJournal.selectedMountID then
			Mounts:SetCharacterFavorite(MountJournal.selectedMountID, button:GetChecked())
			ns:RefreshAll()
		end
	end)
	selectedCheckbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine("Character Favorite")
		GameTooltip:AddLine("This toggle affects only " .. ns.Database:GetCharacterDisplayName() .. ".", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	selectedCheckbox:SetScript("OnLeave", GameTooltip_Hide)
	self.selectedCheckbox = selectedCheckbox

	local summonButton = ns.SummonIcon:Create(
		MountJournal,
		"TOPRIGHT",
		MountJournal.SummonRandomFavoriteSpellFrame,
		"BOTTOMRIGHT",
		0,
		-8,
		nil
	)
	self.summonButton = summonButton

	local managerButton = CreateFrame("Button", nil, MountJournal, "UIPanelButtonTemplate")
	managerButton:SetSize(166, 22)
	managerButton:SetPoint("RIGHT", summonButton, "LEFT", -8, 0)
	managerButton:SetText("Open Character Favorites")
	managerButton:SetScript("OnClick", function()
		ns.Manager:Open()
	end)
	self.managerButton = managerButton
end

function Journal:Initialize()
	if self.initialized or not MountJournal then
		return
	end

	self.initialized = true
	self:CreateSelectedMountControls()

	hooksecurefunc("MountJournal_InitMountButton", function(button)
		self:UpdateRowButton(button)
	end)

	hooksecurefunc("MountJournal_UpdateMountDisplay", function()
		self:RefreshSelectedMount()
	end)

	hooksecurefunc("MountJournalMountButton_UpdateTooltip", function(button)
		AddTooltipLine(button.mountID)
	end)

	if MountJournal:IsShown() then
		MountJournal_UpdateMountList()
		self:RefreshSelectedMount()
	end
end

function Journal:Refresh()
	if not self.initialized then
		return
	end

	if MountJournal and MountJournal:IsShown() then
		MountJournal_UpdateMountList()
	end
	self:RefreshSelectedMount()
end
