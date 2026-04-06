local addonName, ns = ...

local Database = ns.Database
local Mounts = {}
ns.Mounts = Mounts

local MOUNT_TYPE_LABELS = {
	[Enum.MountType.Ground] = MOUNT_JOURNAL_FILTER_GROUND or "Ground",
	[Enum.MountType.Flying] = MOUNT_JOURNAL_FILTER_FLYING or "Flying",
	[Enum.MountType.Aquatic] = MOUNT_JOURNAL_FILTER_AQUATIC or "Aquatic",
	[Enum.MountType.Dragonriding] = MOUNT_JOURNAL_FILTER_DRAGONRIDING or "Dragonriding",
	[Enum.MountType.RideAlong] = MOUNT_JOURNAL_FILTER_RIDEALONG or "Ride Along",
}

local RAW_MOUNT_TYPE_TO_CATEGORY = {
	[230] = Enum.MountType.Ground,
	[241] = Enum.MountType.Ground,
	[242] = Enum.MountType.Ground,
	[284] = Enum.MountType.Ground,

	[231] = Enum.MountType.Aquatic,
	[232] = Enum.MountType.Aquatic,
	[254] = Enum.MountType.Aquatic,
	[269] = Enum.MountType.Aquatic,
	[407] = Enum.MountType.Aquatic,
	[408] = Enum.MountType.Aquatic,
	[412] = Enum.MountType.Aquatic,

	[247] = Enum.MountType.Flying,
	[248] = Enum.MountType.Flying,
	[398] = Enum.MountType.Flying,

	[402] = Enum.MountType.Dragonriding,
	[424] = Enum.MountType.Dragonriding,
}

local function Lower(value)
	return string.lower(value or "")
end

local function CompareValues(a, b)
	if a == b then
		return 0
	end
	return a < b and -1 or 1
end

local function ResolveMountCategory(rawMountTypeID, isSteadyFlight)
	local category = rawMountTypeID and RAW_MOUNT_TYPE_TO_CATEGORY[rawMountTypeID] or nil
	if category then
		return category
	end

	if isSteadyFlight then
		return Enum.MountType.Flying
	end

	return nil
end

function Mounts:RefreshCache()
	self.cache = {}
	self.mountIDs = C_MountJournal.GetMountIDs() or {}

	for _, mountID in ipairs(self.mountIDs) do
		local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, returnedMountID, isSteadyFlight =
			C_MountJournal.GetMountInfoByID(mountID)

		if name then
			local creatureDisplayInfoID, description, sourceText, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview =
				C_MountJournal.GetMountInfoExtraByID(mountID)
			local mountCategory = ResolveMountCategory(mountTypeID, isSteadyFlight)

			self.cache[mountID] = {
				mountID = returnedMountID or mountID,
				name = name,
				spellID = spellID,
				icon = icon,
				isActive = isActive,
				isUsable = isUsable,
				sourceType = sourceType,
				isFavorite = isFavorite,
				isFactionSpecific = isFactionSpecific,
				faction = faction,
				shouldHideOnChar = shouldHideOnChar,
				isCollected = isCollected,
				isSteadyFlight = isSteadyFlight,
				creatureDisplayInfoID = creatureDisplayInfoID,
				description = description,
				sourceText = sourceText,
				isSelfMount = isSelfMount,
				rawMountTypeID = mountTypeID,
				mountCategory = mountCategory,
				uiModelSceneID = uiModelSceneID,
				animID = animID,
				spellVisualKitID = spellVisualKitID,
				disablePlayerMountPreview = disablePlayerMountPreview,
			}
		end
	end
end

function Mounts:GetCache()
	if not self.cache then
		self:RefreshCache()
	end

	return self.cache
end

function Mounts:GetMountByID(mountID)
	return self:GetCache()[mountID]
end

function Mounts:GetMountTypeLabel(mountData)
	if not mountData then
		return UNKNOWN
	end

	if mountData.mountCategory and MOUNT_TYPE_LABELS[mountData.mountCategory] then
		return MOUNT_TYPE_LABELS[mountData.mountCategory]
	end

	return mountData.rawMountTypeID and ("Unknown (" .. mountData.rawMountTypeID .. ")") or UNKNOWN
end

function Mounts:IsCharacterFavorite(mountID)
	return Database:IsFavorite(mountID)
end

function Mounts:SetCharacterFavorite(mountID, isFavorite)
	Database:SetFavorite(mountID, isFavorite)
end

function Mounts:ToggleCharacterFavorite(mountID)
	return Database:ToggleFavorite(mountID)
end

function Mounts:GetEnvironmentContext()
	return {
		isSubmerged = IsSubmerged and IsSubmerged() or false,
		isSwimming = IsSwimming and IsSwimming() or false,
		isFlyable = IsFlyableArea and IsFlyableArea() or false,
		isIndoors = IsIndoors and IsIndoors() or false,
	}
end

function Mounts:IsCurrentlyUsable(mountData)
	if not mountData or not mountData.isCollected or mountData.shouldHideOnChar then
		return false
	end

	if ns.settings.avoidUnusableMounts then
		local isUsable = C_MountJournal.GetMountUsabilityByID(mountData.mountID, true)
		return isUsable == true
	end

	return mountData.isUsable == true
end

function Mounts:GetAllCollectedMounts()
	local mounts = {}

	for _, mountID in ipairs(self.mountIDs or C_MountJournal.GetMountIDs() or {}) do
		local mountData = self:GetMountByID(mountID)
		if mountData and mountData.isCollected and not mountData.shouldHideOnChar then
			table.insert(mounts, mountData)
		end
	end

	return mounts
end

function Mounts:GetUsableMountPool(poolType)
	self:RefreshCache()

	local pool = {}

	for _, mountID in ipairs(self.mountIDs) do
		local mountData = self.cache[mountID]
		if mountData and self:IsCurrentlyUsable(mountData) then
			if poolType == "CHARACTER" then
				if self:IsCharacterFavorite(mountID) then
					table.insert(pool, mountData)
				end
			elseif poolType == "BLIZZARD" then
				if mountData.isFavorite then
					table.insert(pool, mountData)
				end
			elseif poolType == "ALL" then
				table.insert(pool, mountData)
			end
		end
	end

	return pool
end

function Mounts:ApplyRegionPreference(candidates)
	if not ns.settings.preferRegionAppropriate or #candidates <= 1 then
		return candidates
	end

	local context = self:GetEnvironmentContext()
	local aquatic = {}
	local flying = {}
	local dragonriding = {}
	local ground = {}

	for _, mountData in ipairs(candidates) do
		if mountData.mountCategory == Enum.MountType.Aquatic then
			table.insert(aquatic, mountData)
		elseif mountData.mountCategory == Enum.MountType.Dragonriding then
			table.insert(dragonriding, mountData)
			table.insert(flying, mountData)
		elseif mountData.mountCategory == Enum.MountType.Flying then
			table.insert(flying, mountData)
		elseif mountData.mountCategory == Enum.MountType.Ground then
			table.insert(ground, mountData)
		end
	end

	if (context.isSubmerged or context.isSwimming) and #aquatic > 0 then
		return aquatic
	end

	if context.isFlyable then
		if #dragonriding > 0 then
			return dragonriding
		end
		if #flying > 0 then
			return flying
		end
	end

	if #ground > 0 then
		return ground
	end

	return candidates
end

function Mounts:GetRandomMountFromPool(pool)
	if not pool or #pool == 0 then
		return nil
	end

	local preferredPool = self:ApplyRegionPreference(pool)
	return preferredPool[math.random(1, #preferredPool)]
end

function Mounts:GetFallbackPool()
	if ns.settings.fallbackBehavior == "ALL_USABLE" then
		return self:GetUsableMountPool("ALL"), "all usable collected mounts"
	end

	if ns.settings.fallbackBehavior == "BLIZZARD_FAVORITES" then
		return self:GetUsableMountPool("BLIZZARD"), "Blizzard account favorites"
	end

	return {}, nil
end

function Mounts:SummonRandomCharacterFavorite()
	if not ns.settings.enabled then
		ns:Message("CharacterMountFavorites is currently disabled.")
		return false
	end

	local pool = self:GetUsableMountPool("CHARACTER")
	local chosenMount = self:GetRandomMountFromPool(pool)

	if not chosenMount then
		if ns.settings.useOnlyCharacterFavorites then
			ns:Message("No usable Character Favorite mounts are available for this character right now.")
			return false
		end

		local fallbackPool, fallbackLabel = self:GetFallbackPool()
		chosenMount = self:GetRandomMountFromPool(fallbackPool)

		if not chosenMount then
			if ns.settings.fallbackBehavior == "NONE" then
				ns:Message("No usable Character Favorite mounts are available, and fallback is disabled.")
			elseif fallbackLabel then
				ns:Message("No usable Character Favorite mounts were found, and no usable mounts were available in the fallback pool (" .. fallbackLabel .. ").")
			else
				ns:Message("No usable Character Favorite mounts are available for this character right now.")
			end
			return false
		end
	end

	C_MountJournal.SummonByID(chosenMount.mountID)
	return true
end

function Mounts:MatchesSearch(mountData, searchText)
	if not searchText or searchText == "" then
		return true
	end

	local haystack = Lower(table.concat({
		mountData.name or "",
		mountData.sourceText or "",
		self:GetMountTypeLabel(mountData),
	}, " "))

	return string.find(haystack, Lower(searchText), 1, true) ~= nil
end

function Mounts:MatchesFilters(mountData, filters)
	if not mountData then
		return false
	end

	if filters.usableOnly and not self:IsCurrentlyUsable(mountData) then
		return false
	end

	local wantsType =
		filters.ground or
		filters.aquatic or
		filters.dragonriding

	if not wantsType then
		return true
	end

	if filters.ground and mountData.mountCategory == Enum.MountType.Ground then
		return true
	end

	if filters.aquatic and mountData.mountCategory == Enum.MountType.Aquatic then
		return true
	end

	if filters.dragonriding and mountData.mountCategory == Enum.MountType.Dragonriding then
		return true
	end

	return false
end

function Mounts:SortEntries(entries, sortState)
	table.sort(entries, function(left, right)
		local direction = sortState.descending and -1 or 1

		if sortState.key == "favorite" then
			local favoriteCompare = CompareValues(self:IsCharacterFavorite(left.mountID) and 0 or 1, self:IsCharacterFavorite(right.mountID) and 0 or 1)
			if favoriteCompare ~= 0 then
				return favoriteCompare * direction < 0
			end
		elseif sortState.key == "type" then
			local typeCompare = CompareValues(self:GetMountTypeLabel(left), self:GetMountTypeLabel(right))
			if typeCompare ~= 0 then
				return typeCompare * direction < 0
			end
		elseif sortState.key == "source" then
			local sourceCompare = CompareValues(Lower(left.sourceText), Lower(right.sourceText))
			if sourceCompare ~= 0 then
				return sourceCompare * direction < 0
			end
		end

		local nameCompare = CompareValues(Lower(left.name), Lower(right.name))
		if nameCompare ~= 0 then
			return nameCompare * direction < 0
		end

		return left.mountID < right.mountID
	end)
end

function Mounts:GetManagerEntries(searchText, filters, sortState)
	self:RefreshCache()

	local entries = {}

	for _, mountID in ipairs(self.mountIDs) do
		local mountData = self.cache[mountID]
		if mountData and mountData.isCollected and not mountData.shouldHideOnChar then
			if self:MatchesSearch(mountData, searchText) and self:MatchesFilters(mountData, filters) then
				table.insert(entries, mountData)
			end
		end
	end

	self:SortEntries(entries, sortState)
	return entries
end
