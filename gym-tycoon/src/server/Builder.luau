--!nonstrict
-- Builder (ModuleScript, child of GymServer)
-- Builds every model in the game out of plain Parts, so the game works with zero imported assets.
--
-- Each station builder returns info in the item's local space:
--   Approach     : Vector3  floor spot a customer walks to before using the machine
--   Use          : CFrame   where the customer's HumanoidRootPart is placed while working out
--   Anim         : "Walk" | "Idle" | "Sit"
--   BodyOffset   : Vector3? the customer bobs between Use and Use+BodyOffset
--   MovingOffset : Vector3? parts named "Moving..." tween by this offset (barbells, weight stacks...)
--   Bob          : number   seconds per half-rep

local Builder = {}

local C = {
	Metal = Color3.fromRGB(165, 170, 178),
	Dark = Color3.fromRGB(40, 42, 50),
	Black = Color3.fromRGB(22, 22, 26),
	Red = Color3.fromRGB(205, 45, 55),
	Blue = Color3.fromRGB(40, 110, 225),
	Wood = Color3.fromRGB(150, 100, 62),
	LightWood = Color3.fromRGB(210, 170, 120),
	White = Color3.fromRGB(242, 242, 245),
	Cyan = Color3.fromRGB(0, 210, 255),
	Pink = Color3.fromRGB(255, 80, 170),
	Green = Color3.fromRGB(60, 170, 80),
	Purple = Color3.fromRGB(140, 80, 210),
	Orange = Color3.fromRGB(255, 150, 40),
	Wall = Color3.fromRGB(228, 228, 234),
	Accent = Color3.fromRGB(255, 170, 0),
	Terracotta = Color3.fromRGB(190, 100, 60),
}
Builder.Colors = C

local M = Enum.Material

-- Lying on your back, head toward -Z, face up
local LIE = CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.rad(90), 0, 0)

---------------------------------------------------------------------
-- Build context helpers
---------------------------------------------------------------------
local Ctx = {}
Ctx.__index = Ctx

local function toCFrame(pos)
	if typeof(pos) == "CFrame" then
		return pos
	end
	return CFrame.new(pos)
end

function Ctx:Part(name, size, pos, color, material, props)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = self.Origin * toCFrame(pos)
	part.Color = color or C.Metal
	part.Material = material or M.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in props do
			part[key] = value
		end
	end
	part.Parent = self.Model
	return part
end

local AXIS = {
	X = CFrame.new(),
	Y = CFrame.Angles(0, 0, math.rad(90)),
	Z = CFrame.Angles(0, math.rad(90), 0),
}

function Ctx:Cylinder(name, length, diameter, pos, axis, color, material, props)
	local part = self:Part(name, Vector3.new(length, diameter, diameter), toCFrame(pos) * AXIS[axis or "X"], color, material, props)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Ctx:Ball(name, diameter, pos, color, material, props)
	local part = self:Part(name, Vector3.one * diameter, pos, color, material, props)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Only visible while a customer is using the station (e.g. dumbbells in their hands)
function Ctx:HeldOnly(part)
	part.Transparency = 1
	part.CanCollide = false
	part:SetAttribute("HiddenWhenIdle", true)
	return part
end

function Ctx:Label(part, face, text, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = textColor or C.White
	label.Parent = gui
	gui.Parent = part
	return label
end

---------------------------------------------------------------------
-- Model builders
---------------------------------------------------------------------
local Builders = {}

function Builders.Desk(c)
	c:Part("Counter", Vector3.new(10, 3.4, 2.5), Vector3.new(0, 1.7, 0), C.Dark)
	c:Part("Top", Vector3.new(10.4, 0.3, 2.9), Vector3.new(0, 3.55, 0), C.White)
	c:Part("Stripe", Vector3.new(10.04, 0.4, 2.54), Vector3.new(0, 2.7, 0), C.Accent, M.Neon)
	c:Part("Monitor", Vector3.new(2.4, 1.5, 0.2), Vector3.new(2.5, 4.7, -0.4), C.Black)
	c:Part("MonitorStand", Vector3.new(0.3, 0.6, 0.3), Vector3.new(2.5, 3.9, -0.4), C.Black)
	c:Part("Screen", Vector3.new(2.2, 1.3, 0.05), Vector3.new(2.5, 4.7, -0.52), C.Cyan, M.Neon)
	local sign = c:Part("Sign", Vector3.new(6, 1.1, 0.1), Vector3.new(0, 1.4, 1.3), C.Dark)
	c:Label(sign, Enum.NormalId.Back, "FRONT DESK", C.Accent)
	return nil
end

function Builders.Treadmill(c)
	c:Part("Base", Vector3.new(4, 1, 8), Vector3.new(0, 0.5, 0), C.Dark)
	c:Part("Belt", Vector3.new(3.2, 0.2, 7.4), Vector3.new(0, 1.1, 0.2), C.Black, M.Fabric)
	for _, x in { -1.8, 1.8 } do
		c:Part("Post", Vector3.new(0.4, 4.4, 0.4), Vector3.new(x, 3.2, -3.6), C.Metal, M.Metal)
	end
	c:Part("Console", Vector3.new(4, 1.2, 0.8), Vector3.new(0, 5.6, -3.6), C.Dark)
	c:Part("Screen", Vector3.new(2.6, 0.8, 0.1), Vector3.new(0, 5.6, -3.15), C.Cyan, M.Neon)
	return {
		Approach = Vector3.new(0, 0, 6),
		Use = CFrame.new(0, 4.2, 0.6),
		Anim = "Walk",
		BodyOffset = Vector3.new(0, 0.2, 0),
		Bob = 0.2,
	}
end

function Builders.Bench(c)
	for _, z in { -2.1, 2.9 } do
		c:Part("Leg", Vector3.new(1.6, 1.8, 0.6), Vector3.new(0, 0.9, z), C.Metal, M.Metal)
	end
	c:Part("Pad", Vector3.new(2, 0.6, 6), Vector3.new(0, 2.1, 0.4), C.Red, M.Fabric)
	for _, x in { -2.6, 2.6 } do
		c:Part("Rack", Vector3.new(0.4, 5, 0.4), Vector3.new(x, 2.5, -0.6), C.Metal, M.Metal)
	end
	c:Cylinder("MovingBar", 7, 0.3, Vector3.new(0, 5.1, -0.6), "X", C.Metal, M.Metal)
	for _, x in { -3.1, 3.1 } do
		c:Cylinder("MovingPlate", 0.4, 2.2, Vector3.new(x, 5.1, -0.6), "X", C.Black)
	end
	return {
		Approach = Vector3.new(0, 0, 5.5),
		Use = CFrame.new(0, 3.0, 1.0) * LIE,
		Anim = "Idle",
		MovingOffset = Vector3.new(0, -1.3, 0),
		Bob = 0.8,
	}
end

function Builders.DumbbellRack(c)
	c:Part("ShelfLow", Vector3.new(7, 0.3, 1.6), Vector3.new(0, 1.2, -1.4), C.Dark)
	c:Part("ShelfHigh", Vector3.new(7, 0.3, 1.6), Vector3.new(0, 2.4, -1.9), C.Dark)
	for _, x in { -3.3, 3.3 } do
		c:Part("Leg", Vector3.new(0.4, 2.7, 2.2), Vector3.new(x, 1.35, -1.6), C.Metal, M.Metal)
	end
	for i = 0, 5 do
		local x = -2.5 + i
		local size = 0.45 + i * 0.06
		c:Cylinder("Dumbbell", 1.2, size, Vector3.new(x, 1.35 + size / 2, -1.4), "Z", C.Black)
		c:Cylinder("Dumbbell", 1.2, size, Vector3.new(x, 2.55 + size / 2, -1.9), "Z", C.Black)
	end
	for _, x in { -1.5, 1.5 } do
		c:HeldOnly(c:Cylinder("MovingDumbbell", 1.2, 0.55, Vector3.new(x, 2.0, 1.6), "Z", C.Black))
	end
	return {
		Approach = Vector3.new(0, 0, 5),
		Use = CFrame.new(0, 3, 1.6),
		Anim = "Idle",
		MovingOffset = Vector3.new(0, 1.4, -0.4),
		Bob = 0.7,
	}
end

function Builders.SquatRack(c)
	c:Part("Platform", Vector3.new(7, 0.2, 5), Vector3.new(0, 0.1, 0), C.Wood, M.WoodPlanks)
	for _, x in { -3, 3 } do
		for _, z in { -1.8, 1.8 } do
			c:Part("Post", Vector3.new(0.4, 8, 0.4), Vector3.new(x, 4.2, z), C.Red, M.Metal)
		end
		c:Part("SideBar", Vector3.new(0.3, 0.3, 4), Vector3.new(x, 8.1, 0), C.Red, M.Metal)
	end
	c:Part("TopBar", Vector3.new(6.4, 0.3, 0.3), Vector3.new(0, 8.1, -1.8), C.Red, M.Metal)
	c:Cylinder("MovingBar", 8, 0.3, Vector3.new(0, 4.9, 0.6), "X", C.Metal, M.Metal)
	for _, x in { -3.5, 3.5 } do
		c:Cylinder("MovingPlate", 0.5, 2.4, Vector3.new(x, 4.9, 0.6), "X", C.Black)
	end
	return {
		Approach = Vector3.new(0, 0, 5),
		Use = CFrame.new(0, 3.2, 0.3),
		Anim = "Idle",
		BodyOffset = Vector3.new(0, -1.2, 0),
		MovingOffset = Vector3.new(0, -1.2, 0),
		Bob = 0.9,
	}
end

function Builders.Rowing(c)
	c:Part("Rail", Vector3.new(1.4, 0.6, 8), Vector3.new(0, 0.5, 0), C.Dark)
	c:Cylinder("Flywheel", 0.8, 2.6, Vector3.new(0, 1.6, -3.4), "X", C.Black)
	c:Part("Footrest", Vector3.new(2.4, 0.3, 0.8), CFrame.new(0, 1.1, -2.2) * CFrame.Angles(math.rad(30), 0, 0), C.Metal, M.Metal)
	c:Part("MovingSeat", Vector3.new(1.6, 0.4, 1.6), Vector3.new(0, 1.0, 1.6), C.Black, M.Fabric)
	return {
		Approach = Vector3.new(0, 0, 6),
		Use = CFrame.new(0, 2.6, 1.6),
		Anim = "Sit",
		BodyOffset = Vector3.new(0, 0, -1.4),
		MovingOffset = Vector3.new(0, 0, -1.4),
		Bob = 0.9,
	}
end

function Builders.CableMachine(c)
	c:Part("Base", Vector3.new(6, 0.4, 2), Vector3.new(0, 0.2, -1.5), C.Dark)
	for _, x in { -2.6, 2.6 } do
		c:Part("Post", Vector3.new(0.5, 9, 0.5), Vector3.new(x, 4.6, -1.5), C.Dark, M.Metal)
	end
	c:Part("Top", Vector3.new(5.7, 0.5, 0.8), Vector3.new(0, 9.1, -1.5), C.Dark)
	for _, x in { -0.6, 0.6 } do
		c:Part("Guide", Vector3.new(0.15, 8, 0.15), Vector3.new(x, 4.6, -1.5), C.Metal, M.Metal)
	end
	c:Part("MovingStack", Vector3.new(1.8, 2.4, 0.9), Vector3.new(0, 1.6, -1.5), C.Black)
	c:Cylinder("Pulley", 0.3, 1, Vector3.new(0, 8.5, -0.9), "X", C.Metal, M.Metal)
	c:Part("Handle", Vector3.new(2, 0.2, 0.2), Vector3.new(0, 6.5, -0.4), C.Metal, M.Metal)
	return {
		Approach = Vector3.new(0, 0, 5.5),
		Use = CFrame.new(0, 3, 1.6),
		Anim = "Idle",
		BodyOffset = Vector3.new(0, 0, 0.35),
		MovingOffset = Vector3.new(0, 2.6, 0),
		Bob = 0.8,
	}
end

function Builders.PunchingBag(c)
	c:Part("Base", Vector3.new(3, 0.4, 3), Vector3.new(2.6, 0.2, -1.6), C.Dark)
	c:Part("Post", Vector3.new(0.5, 10, 0.5), Vector3.new(2.6, 5, -1.6), C.Metal, M.Metal)
	c:Part("Arm", Vector3.new(3, 0.4, 0.4), Vector3.new(1.3, 9.8, -1.6), C.Metal, M.Metal)
	c:Part("Chain", Vector3.new(0.15, 2, 0.15), Vector3.new(0, 8.6, -1.6), C.Metal, M.Metal)
	c:Cylinder("MovingBag", 4.4, 2.2, Vector3.new(0, 5.4, -1.6), "Y", C.Red, M.Fabric)
	return {
		Approach = Vector3.new(0, 0, 4.5),
		Use = CFrame.new(0, 3, 0.6),
		Anim = "Idle",
		BodyOffset = Vector3.new(0, 0, -0.35),
		MovingOffset = Vector3.new(0, 0, -0.8),
		Bob = 0.25,
	}
end

function Builders.YogaMat(c)
	c:Part("Mat", Vector3.new(3, 0.2, 7), Vector3.new(0, 0.1, 0), C.Purple, M.Fabric)
	c:Ball("ExerciseBall", 2.4, Vector3.new(2.6, 1.2, -2.4), C.Pink)
	return {
		Approach = Vector3.new(0, 0, 5),
		Use = CFrame.new(0, 0.75, 0.8) * LIE,
		Anim = "Idle",
		BodyOffset = Vector3.new(0, 0.5, 0),
		Bob = 1.2,
	}
end

function Builders.SmoothieBar(c)
	c:Part("Counter", Vector3.new(10, 3.4, 2.4), Vector3.new(0, 1.7, 0), C.White)
	c:Part("Top", Vector3.new(10.4, 0.3, 2.8), Vector3.new(0, 3.55, 0), C.Wood, M.WoodPlanks)
	c:Part("Stripe", Vector3.new(10.04, 0.4, 2.44), Vector3.new(0, 2.6, 0), C.Pink, M.Neon)
	c:Part("Shelf", Vector3.new(10, 7, 0.8), Vector3.new(0, 3.5, -3), C.Wood, M.WoodPlanks)
	local sign = c:Part("Sign", Vector3.new(8, 1.6, 0.3), Vector3.new(0, 8, -3), C.Black)
	c:Label(sign, Enum.NormalId.Back, "SMOOTHIES", C.Pink)
	local juice = { C.Pink, C.Green, C.Orange }
	for i, x in { -3, 0, 3 } do
		c:Cylinder("Blender", 1.4, 0.8, Vector3.new(x, 4.4, -0.3), "Y", juice[i], M.Glass, { Transparency = 0.2 })
		c:Ball("Fruit", 0.8, Vector3.new(x, 4.5, -2.4), juice[i])
	end
	for _, x in { -3.5, 3.5 } do
		c:Cylinder("StoolSeat", 0.3, 1.4, Vector3.new(x, 2.2, 2.6), "Y", C.Red, M.SmoothPlastic, { CanCollide = false })
		c:Cylinder("StoolLeg", 2, 0.3, Vector3.new(x, 1, 2.6), "Y", C.Metal, M.Metal, { CanCollide = false })
	end
	return {
		Approach = Vector3.new(0, 0, 5),
		Use = CFrame.new(0, 3, 2.6),
		Anim = "Idle",
		Bob = 1,
	}
end

function Builders.Sauna(c)
	local W = C.Wood
	c:Part("Floor", Vector3.new(12, 0.4, 10), Vector3.new(0, 0.2, 0), C.LightWood, M.WoodPlanks)
	c:Part("Wall", Vector3.new(12, 9, 0.4), Vector3.new(0, 4.5, -5), W, M.WoodPlanks)
	c:Part("Wall", Vector3.new(0.4, 9, 10), Vector3.new(-6, 4.5, 0), W, M.WoodPlanks)
	c:Part("Wall", Vector3.new(0.4, 9, 10), Vector3.new(6, 4.5, 0), W, M.WoodPlanks)
	c:Part("Wall", Vector3.new(4.5, 9, 0.4), Vector3.new(-3.75, 4.5, 5), W, M.WoodPlanks)
	c:Part("Wall", Vector3.new(4.5, 9, 0.4), Vector3.new(3.75, 4.5, 5), W, M.WoodPlanks)
	c:Part("Wall", Vector3.new(3, 2, 0.4), Vector3.new(0, 8, 5), W, M.WoodPlanks)
	c:Part("Door", Vector3.new(3, 7, 0.2), Vector3.new(0, 3.5, 5), C.Orange, M.Glass, { Transparency = 0.5, CanCollide = false })
	c:Part("Roof", Vector3.new(12.6, 0.5, 10.6), Vector3.new(0, 9.25, 0), C.Dark)
	c:Part("Bench", Vector3.new(11, 0.5, 2.6), Vector3.new(0, 1.9, -3.4), C.LightWood, M.WoodPlanks)
	local heater = c:Part("Heater", Vector3.new(2, 2, 2), Vector3.new(4, 1.4, 2.5), C.Dark, M.Metal)
	c:Ball("Stones", 1.6, Vector3.new(4, 2.6, 2.5), C.Metal, M.Slate)

	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Rate = 6
	steam.Lifetime = NumberRange.new(2, 3)
	steam.Speed = NumberRange.new(1, 2)
	steam.Size = NumberSequence.new(1, 3)
	steam.Transparency = NumberSequence.new(0.6, 1)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.Parent = heater

	local light = Instance.new("PointLight")
	light.Color = C.Orange
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = heater

	local sign = c:Part("Sign", Vector3.new(4, 1.2, 0.1), Vector3.new(0, 8, 5.25), C.Dark)
	c:Label(sign, Enum.NormalId.Back, "SAUNA", C.Orange)
	return {
		Approach = Vector3.new(0, 0, 8),
		Use = CFrame.new(-2, 3.7, -3.2) * CFrame.Angles(0, math.pi, 0),
		Anim = "Sit",
		Bob = 1,
	}
end

function Builders.BoxingRing(c)
	c:Part("Platform", Vector3.new(14, 2, 14), Vector3.new(0, 1, 0), C.Dark)
	c:Part("Canvas", Vector3.new(13, 0.1, 13), Vector3.new(0, 2.05, 0), C.Blue, M.Fabric)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			c:Part("Corner", Vector3.new(0.6, 5, 0.6), Vector3.new(sx * 6.6, 4.5, sz * 6.6), sx == sz and C.Red or C.Blue)
		end
	end
	for _, y in { 3.2, 4.2, 5.2 } do
		for _, s in { -1, 1 } do
			c:Part("Rope", Vector3.new(13.2, 0.18, 0.18), Vector3.new(0, y, s * 6.6), C.White)
			c:Part("Rope", Vector3.new(0.18, 0.18, 13.2), Vector3.new(s * 6.6, y, 0), C.White)
		end
	end
	c:Cylinder("MovingDummy", 4, 1.6, Vector3.new(2.2, 4.2, 0), "Y", C.Accent, M.Fabric)
	return {
		Approach = Vector3.new(0, 0, 9),
		Use = CFrame.new(-1.2, 5.1, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		Anim = "Idle",
		BodyOffset = Vector3.new(0.5, 0, 0),
		MovingOffset = Vector3.new(0.6, 0, 0),
		Bob = 0.3,
	}
end

---------------------------------------------------------------------
-- Decor (origin = plot centre)
---------------------------------------------------------------------
function Builders.Walls(c, params)
	local s = params.PlotSize
	local h = s / 2 - 0.5
	local H = 12
	local gap = 6
	local frontLen = s / 2 - gap
	local segments = {
		{ Vector3.new(s, H, 1), Vector3.new(0, H / 2, -h) },
		{ Vector3.new(1, H, s), Vector3.new(-h, H / 2, 0) },
		{ Vector3.new(1, H, s), Vector3.new(h, H / 2, 0) },
		{ Vector3.new(frontLen, H, 1), Vector3.new(-(gap + frontLen / 2), H / 2, h) },
		{ Vector3.new(frontLen, H, 1), Vector3.new(gap + frontLen / 2, H / 2, h) },
	}
	for _, seg in segments do
		local size, pos = seg[1], seg[2]
		c:Part("Wall", size, pos, C.Wall)
		local trim = Vector3.new(size.X + 0.1, 0.6, size.Z + 0.1)
		c:Part("Trim", trim, Vector3.new(pos.X, 9, pos.Z), C.Accent, M.Neon)
	end
	return nil
end

function Builders.RubberFloor(c, params)
	local s = params.PlotSize - 2
	c:Part("Floor", Vector3.new(s, 0.1, s), Vector3.new(0, 0.05, 0), Color3.fromRGB(55, 58, 66), M.Slate, {
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	return nil
end

function Builders.Plants(c)
	for _, p in { Vector3.new(-41.5, 0, -41.5), Vector3.new(41.5, 0, -41.5), Vector3.new(-41.5, 0, 0), Vector3.new(41.5, 0, 0) } do
		c:Cylinder("Pot", 2, 2.4, Vector3.new(p.X, 1, p.Z), "Y", C.Terracotta)
		c:Ball("Leaves", 3.4, Vector3.new(p.X, 3.2, p.Z), C.Green, M.Grass)
		c:Ball("Leaves", 2.4, Vector3.new(p.X + 0.6, 4.6, p.Z - 0.4), C.Green, M.Grass)
	end
	return nil
end

function Builders.Mirrors(c, params)
	local x = params.PlotSize / 2 - 1.2
	for _, side in { -1, 1 } do
		c:Part("Frame", Vector3.new(0.2, 7.6, 20.6), Vector3.new(side * (x + 0.05), 5, -12), C.Dark)
		c:Part("Mirror", Vector3.new(0.2, 7, 20), Vector3.new(side * x, 5, -12), Color3.fromRGB(200, 225, 240), M.Glass, {
			Reflectance = 0.6,
		})
	end
	return nil
end

function Builders.Speakers(c)
	for _, x in { -40, 40 } do
		c:Part("Speaker", Vector3.new(3, 5, 2), Vector3.new(x, 8, -42.8), C.Black)
		c:Cylinder("Cone", 0.2, 2, Vector3.new(x, 8.8, -41.75), "Z", C.Dark)
		c:Cylinder("Tweeter", 0.2, 0.8, Vector3.new(x, 6.8, -41.75), "Z", C.Dark)
		local light = c:Part("Glow", Vector3.new(3.1, 0.3, 2.1), Vector3.new(x, 5.6, -42.8), C.Pink, M.Neon)
		local pl = Instance.new("PointLight")
		pl.Color = C.Pink
		pl.Range = 16
		pl.Parent = light
	end
	return nil
end

function Builders.NeonSign(c, params)
	local z = -(params.PlotSize / 2 - 0.5)
	local board = c:Part("Board", Vector3.new(26, 5, 0.6), Vector3.new(0, 15, z), C.Black)
	c:Label(board, Enum.NormalId.Back, string.upper(params.OwnerName or "MY") .. "'S GYM", C.Cyan)
	c:Part("Border", Vector3.new(26.4, 0.3, 0.7), Vector3.new(0, 17.6, z), C.Pink, M.Neon)
	c:Part("Border", Vector3.new(26.4, 0.3, 0.7), Vector3.new(0, 12.4, z), C.Pink, M.Neon)
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Back
	glow.Color = C.Cyan
	glow.Range = 20
	glow.Parent = board
	return nil
end

---------------------------------------------------------------------
function Builder.Build(modelName: string, origin: CFrame, params)
	local fn = Builders[modelName]
	if not fn then
		warn("[GymTycoon] No builder for model:", modelName)
		return nil, nil
	end
	local model = Instance.new("Model")
	model.Name = modelName
	local ctx = setmetatable({ Model = model, Origin = origin }, Ctx)
	local info = fn(ctx, params or {})
	return model, info
end

return Builder
