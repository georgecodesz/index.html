--!nonstrict
-- Rig (ModuleScript, child of GymServer)
-- Shared NPC body used by customers and staff: spawning, outfits, name tag,
-- animations, pathfinding movement and holding props.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local Rig = {}
Rig.__index = Rig

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

local function pick(list)
	return list[math.random(#list)]
end
Rig.Pick = pick

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
		warn("[GymTycoon] Could not create NPC rig:", result)
		return nil
	end

	local animate = result:FindFirstChild("Animate")
	animIds = {
		Walk = findAnimId(animate, "walk") or FALLBACK_ANIMS.Walk,
		Idle = findAnimId(animate, "idle") or FALLBACK_ANIMS.Idle,
		Sit = findAnimId(animate, "sit") or FALLBACK_ANIMS.Sit,
	}
	if animate then
		animate:Destroy() -- animations are driven from the server instead
	end
	for _, d in result:GetDescendants() do
		if d:IsA("BodyColors") then
			d:Destroy()
		end
	end
	template = result
	return template
end

function Rig.Preload()
	task.spawn(getTemplate)
end

local function dress(model, colors)
	colors = colors or {}
	local skin = colors.Skin or pick(SKIN)
	local shirt = colors.Shirt or pick(SHIRTS)
	local pants = colors.Pants or pick(PANTS)
	local shoes = colors.Shoes or pick(PANTS)
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

local function makeTag(model, name, nameColor)
	local head = model:FindFirstChild("Head")
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(180, 44)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 70
	gui.AlwaysOnTop = true
	gui.Adornee = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = nameColor or Color3.new(1, 1, 1)
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
Rig.FlatDistance = flatDistance

--[[
	opts = {
		Name, NameColor, Colors = { Skin, Shirt, Pants, Shoes },
		CFrame, Parent, WalkSpeed,
		IsValid = function() -> bool  (return false to make the NPC stop, e.g. plot reset)
	}
]]
function Rig.new(opts)
	local tpl = getTemplate()
	if not tpl then
		return nil
	end
	local model = tpl:Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		model:Destroy()
		return nil
	end

	local self = setmetatable({
		Model = model,
		Humanoid = humanoid,
		Root = root,
		IsValid = opts.IsValid or function()
			return true
		end,
		Manual = false,
		Tracks = {},
	}, Rig)

	model.Name = opts.Name or "NPC"
	dress(model, opts.Colors)
	humanoid.WalkSpeed = opts.WalkSpeed or 14
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Customers"
		end
	end
	self.StatusLabel = makeTag(model, opts.Name or "NPC", opts.NameColor)

	model:PivotTo(opts.CFrame or CFrame.new())
	model.Parent = opts.Parent or workspace
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	for key, id in animIds do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok and track then
			track.Looped = true
			self.Tracks[key] = track
		end
	end
	humanoid.Running:Connect(function(speed)
		if not self.Manual then
			self:Play(speed > 0.5 and "Walk" or "Idle")
		end
	end)
	self:Play("Idle")
	return self
end

function Rig:Alive()
	return self.Model.Parent ~= nil and self.Root.Parent ~= nil and self.IsValid()
end

function Rig:SetStatus(text)
	self.StatusLabel.Text = text
end

function Rig:Play(trackName)
	for key, track in self.Tracks do
		if key == trackName then
			if not track.IsPlaying then
				track:Play(0.2)
			end
		elseif track.IsPlaying then
			track:Stop(0.2)
		end
	end
end

-- Waits while staying responsive to the NPC being removed. Returns false if it should stop.
function Rig:Wait(seconds)
	local start = os.clock()
	while self:Alive() and os.clock() - start < seconds do
		task.wait(0.25)
	end
	return self:Alive()
end

function Rig:MoveTo(target: Vector3, timeout: number)
	local humanoid, root = self.Humanoid, self.Root
	humanoid:MoveTo(target)
	local start = os.clock()
	local lastIssue = start
	while self:Alive() and os.clock() - start < timeout do
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

function Rig:WalkTo(target: Vector3)
	if not self:Alive() then
		return false
	end
	local root = self.Root
	local speed = math.max(self.Humanoid.WalkSpeed, 1)
	local path = PathfindingService:CreatePath(PATH_PARAMS)
	local ok = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for i = 2, #waypoints do
			if not self:Alive() then
				return false
			end
			local wp = waypoints[i].Position
			self:MoveTo(wp, flatDistance(root.Position, wp) / speed + 1.5)
		end
	else
		self:MoveTo(target, flatDistance(root.Position, target) / speed + 3)
	end
	return self:Alive() and flatDistance(root.Position, target) < 4
end

function Rig:Face(position: Vector3)
	local root = self.Root
	if not self:Alive() then
		return
	end
	local target = Vector3.new(position.X, root.Position.Y, position.Z)
	if (target - root.Position).Magnitude > 0.1 then
		root.CFrame = CFrame.lookAt(root.Position, target)
	end
end

-- Freeze the NPC at a CFrame (used for machines and stationary staff)
function Rig:Anchor(cf: CFrame)
	self.Manual = true
	self.Humanoid:MoveTo(self.Root.Position)
	self.Root.Anchored = true
	self.Root.CFrame = cf
end

function Rig:Unanchor(cf: CFrame?)
	if cf then
		self.Root.CFrame = cf
	end
	self.Root.Anchored = false
	self.Manual = false
	self:Play("Idle")
end

-- Loop the (anchored) NPC between its current CFrame and `target`
function Rig:Bob(target: CFrame, halfPeriod: number)
	local tween = TweenService:Create(
		self.Root,
		TweenInfo.new(halfPeriod, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = target }
	)
	tween:Play()
	return tween
end

-- Weld a prop (part or model with a PrimaryPart) to the right hand
function Rig:Hold(prop, offset: CFrame)
	local hand = self.Model:FindFirstChild("RightHand")
	if not hand then
		prop:Destroy()
		return
	end
	local main = prop:IsA("Model") and prop.PrimaryPart or prop
	for _, d in (prop:IsA("Model") and prop:GetDescendants() or { prop }) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	if prop:IsA("Model") then
		prop:PivotTo(hand.CFrame * offset)
	else
		prop.CFrame = hand.CFrame * offset
	end
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = main
	weld.C0 = offset
	weld.Parent = main
	prop.Parent = self.Model
end

function Rig:Destroy()
	if self.Model then
		self.Model:Destroy()
	end
end

return Rig
