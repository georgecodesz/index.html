--!nonstrict
-- DataService (ModuleScript, child of GymServer)
-- Holds each player's cash / strength / owned items and saves them to a DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))

local DataService = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[GymTycoon] DataStore unavailable, progress will not save:", result)
	end
end

local profiles = {} -- [Player] = { Data = {...}, CanSave = bool }

local function keyFor(player)
	return "player_" .. player.UserId
end

local function defaultData()
	return {
		Cash = Config.StartingCash,
		Strength = 0,
		TotalEarned = 0,
		Owned = {}, -- set: [itemId] = true
	}
end

local function setStat(player, name, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat then
		stat.Value = math.floor(value)
	end
end

function DataService.Load(player)
	local data = defaultData()
	local canSave = store ~= nil

	if store then
		local ok, result
		for _ = 1, 3 do
			ok, result = pcall(store.GetAsync, store, keyFor(player))
			if ok then
				break
			end
			task.wait(1)
		end

		if ok then
			if type(result) == "table" then
				data.Cash = tonumber(result.Cash) or data.Cash
				data.Strength = tonumber(result.Strength) or 0
				data.TotalEarned = tonumber(result.TotalEarned) or 0
				if type(result.Owned) == "table" then
					for _, id in result.Owned do
						if Config.ItemsById[id] then
							data.Owned[id] = true
						end
					end
				end
			end
		else
			-- Don't overwrite real saves with a blank profile if loading failed
			canSave = false
			warn("[GymTycoon] Could not load data for", player.Name, "-", result, "(saving disabled this session)")
		end
	end

	profiles[player] = { Data = data, CanSave = canSave }

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(data.Cash)
	cash.Parent = leaderstats
	local strength = Instance.new("IntValue")
	strength.Name = "Strength"
	strength.Value = math.floor(data.Strength)
	strength.Parent = leaderstats
	leaderstats.Parent = player

	return data
end

function DataService.Get(player)
	local profile = profiles[player]
	return profile and profile.Data
end

function DataService.AddCash(player, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned += amount
	end
	setStat(player, "Cash", data.Cash)
end

function DataService.SpendCash(player, amount)
	local data = DataService.Get(player)
	if not data or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	setStat(player, "Cash", data.Cash)
	return true
end

function DataService.AddStrength(player, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Strength += amount
	setStat(player, "Strength", data.Strength)
end

function DataService.Save(player)
	local profile = profiles[player]
	if not profile or not profile.CanSave or not store then
		return
	end
	local data = profile.Data
	local owned = {}
	for id in data.Owned do
		table.insert(owned, id)
	end
	local payload = {
		Version = 1,
		Cash = math.floor(data.Cash),
		Strength = math.floor(data.Strength),
		TotalEarned = math.floor(data.TotalEarned),
		Owned = owned,
	}
	local ok, err = pcall(store.SetAsync, store, keyFor(player), payload)
	if not ok then
		warn("[GymTycoon] Save failed for", player.Name, "-", err)
	end
end

function DataService.Release(player)
	DataService.Save(player)
	profiles[player] = nil
end

return DataService
