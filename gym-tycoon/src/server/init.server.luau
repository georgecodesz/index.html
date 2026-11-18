--!nonstrict
-- GymServer (Script in ServerScriptService)
-- Entry point: sets up the world, creates the gym plots and hands one to each player.
-- Children ModuleScripts: Builder, Customer, DataService, Plot, Remotes

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Remotes = require(script.Remotes)
local DataService = require(script.DataService)
local Customer = require(script.Customer)
local Plot = require(script.Plot)

---------------------------------------------------------------------
-- World setup
---------------------------------------------------------------------
for _, group in { "Customers", "Players" } do
	pcall(function()
		PhysicsService:RegisterCollisionGroup(group)
	end)
end
PhysicsService:CollisionGroupSetCollidable("Customers", "Customers", false)
PhysicsService:CollisionGroupSetCollidable("Customers", "Players", false)

if not workspace:FindFirstChild("Baseplate") then
	local ground = Instance.new("Part")
	ground.Name = "Baseplate"
	ground.Anchored = true
	ground.Size = Vector3.new(Config.PlotCount * Config.PlotSpacing + 300, 2, 500)
	ground.CFrame = CFrame.new(0, -1, 40)
	ground.Color = Color3.fromRGB(90, 160, 70)
	ground.Material = Enum.Material.Grass
	ground.Parent = workspace
end

if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 110)
	spawn.Parent = workspace
end

Lighting.ClockTime = 14

---------------------------------------------------------------------
-- Plots
---------------------------------------------------------------------
local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Gyms"
plotsFolder.Parent = workspace

local plots = {}
for i = 1, Config.PlotCount do
	local x = (i - (Config.PlotCount + 1) / 2) * Config.PlotSpacing
	plots[i] = Plot.new(i, CFrame.new(x, Config.FloorHeight, 0), plotsFolder)
end

Customer.Preload()

local playerPlots = {}

local function findFreePlot()
	for _, plot in plots do
		if plot:IsFree() then
			return plot
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Players
---------------------------------------------------------------------
local function onCharacterAdded(player, character)
	local function setGroup(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = "Players"
		end
	end
	for _, d in character:GetDescendants() do
		setGroup(d)
	end
	character.DescendantAdded:Connect(setGroup)

	local plot = playerPlots[player]
	if plot then
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and plot.Owner == player then
			task.wait(0.1)
			character:PivotTo(plot:GetSpawnCFrame())
		end
	end
end

local function onPlayerAdded(player)
	local data = DataService.Load(player)
	if not player.Parent then
		DataService.Release(player)
		return
	end

	local plot = findFreePlot()
	if not plot then
		Remotes.Notify(player, "All gyms are taken on this server, sorry!", Color3.fromRGB(231, 76, 60))
		return
	end
	playerPlots[player] = plot
	plot:Claim(player, data)

	local leaderstats = player:WaitForChild("leaderstats")
	leaderstats.Cash.Changed:Connect(function()
		plot:RefreshButtonColors()
	end)
	leaderstats.Strength.Changed:Connect(function()
		plot:UpdateOwnerAttributes()
	end)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	Remotes.Notify(player, "Welcome to your gym! Step on a green pad to buy your first treadmill.", Color3.fromRGB(255, 200, 40))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local plot = playerPlots[player]
	playerPlots[player] = nil
	if plot and plot.Owner == player then
		plot:Release()
	end
	DataService.Release(player)
end)

---------------------------------------------------------------------
-- Saving
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for _, player in Players:GetPlayers() do
			task.spawn(DataService.Save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			DataService.Save(player)
			pending -= 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait(0.1)
	end
end)
