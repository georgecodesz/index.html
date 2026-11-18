--!nonstrict
-- Customer (ModuleScript, child of GymServer)
-- NPC gym-goers: walk in, pay at the front desk, use 1-3 machines, pay per workout, leave.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Rig = require(script.Parent.Rig)
local CC = Config.Customer

local Customer = {}

local NAMES = {
	"Chad", "Brittany", "Marcus", "Jess", "Tyrone", "Priya", "Kenji", "Olivia", "Diego", "Aisha",
	"Liam", "Zoe", "Hank", "Mia", "Sven", "Lola", "Rex", "Nina", "Gus", "Ivy", "Brock", "Tia",
	"Dwayne", "Sasha", "Moe", "Kira", "Bruno", "Ellie", "Frank", "Yuki",
}

-- Puts the customer on a machine, animates it, then puts them back on the floor
local function workout(plot, rig, station, state)
	local root = rig.Root
	rig:Anchor(station.Use)
	rig:Play(station.Anim)

	local info = TweenInfo.new(station.Bob, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tweens = {}
	if station.UseBob then
		table.insert(tweens, TweenService:Create(root, info, { CFrame = station.UseBob }))
	end
	for _, moving in station.Moving do
		table.insert(tweens, TweenService:Create(moving.Part, info, { CFrame = moving.To }))
	end
	for _, part in station.Hidden do
		part.Transparency = 0
	end
	for _, tween in tweens do
		tween:Play()
	end

	state.Cleanup = function()
		state.Cleanup = nil
		for _, tween in tweens do
			tween:Cancel()
		end
		for _, moving in station.Moving do
			if moving.Part.Parent then
				moving.Part.CFrame = moving.From
			end
		end
		for _, part in station.Hidden do
			part.Transparency = 1
		end
	end

	local alive = rig:Wait(station.Item.Duration * (0.8 + math.random() * 0.4))
	if state.Cleanup then
		state.Cleanup()
	end
	if not alive then
		return false
	end

	local standAt = station.Approach + Vector3.new(0, 3, 0)
	local faceTo = plot.DeskPoint
	rig:Unanchor(CFrame.lookAt(standAt, Vector3.new(faceTo.X, standAt.Y, faceTo.Z)))
	return true
end

local function run(plot, rig, state)
	rig:SetStatus("🚶 Arriving")
	rig:WalkTo(plot.EntrancePoint)
	rig:WalkTo(plot.DeskPoint)
	if not rig:Alive() then
		return
	end

	rig:SetStatus("💳 Checking in")
	if not rig:Wait(1.2) then
		return
	end
	plot:Earn(CC.EntryFee * plot.Stats.EntryFee, rig.Root.Position)

	local visits = math.random(CC.MinVisits, CC.MaxVisits) + plot.Stats.ExtraVisits
	local used = {}
	local happy = true
	for i = 1, visits do
		if not rig:Alive() then
			return
		end
		local station, candidates = plot:ReserveStation(used)
		if candidates == 0 then
			break -- already tried every machine in the gym
		end
		if not station then
			rig:SetStatus("⏳ Waiting for a machine...")
			rig:WalkTo(plot.WaitPoint + Vector3.new(math.random(-3, 3), 0, math.random(-2, 2)))
			local start = os.clock()
			while not station and rig:Alive() and os.clock() - start < CC.MaxWait do
				task.wait(0.5)
				station = plot:ReserveStation(used)
			end
		end
		if not station then
			if i == 1 then
				happy = false
				rig:SetStatus("😠 Too busy! Leaving...")
			end
			break
		end

		state.Station = station
		used[station] = true
		rig:SetStatus("🚶 Going to " .. station.Item.Name)
		rig:WalkTo(station.Approach)
		if not rig:Alive() then
			return
		end

		rig:SetStatus(Config.Verbs[station.Item.Model] or ("💪 Using " .. station.Item.Name))
		if not workout(plot, rig, station, state) then
			return
		end
		plot:ReleaseStation(station)
		state.Station = nil
		plot:Earn(station.Item.Pay, rig.Root.Position)
	end

	rig:SetStatus(happy and "😄 Great workout!" or "😠 Too busy! Leaving...")
	rig:WalkTo(plot.EntrancePoint)
	rig:WalkTo(plot:ToWorld(Config.Layout.CustomerSpawn))
end

function Customer.Spawn(plot)
	local gen = plot.Generation
	plot:AdjustCustomers(1, gen)

	task.spawn(function()
		local state = {}
		local spawnPos = plot:ToWorld(Config.Layout.CustomerSpawn + Vector3.new(math.random(-4, 4), 0, 0))
		local rig = Rig.new({
			Name = Rig.Pick(NAMES),
			CFrame = CFrame.new(spawnPos + Vector3.new(0, 3, 0)) * plot.Origin.Rotation,
			Parent = plot.CustomersFolder,
			WalkSpeed = CC.WalkSpeed + (math.random() * 4 - 2),
			IsValid = function()
				return plot.Generation == gen
			end,
		})

		if rig and rig:Alive() then
			task.delay(CC.MaxLifetime, function()
				rig:Destroy()
			end)
			local ok, err = pcall(run, plot, rig, state)
			if not ok then
				warn("[GymTycoon] Customer error:", err)
			end
		end

		if state.Cleanup then
			pcall(state.Cleanup)
		end
		if state.Station then
			plot:ReleaseStation(state.Station)
		end
		if rig then
			rig:Destroy()
		end
		plot:AdjustCustomers(-1, gen)
	end)
end

return Customer
