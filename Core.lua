local addonName, ns = ...

local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

local function ColorizePrefix()
	return "|cff40d2ffCharacterMountFavorites|r"
end

function ns:Message(text)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: %s", ColorizePrefix(), text))
end

function ns:RefreshAll()
	if ns.MinimapButton then
		ns.MinimapButton:RefreshVisibility()
	end

	if ns.Manager then
		ns.Manager:Refresh()
	end

	if ns.Journal then
		ns.Journal:Refresh()
	end
end

local function HandleSlashCommand(message)
	local command = string.lower(strtrim(message or ""))

	if command == "" or command == "open" or command == "manager" then
		ns.Manager:Open()
	elseif command == "settings" then
		ns.SettingsPanel:Open()
	elseif command == "summon" then
		ns.Mounts:SummonRandomCharacterFavorite()
	else
		ns:Message("Commands: /cmf summon, /cmf open, /cmf settings")
	end
end

local function CreateClearPopup()
	StaticPopupDialogs["CHARACTER_MOUNT_FAVORITES_CLEAR_CONFIRM"] = {
		text = "Clear all Character Favorite mounts for this character?",
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			ns.Database:ClearFavorites()
			ns:RefreshAll()
			ns:Message("Cleared Character Favorites for " .. ns.Database:GetCharacterDisplayName() .. ".")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = STATICPOPUP_NUMDIALOGS,
	}
end

local function InitializeAddon()
	ns.Database:Initialize()
	ns.Mounts:RefreshCache()
	ns.Manager:CreateFrame()
	ns.MinimapButton:Create()
	ns.SettingsPanel:Create()
	CreateClearPopup()

	if MountJournal then
		ns.Journal:Initialize()
	end

	SLASH_CHARACTERMOUNTFAVORITES1 = "/cmf"
	SLASH_CHARACTERMOUNTFAVORITES2 = "/charactermountfavorites"
	SlashCmdList.CHARACTERMOUNTFAVORITES = HandleSlashCommand
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			InitializeAddon()
		elseif arg1 == "Blizzard_Collections" then
			ns.Journal:Initialize()
		end
	elseif event == "COMPANION_UPDATE" or event == "MOUNT_JOURNAL_USABILITY_CHANGED" or event == "NEW_MOUNT_ADDED" then
		ns.Mounts:RefreshCache()
		ns:RefreshAll()
	end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("COMPANION_UPDATE")
eventFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
