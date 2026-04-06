local addonName, ns = ...

local Database = {}
ns.Database = Database

local defaults = {
	version = 1,
	global = {
		settings = {
			enabled = true,
			showMinimapButton = true,
			showJournalMarker = true,
			enableTooltipLine = true,
			useOnlyCharacterFavorites = false,
			fallbackBehavior = "ALL_USABLE",
			preferRegionAppropriate = true,
			avoidUnusableMounts = true,
		},
		minimap = {
			angle = 220,
		},
	},
	characters = {},
}

local function CopyDefaults(source, target)
	if type(source) ~= "table" then
		return target
	end

	if type(target) ~= "table" then
		target = {}
	end

	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = CopyDefaults(value, target[key])
		elseif target[key] == nil then
			target[key] = value
		end
	end

	return target
end

local function GetPlayerName()
	local name = UnitName("player")
	return name or UNKNOWN
end

local function GetRealmNameSafe()
	local realmName = GetRealmName()
	return realmName or "Unknown Realm"
end

function Database:GetCharacterKey()
	return string.format("%s - %s", GetRealmNameSafe(), GetPlayerName())
end

function Database:GetCharacterDisplayName()
	return string.format("%s (%s)", GetPlayerName(), GetRealmNameSafe())
end

function Database:Initialize()
	CharacterMountFavoritesDB = CopyDefaults(defaults, CharacterMountFavoritesDB)

	self.db = CharacterMountFavoritesDB
	self.charKey = self:GetCharacterKey()
	self.db.characters[self.charKey] = CopyDefaults({
		favorites = {},
	}, self.db.characters[self.charKey])

	ns.db = self.db
	ns.settings = self.db.global.settings
	ns.charDB = self.db.characters[self.charKey]
end

function Database:IsFavorite(mountID)
	return mountID and ns.charDB and ns.charDB.favorites and ns.charDB.favorites[mountID] == true or false
end

function Database:SetFavorite(mountID, isFavorite)
	if not mountID then
		return
	end

	ns.charDB.favorites = ns.charDB.favorites or {}

	if isFavorite then
		ns.charDB.favorites[mountID] = true
	else
		ns.charDB.favorites[mountID] = nil
	end
end

function Database:ToggleFavorite(mountID)
	local newValue = not self:IsFavorite(mountID)
	self:SetFavorite(mountID, newValue)
	return newValue
end

function Database:ClearFavorites()
	ns.charDB.favorites = {}
end

function Database:GetFavoriteCount()
	local count = 0
	for _ in pairs(ns.charDB.favorites or {}) do
		count = count + 1
	end
	return count
end

function Database:GetMinimapSettings()
	return ns.db.global.minimap
end
