--!nonstrict
-- Staff (ModuleScript, child of GymServer)
-- Hired NPCs. Their money bonus comes from the item's Effect in GymConfig;
-- this module makes them walk around and act out their job.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Rig = require(script.Parent.Rig)
local pick = Rig.Pick

local Staff = {}

local NAMES = { "Mike", "Sara", "Dante", "Rosa", "Theo", "Jada", "Victor", "Hana", "Leo", "Maya", "Omar", "Grace" }
local STAFF_COLOR = Color3.fromRGB(255, 200, 40)

-- Somewhere to stand next to a machine
local function besideStation(station)
	return station.Approach + Vector3.new(math.random() < 0.5 and -2.5 or 2.5, 0, 0)
end

local function makeMop()
	local model = Instance.new("Model")
	model.Name = "Mop"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 5, 0.25)
	handle.Color = Color3.fromRGB(150, 100, 60)
	handle.Material = Enum.Material.Wood
	handle.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.4, 0.4, 0.6)
	head.Color = Color3.fromRGB(230, 230, 210)
	head.Material = Enum.Material.Fabric
	head.CFrame = handle.CFrame * CFrame.new(0, -2.6, 0)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = head
	model.PrimaryPart = handle
	return model
end

local function makeClipboard()
	local board = Instance.new("Part")
	board.Name = "Clipboard"
	board.Size = Vector3.new(1, 0.1, 1.3)
	board.Color = Color3.fromRGB(150, 110, 70)
	return board
end

local Roles = {}

Roles.Receptionist = {
	Colors = { Shirt = Color3.fromRGB(0, 170, 170), Pants = Color3.fromRGB(30, 30, 35) },
	Run = function(plot, rig)
		-- stands behind the front desk facing the entrance
		rig:Anchor(plot.Origin * CFrame.new(Config.Layout.Desk + Vector3.new(0, 3, -3)) * CFrame.Angles(0, math.pi, 0))
		rig:Play("Idle")
		local lines = { "👋 Welcome in!", "💳 Checking members in", "😊 Have a great workout!", "📞 On the phone" }
		while rig:Alive() do
			rig:SetStatus(pick(lines))
			rig:Wait(5)
		end
	end,
}

Roles.Trainer = {
	Colors = { Shirt = Color3.fromRGB(220, 40, 40), Pants = Color3.fromRGB(25, 25, 30) },
	Run = function(plot, rig)
		local cheers = { "📣 One more rep!", "📣 Keep it up!", "📣 Feel the burn!", "📣 Great form!", "📣 You got this!" }
		while rig:Alive() do
			local busy = {}
			for _, station in plot.Stations do
				if station.Busy then
					table.insert(busy, station)
				end
			end
			local target = (#busy > 0 and pick(busy)) or (#plot.Stations > 0 and pick(plot.Stations)) or nil
			if target then
				rig:SetStatus("🚶 Making rounds")
				rig:WalkTo(besideStation(target))
				rig:Face(target.Use.Position)
				rig:SetStatus(target.Busy and pick(cheers) or "📋 Checking equipment")
			else
				rig:SetStatus("☕ Waiting for clients")
			end
			rig:Wait(math.random(4, 7))
		end
	end,
}

Roles.Janitor = {
	Colors = { Shirt = Color3.fromRGB(70, 100, 140), Pants = Color3.fromRGB(70, 100, 140) },
	Run = function(plot, rig)
		rig:Hold(makeMop(), CFrame.new(0, 0.6, -0.4))
		local jobs = { "🧹 Mopping floors", "🧽 Scrubbing", "✨ Sparkling clean", "🧴 Wiping machines" }
		while rig:Alive() do
			local spots = { plot.DeskPoint, plot.WaitPoint, plot:ToWorld(Vector3.new(0, 0, 20)), plot:ToWorld(Vector3.new(0, 0, -2)) }
			for _, station in plot.Stations do
				table.insert(spots, besideStation(station))
			end
			rig:SetStatus("🚶 Heading over")
			rig:WalkTo(pick(spots))
			rig:SetStatus(pick(jobs))
			rig:Wait(math.random(3, 5))
		end
	end,
}

Roles.DJ = {
	Colors = { Shirt = Color3.fromRGB(25, 25, 30), Pants = Color3.fromRGB(25, 25, 30) },
	Run = function(plot, rig, item)
		local cf = plot.Origin * CFrame.new(item.Position + Vector3.new(0, 3, -2.2)) * CFrame.Angles(0, math.pi, 0)
		rig:Anchor(cf)
		rig:Play("Idle")
		rig:Bob(cf + Vector3.new(0, -0.35, 0), 0.25)
		local lines = { "🎧 Dropping beats", "🎶 Turn it up!", "🔊 Pump-up playlist", "🎵 Bass boosted" }
		while rig:Alive() do
			rig:SetStatus(pick(lines))
			rig:Wait(6)
		end
	end,
}

Roles.Manager = {
	Colors = { Shirt = Color3.fromRGB(30, 40, 80), Pants = Color3.fromRGB(30, 40, 80) },
	Run = function(plot, rig)
		rig:Hold(makeClipboard(), CFrame.new(0, -0.4, -0.5) * CFrame.Angles(math.rad(-30), 0, 0))
		local lines = { "📋 Taking notes", "💼 Upselling memberships", "📈 Checking the numbers", "🤝 Greeting members" }
		while rig:Alive() do
			local spots = { plot.DeskPoint + Vector3.new(6, 0, 0), plot.WaitPoint, plot:ToWorld(Config.Layout.CollectPad + Vector3.new(-6, 0, -4)) }
			for _, station in plot.Stations do
				table.insert(spots, besideStation(station))
			end
			rig:SetStatus("🚶 Walking the floor")
			rig:WalkTo(pick(spots))
			rig:SetStatus(pick(lines))
			rig:Wait(math.random(4, 6))
		end
	end,
}

function Staff.Spawn(plot, item)
	local role = Roles[item.Role]
	if not role then
		warn("[GymTycoon] Unknown staff role:", item.Role)
		return
	end
	local gen = plot.Generation
	task.spawn(function()
		local rig = Rig.new({
			Name = pick(NAMES) .. " • " .. item.Name,
			NameColor = STAFF_COLOR,
			Colors = role.Colors,
			CFrame = plot.Origin * CFrame.new(Config.Layout.Desk + Vector3.new(8, 3, -4)),
			Parent = plot.StaffFolder,
			WalkSpeed = 10,
			IsValid = function()
				return plot.Generation == gen
			end,
		})
		if not rig then
			return
		end
		if rig:Alive() then
			local ok, err = pcall(role.Run, plot, rig, item)
			if not ok then
				warn("[GymTycoon] Staff error:", err)
			end
		end
		rig:Destroy()
	end)
end

return Staff
