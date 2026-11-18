--!nonstrict
-- Customer (ModuleScript, child of GymServer)
-- NPC gym-goers: walk in, pay at the front desk, use 1-3 machines, pay per workout, leave.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local CC = Config.Customer

local Customer = {}

local NAMES = {
	"Chad", "Brittany", "Marcus", "Jess", "Tyrone", "Priya", "Kenji", "Olivia", "Diego", "Aisha",
	"Liam", "Zoe", "Hank", "Mia", "Sven", "Lola", "Rex", "Nina", "Gus", "Ivy", "Brock", "Tia",
	"Dwayne", "Sasha", "Moe", "Kira", "Bruno", "Ellie", "Frank", "Yuki",
}
local SKIN = {
	Color3.fromRGB(255, 220, 185), Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 134, 98),
	Color3.fromRGB(141, 85, 56), Color3.fromRGB(95, 58, 38), Color3.fromRGB(250, 205, 160),
}
local SHIRTS = {
	Color3.fromRGB(230, 60, 60), Color3.fromRGB(40, 120, 230), Color3.fromRGB(40, 180, 90),
	Color3.fromRGB(250, 200, 40), Color3.fromRGB(150, 70, 210), Color3.fromRGB(255, 120, 180),
	Color3.fromRGB(30, 30, 35), Color3.fromRGB(240, 240, 240), Color3.fromRGB(255, 140, 40),
}
local PANTS = {
	Color3.fromRGB(30, 30, 35), Color3.fromRGB(60, 60, 70), Color3.fromRGB(40, 50, 90),
	Color3.fromRGB(110, 110, 120), Color3.fromRGB(20, 60, 40),
}

local SHIRT_PARTS = { UpperTorso = true, LowerTorso = true, LeftUpperArm = true, RightUpperArm = true }
local PANTS_PARTS = { LeftUpperLeg = true, LeftLowerLeg = true, RightUpperLeg = true, RightLowerLeg = true }
local SHOE_PARTS = { LeftFoot = true, RightFoot = true }

-- Default R15 animations (used if the generated rig has no Animate script to read them from)
local FALLBACK_ANIMS = {
	Walk = "rbxassetid://507777826",
	Idle = "rbxassetid://507766388",
	Sit = "rbxassetid://2506281703",
}

local PATH_PARAMS = {
	AgentRadius = 1.8,
	AgentHeight = 5,
	AgentCanJump = false,
	WaypointSpacing = 4,
}

local template = nil
local animIds = FALLBACK_ANIMS
local loading = false
local lastFailure = -math.huge

local function findAnimId(animate, valueName)
	local holder = animate and animate:FindFirstChild(valueName)
	local anim = holder and holder:FindFirstChildWhichIsA("Animation")
	if anim and anim.AnimationId ~= "" then
		return anim.AnimationId
	end
	return nil
end

local function getTemplate()
	while loading do
		task.wait(0.1)
	end
	if template then
		return template
	end
	if os.clock() - lastFailure < 30 then
		return nil
	end

	loading = true
	local ok, result = pcall(function()
		local description = Instance.new("HumanoidDescription")
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	loading = false

	if not ok or not result then
		lastFailure = os.clock()
		warn("[GymTycoon] Could not create customer rig:", result)
		return nil
	end

	local animate = result:FindFirstChild("Animate")
	animIds = {
		Walk = findAnimId(animate, "walk") or FALLBACK_ANIMS.Walk,
		Idle = findAnimId(animate, "idle") or FALLBACK_ANIMS.Idle,
		Sit = findAnimId(animate, "sit") or FALLBACK_ANIMS.Sit,
	}
	if animate then
		animate:Destroy() -- we drive animations from the server ourselves
	end
	for _, d in result:GetDescendants() do
		if d:IsA("BodyColors") then
			d:Destroy()
		end
	end
	template = result
	return template
end

function Customer.Preload()
	task.spawn(getTemplate)
end

local function pick(list)
	return list[math.random(#list)]
end

local function dress(model)
	local skin, shirt, pants, shoes = pick(SKIN), pick(SHIRTS), pick(PANTS), pick(PANTS)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if SHIRT_PARTS[part.Name] then
				part.Color = shirt
			elseif PANTS_PARTS[part.Name] then
				part.Color = pants
			elseif SHOE_PARTS[part.Name] then
				part.Color = shoes
			else
				part.Color = skin
			end
		end
	end
end

local function makeTag(model, name)
	local head = model:FindFirstChild("Head")
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(170, 44)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 70
	gui.AlwaysOnTop = true
	gui.Adornee = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = name
	nameLabel.Parent = gui

	local status = Instance.new("TextLabel")
	status.Size = UDim2.fromScale(1, 0.5)
	status.Position = UDim2.fromScale(0, 0.5)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 230, 140)
	status.TextStrokeTransparency = 0.5
	status.Text = ""
	status.Parent = gui

	gui.Parent = head or model
	return status
end

local function flatDistance(a: Vector3, b: Vector3)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function run(plot, gen, model, state)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end

	local name = pick(NAMES)
	model.Name = name
	dress(model)
	humanoid.WalkSpeed = CC.WalkSpeed + (math.random() * 4 - 2)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Customers"
		end
	end
	local statusLabel = makeTag(model, name)
	local function setStatus(text)
		statusLabel.Text = text
	end

	local spawnPos = plot:ToWorld(Config.Layout.CustomerSpawn + Vector3.new(math.random(-4, 4), 0, 0))
	model:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 3, 0)) * plot.Origin.Rotation)
	model.Parent = plot.CustomersFolder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local function alive()
		return model.Parent ~= nil and root.Parent ~= nil and plot.Generation == gen
	end

	-- Animations
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local tracks = {}
	for key, id in animIds do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok and track then
			track.Looped = true
			tracks[key] = track
		end
	end
	local manualAnim = false
	local function play(trackName)
		for key, track in tracks do
			if key == trackName then
				if not track.IsPlaying then
					track:Play(0.2)
				end
			elseif track.IsPlaying then
				track:Stop(0.2)
			end
		end
	end
	humanoid.Running:Connect(function(speed)
		if not manualAnim then
			play(speed > 0.5 and "Walk" or "Idle")
		end
	end)
	play("Idle")

	-- Movement
	local function moveTo(target: Vector3, timeout: number)
		humanoid:MoveTo(target)
		local start = os.clock()
		local lastIssue = start
		while alive() and os.clock() - start < timeout do
			if flatDistance(root.Position, target) < 1.6 then
				return true
			end
			if os.clock() - lastIssue > 5 then
				humanoid:MoveTo(target)
				lastIssue = os.clock()
			end
			task.wait(0.1)
		end
		return false
	end

	local function walkTo(target: Vector3)
		if not alive() then
			return false
		end
		local speed = math.max(humanoid.WalkSpeed, 1)
		local path = PathfindingService:CreatePath(PATH_PARAMS)
		local ok = pcall(function()
			path:ComputeAsync(root.Position, target)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			for i = 2, #waypoints do
				if not alive() then
					return false
				end
				local wp = waypoints[i].Position
				moveTo(wp, flatDistance(root.Position, wp) / speed + 1.5)
			end
		else
			moveTo(target, flatDistance(root.Position, target) / speed + 3)
		end
		return alive() and flatDistance(root.Position, target) < 4
	end

	-- Using a machine
	local function workout(station)
		manualAnim = true
		humanoid:MoveTo(root.Position)
		root.Anchored = true
		root.CFrame = station.Use
		play(station.Anim)

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

		local duration = station.Item.Duration * (0.8 + math.random() * 0.4)
		local start = os.clock()
		while alive() and os.clock() - start < duration do
			task.wait(0.25)
		end
		if state.Cleanup then
			state.Cleanup()
		end
		if not alive() then
			return false
		end

		local standAt = station.Approach + Vector3.new(0, 3, 0)
		local faceTo = plot.DeskPoint + Vector3.new(0, 3, 0)
		root.CFrame = CFrame.lookAt(standAt, Vector3.new(faceTo.X, standAt.Y, faceTo.Z))
		root.Anchored = false
		manualAnim = false
		play("Idle")
		return true
	end

	------------------------------------------------------------------
	-- The visit
	------------------------------------------------------------------
	setStatus("🚶 Arriving")
	walkTo(plot.EntrancePoint)
	walkTo(plot.DeskPoint)
	if not alive() then
		return
	end

	setStatus("💳 Checking in")
	task.wait(1.2)
	if not alive() then
		return
	end
	plot:Earn(CC.EntryFee, root.Position)

	local visits = math.random(CC.MinVisits, CC.MaxVisits)
	local used = {}
	local happy = true
	for i = 1, visits do
		if not alive() then
			return
		end
		local station, candidates = plot:ReserveStation(used)
		if candidates == 0 then
			break -- tried every machine in the gym already
		end
		if not station then
			setStatus("⏳ Waiting for a machine...")
			walkTo(plot.WaitPoint + Vector3.new(math.random(-3, 3), 0, math.random(-2, 2)))
			local start = os.clock()
			while not station and alive() and os.clock() - start < CC.MaxWait do
				task.wait(0.5)
				station = plot:ReserveStation(used)
			end
		end
		if not station then
			if i == 1 then
				happy = false
				setStatus("😠 Too busy! Leaving...")
			end
			break
		end

		state.Station = station
		used[station] = true
		setStatus("🚶 Going to " .. station.Item.Name)
		walkTo(station.Approach)
		if not alive() then
			return
		end

		setStatus(Config.Verbs[station.Item.Model] or ("💪 Using " .. station.Item.Name))
		if not workout(station) then
			return
		end
		plot:ReleaseStation(station)
		state.Station = nil
		plot:Earn(station.Item.Pay, root.Position)
	end

	setStatus(happy and "😄 Great workout!" or "😠 Too busy! Leaving...")
	walkTo(plot.EntrancePoint)
	walkTo(plot:ToWorld(Config.Layout.CustomerSpawn))
end

function Customer.Spawn(plot)
	local gen = plot.Generation
	plot:AdjustCustomers(1, gen)

	task.spawn(function()
		local state = {}
		local model = nil
		local tpl = getTemplate()
		if tpl and plot.Generation == gen then
			model = tpl:Clone()
			task.delay(CC.MaxLifetime, function()
				if model and model.Parent then
					model:Destroy()
				end
			end)
			local ok, err = pcall(run, plot, gen, model, state)
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
		if model then
			model:Destroy()
		end
		plot:AdjustCustomers(-1, gen)
	end)
end

return Customer
