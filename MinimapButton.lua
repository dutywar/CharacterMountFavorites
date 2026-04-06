local addonName, ns = ...

local Mounts = ns.Mounts
local MinimapButton = {}
ns.MinimapButton = MinimapButton

local function UpdatePosition(button)
	local settings = ns.Database:GetMinimapSettings()
	local angle = math.rad(settings.angle or 220)
	local radius = (Minimap:GetWidth() / 2) + 4
	local x = math.cos(angle) * radius
	local y = math.sin(angle) * radius

	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:RefreshVisibility()
	if not self.button then
		return
	end

	self.button:SetShown(ns.settings.showMinimapButton)
	UpdatePosition(self.button)
end

function MinimapButton:Create()
	if self.button then
		return
	end

	local button = CreateFrame("Button", "CharacterMountFavoritesMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetMovable(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	button.Background = button:CreateTexture(nil, "BACKGROUND")
	button.Background:SetSize(54, 54)
	button.Background:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button.Background:SetPoint("TOPLEFT")

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetSize(18, 18)
	button.Icon:SetTexture(134400)
	button.Icon:SetPoint("CENTER", 0, 0)

	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	button:GetHighlightTexture():SetBlendMode("ADD")

	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function(dragButton)
			local cursorX, cursorY = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			local centerX, centerY = Minimap:GetCenter()
			local x = (cursorX / scale) - centerX
			local y = (cursorY / scale) - centerY

			local angle
			if x == 0 then
				angle = y >= 0 and 90 or 270
			else
				angle = math.deg(math.atan(y / x))
				if x < 0 then
					angle = angle + 180
				elseif y < 0 then
					angle = angle + 360
				end
			end

			ns.Database:GetMinimapSettings().angle = angle
			UpdatePosition(dragButton)
		end)
	end)

	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		UpdatePosition(self)
	end)

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns.Manager:Open()
		else
			Mounts:SummonRandomCharacterFavorite()
		end
	end)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("CharacterMountFavorites")
		GameTooltip:AddLine("Left-click: Summon Character Favorite Mount", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("Right-click: Open Character Favorites Manager", 0.9, 0.9, 0.9)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", GameTooltip_Hide)

	self.button = button
	self:RefreshVisibility()
end
