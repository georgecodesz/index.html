--!nonstrict
-- Plot (ModuleScript, child of GymServer)
-- One gym: floor, sign, front desk, register, buy-pads, built equipment and its customers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Builder = require(script.Parent.Builder)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Customer = require(script.Parent.Customer)
local Staff = require(script.Parent.Staff)
local GamePasses = require(script.Parent.GamePasses)

local GREEN = Color3.fromRGB(46, 204, 113)
local RED = Color3.fromRGB(231, 76, 60)
local GOLD = Color3.fromRGB(255, 200, 40)
local KIND_ICON = { Station = "🏋️", Decor = "🎨", Upgrade = "⬆️", Staff = "🧑‍💼" }

local function defaultStats()
	return { Rating = 0, Income = 1, Spawn = 1, Capacity = 0, AutoCollect = false, EntryFee = 1, ExtraVisits = 0 }
end

local workoutCooldowns = {}
Players.PlayerRemoving:Connect(function(player)
	workoutCooldowns[player] = nil
end)

local function playerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function newFolder(name, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function newPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	return part
end

local function newLabel(parent, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	for key, value in props do
		label[key] = value
	end
	label.Parent = parent
	return label
end

local function popIn(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local target = d.Transparency
			d.Transparency = 1
			TweenService:Create(d, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Transparency = target }):Play()
		end
	end
end

local Plot = {}
Plot.__index = Plot

function Plot.new(index: number, origin: CFrame, parent: Instance)
	local self = setmetatable({}, Plot)
	self.Index = index
	self.Origin = origin
	self.Owner = nil
	self.Data = nil
	self.Owned = {}
	self.Stations = {}
	self.Buttons = {}
	self.Register = 0
	self.ActiveCustomers = 0
	self.Generation = 0
	self.Stats = defaultStats()

	self.Folder = newFolder("Gym" .. index, parent)
	self.ItemsFolder = newFolder("Items", self.Folder)
	self.ButtonsFolder = newFolder("Buttons", self.Folder)
	self.CustomersFolder = newFolder("Customers", self.Folder)
	self.StaffFolder = newFolder("Staff", self.Folder)
	self.EffectsFolder = newFolder("Effects", self.Folder)

	self.EntrancePoint = self:ToWorld(Config.Layout.Entrance)
	self.DeskPoint = self:ToWorld(Config.Layout.DeskPoint)
	self.WaitPoint = self:ToWorld(Config.Layout.WaitSpot)

	self:_buildBase()
	return self
end

function Plot:ToWorld(localPos: Vector3): Vector3
	return (self.Origin * CFrame.new(localPos)).Position
end

function Plot:GetSpawnCFrame(): CFrame
	return self.Origin * CFrame.new(Config.Layout.PlayerSpawn + Vector3.new(0, 3, 0))
end

---------------------------------------------------------------------
-- Static parts of the plot
---------------------------------------------------------------------
function Plot:_buildBase()
	local s = Config.PlotSize

	newPart({
		Name = "Floor",
		Size = Vector3.new(s, 1, s),
		CFrame = self.Origin * CFrame.new(0, -0.5, 0),
		Color = Color3.fromRGB(205, 205, 210),
		Material = Enum.Material.SmoothPlastic,
		Parent = self.Folder,
	})
	newPart({
		Name = "Sidewalk",
		Size = Vector3.new(14, 1, 28),
		CFrame = self.Origin * CFrame.new(0, -0.5, s / 2 + 14),
		Color = Color3.fromRGB(150, 150, 155),
		Material = Enum.Material.Concrete,
		Parent = self.Folder,
	})

	-- Entrance sign
	for _, x in { -8, 8 } do
		newPart({
			Name = "SignPost",
			Size = Vector3.new(0.8, 15, 0.8),
			CFrame = self.Origin * CFrame.new(x, 7.5, s / 2 + 2.5),
			Color = Color3.fromRGB(40, 42, 50),
			Parent = self.Folder,
		})
	end
	local board = newPart({
		Name = "SignBoard",
		Size = Vector3.new(18, 3.5, 0.6),
		CFrame = self.Origin * CFrame.new(0, 13.5, s / 2 + 2.5),
		Color = Color3.fromRGB(25, 25, 30),
		Parent = self.Folder,
	})
	self.SignLabels = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board
		table.insert(self.SignLabels, newLabel(gui, {
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBlack,
			TextColor3 = GOLD,
			Text = "",
		}))
	end
	self:_setSign("🏋️ Unclaimed Gym")

	-- Front desk (always there)
	local desk = Builder.Build("Desk", self.Origin * CFrame.new(Config.Layout.Desk))
	desk.Parent = self.Folder

	-- Cash register / collect pad
	local pad = newPart({
		Name = "CollectPad",
		Size = Vector3.new(6, 0.4, 6),
		CFrame = self.Origin * CFrame.new(Config.Layout.CollectPad + Vector3.new(0, 0.2, 0)),
		Color = GOLD,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = self.Folder,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 70)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 80
	gui.Parent = pad
	newLabel(gui, { Size = UDim2.fromScale(1, 0.45), Text = "🧾 REGISTER", TextColor3 = GOLD })
	self.RegisterLabel = newLabel(gui, {
		Size = UDim2.fromScale(1, 0.55),
		Position = UDim2.fromScale(0, 0.45),
		Text = "$0",
		TextColor3 = GREEN,
	})
	pad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and player == self.Owner then
			self:Collect()
		end
	end)
end

function Plot:_setSign(text)
	for _, label in self.SignLabels do
		label.Text = text
	end
end

---------------------------------------------------------------------
-- Ownership
---------------------------------------------------------------------
function Plot:IsFree()
	return self.Owner == nil
end

function Plot:Claim(player, data)
	self.Generation += 1
	self.Owner = player
	self.Data = data
	self.Owned = data.Owned
	self.Register = 0
	self.ActiveCustomers = 0
	self:_setSign("🏋️ " .. player.DisplayName .. "'s Gym")

	for _, item in Config.Items do
		if self.Owned[item.Id] then
			self:_buildItem(item, false)
		end
	end
	self:_recalculate()
	self:RefreshButtons()
	self:_updateRegister()
	self:_startCustomerLoop()
end

function Plot:Release()
	self.Generation += 1
	self.Owner = nil
	self.Data = nil
	self.Owned = {}
	self.Stations = {}
	self.Buttons = {}
	self.Register = 0
	self.ActiveCustomers = 0
	self.ItemsFolder:ClearAllChildren()
	self.ButtonsFolder:ClearAllChildren()
	self.CustomersFolder:ClearAllChildren()
	self.StaffFolder:ClearAllChildren()
	self.EffectsFolder:ClearAllChildren()
	self:_recalculate()
	self:_setSign("🏋️ Unclaimed Gym")
	self:_updateRegister()
end

---------------------------------------------------------------------
-- Buying
---------------------------------------------------------------------
function Plot:_requirementsMet(item)
	if not item.Requires then
		return true
	end
	for _, id in item.Requires do
		if not self.Owned[id] then
			return false
		end
	end
	return true
end

function Plot:_makeButton(item)
	local pos = item.ButtonPosition or item.Position
	local pad = newPart({
		Name = item.Id,
		Size = Vector3.new(5, 0.4, 5),
		CFrame = self.Origin * CFrame.new(pos + Vector3.new(0, 0.2, 0)),
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CanCollide = false,
		Parent = self.ButtonsFolder,
	})

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(190, item.Description and 78 or 58)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 45
	gui.Parent = pad
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	newLabel(gui, { Size = UDim2.new(1, 0, 0, 26), Text = (KIND_ICON[item.Kind] or "") .. " " .. item.Name, LayoutOrder = 1 })
	local priceLabel = newLabel(gui, {
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamBlack,
		Text = "$" .. Config.FormatNumber(item.Price),
		LayoutOrder = 2,
	})
	if item.Description then
		newLabel(gui, {
			Size = UDim2.new(1, 0, 0, 20),
			Font = Enum.Font.Gotham,
			Text = item.Description,
			TextColor3 = Color3.fromRGB(200, 220, 255),
			LayoutOrder = 3,
		})
	end

	local busy = false
	pad.Touched:Connect(function(hit)
		if busy then
			return
		end
		local player = playerFromHit(hit)
		if not player or player ~= self.Owner then
			return
		end
		busy = true
		local bought = self:TryPurchase(player, item)
		task.delay(bought and 0.3 or 1.5, function()
			busy = false
		end)
	end)

	return { Part = pad, PriceLabel = priceLabel }
end

function Plot:RefreshButtons()
	for id, button in self.Buttons do
		local item = Config.ItemsById[id]
		if self.Owned[id] or not self:_requirementsMet(item) then
			button.Part:Destroy()
			self.Buttons[id] = nil
		end
	end
	if self.Owner then
		for _, item in Config.Items do
			if not self.Owned[item.Id] and not self.Buttons[item.Id] and self:_requirementsMet(item) then
				self.Buttons[item.Id] = self:_makeButton(item)
			end
		end
	end
	self:RefreshButtonColors()
end

function Plot:RefreshButtonColors()
	local cash = self.Data and self.Data.Cash or 0
	for id, button in self.Buttons do
		local affordable = cash >= Config.ItemsById[id].Price
		button.Part.Color = affordable and GREEN or RED
		button.PriceLabel.TextColor3 = affordable and GREEN or Color3.fromRGB(255, 130, 120)
	end
end

function Plot:TryPurchase(player, item)
	if player ~= self.Owner or self.Owned[item.Id] or not self:_requirementsMet(item) then
		return false
	end
	if not DataService.SpendCash(player, item.Price) then
		local missing = item.Price - (self.Data and self.Data.Cash or 0)
		Remotes.Notify(player, "Need $" .. Config.FormatNumber(missing) .. " more for " .. item.Name, RED)
		return false
	end
	self.Owned[item.Id] = true
	self:_buildItem(item, true)
	self:_recalculate()
	self:RefreshButtons()
	Remotes.Notify(player, "✅ Bought " .. item.Name .. "!", GREEN)
	return true
end

---------------------------------------------------------------------
-- Building items / stations
---------------------------------------------------------------------
function Plot:_buildItem(item, animate)
	if item.Model then
		local origin = self.Origin * CFrame.new(item.Position) * CFrame.Angles(0, math.rad(item.Rotation or 0), 0)
		local model, info = Builder.Build(item.Model, origin, {
			PlotSize = Config.PlotSize,
			OwnerName = self.Owner and self.Owner.DisplayName or "My",
		})
		if model then
			model.Name = item.Id
			model.Parent = self.ItemsFolder
			if animate then
				popIn(model)
			end
			if item.Kind == "Station" and info then
				self:_addStation(item, model, origin, info)
			end
		end
	end
	if item.Kind == "Staff" then
		Staff.Spawn(self, item)
	end
end

function Plot:_addStation(item, model, origin, info)
	local station = {
		Item = item,
		Model = model,
		Approach = (origin * CFrame.new(info.Approach)).Position,
		Use = origin * info.Use,
		UseBob = info.BodyOffset and (origin * CFrame.new(info.BodyOffset) * info.Use) or nil,
		Anim = info.Anim or "Idle",
		Bob = info.Bob or 0.6,
		Moving = {},
		Hidden = {},
		Busy = false,
	}
	local worldOffset = info.MovingOffset and origin:VectorToWorldSpace(info.MovingOffset)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if worldOffset and string.sub(d.Name, 1, 6) == "Moving" then
				table.insert(station.Moving, { Part = d, From = d.CFrame, To = d.CFrame + worldOffset })
			end
			if d:GetAttribute("HiddenWhenIdle") then
				table.insert(station.Hidden, d)
			end
		end
	end
	table.insert(self.Stations, station)

	-- Let players work out on it themselves for Strength
	local anchor = newPart({
		Name = "PromptAnchor",
		Size = Vector3.one,
		CFrame = CFrame.new(station.Approach + Vector3.new(0, 3, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = model,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Work Out"
	prompt.ObjectText = item.Name .. "  (+" .. (item.Strength or 1) .. " 💪)"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		self:_playerWorkout(player, station)
	end)
end

function Plot:_playerWorkout(player, station)
	local now = os.clock()
	if (workoutCooldowns[player] or 0) > now then
		return
	end
	workoutCooldowns[player] = now + Config.WorkoutCooldown
	local gain = station.Item.Strength or 1
	if GamePasses.Has(player, "SuperStrength") then
		gain *= 2
	end
	DataService.AddStrength(player, gain)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		self:FloatText(root.Position, "+" .. gain .. " 💪", GOLD)
	end
end

function Plot:ReserveStation(exclude)
	local free = {}
	local candidates = 0
	for _, station in self.Stations do
		if not (exclude and exclude[station]) then
			candidates += 1
			if not station.Busy then
				table.insert(free, station)
			end
		end
	end
	if #free == 0 then
		return nil, candidates
	end
	local station = free[math.random(#free)]
	station.Busy = true
	return station, candidates
end

function Plot:ReleaseStation(station)
	station.Busy = false
end

---------------------------------------------------------------------
-- Stats & money
---------------------------------------------------------------------
function Plot:_recalculate()
	local stats = defaultStats()
	for id in self.Owned do
		local item = Config.ItemsById[id]
		if item then
			stats.Rating += item.Rating or 0
			local effect = item.Effect
			if effect then
				if effect.Type == "IncomeMult" then
					stats.Income += effect.Value
				elseif effect.Type == "SpawnRate" then
					stats.Spawn += effect.Value
				elseif effect.Type == "Capacity" then
					stats.Capacity += effect.Value
				elseif effect.Type == "AutoCollect" then
					stats.AutoCollect = true
				elseif effect.Type == "EntryFee" then
					stats.EntryFee += effect.Value
				elseif effect.Type == "ExtraVisits" then
					stats.ExtraVisits += effect.Value
				end
			end
		end
	end

	-- Gamepasses
	local owner = self.Owner
	if GamePasses.Has(owner, "AutoCollect") then
		stats.AutoCollect = true
	end
	if GamePasses.Has(owner, "VIPGym") then
		stats.Spawn *= 1.5
		stats.Capacity += 5
	end

	self.Stats = stats
	if stats.AutoCollect and self.Register > 0 then
		self:Collect()
	end
	self:UpdateOwnerAttributes()
end

function Plot:GetIncomeMultiplier()
	local strength = self.Data and self.Data.Strength or 0
	local bonus = math.min(strength * Config.StrengthIncomeBonus, Config.MaxStrengthBonus)
	local rebirths = self.Data and self.Data.Rebirths or 0
	local pass = GamePasses.Has(self.Owner, "DoubleCash") and 2 or 1
	return self.Stats.Income * (1 + bonus) * Config.GetRebirthMultiplier(rebirths) * pass
end

function Plot:GetSpawnInterval()
	local c = Config.Customer
	local speed = (1 + self.Stats.Rating * c.RatingSpawnBonus) * self.Stats.Spawn
	return math.max(c.MinSpawnInterval, c.BaseSpawnInterval / speed)
end

function Plot:GetMaxCustomers()
	local c = Config.Customer
	return c.BaseMaxCustomers + math.floor(#self.Stations * c.CustomersPerStation) + self.Stats.Capacity
end

function Plot:UpdateOwnerAttributes()
	local owner = self.Owner
	if not owner then
		return
	end
	owner:SetAttribute("GymRating", self.Stats.Rating)
	owner:SetAttribute("Customers", self.ActiveCustomers)
	owner:SetAttribute("MaxCustomers", self:GetMaxCustomers())
	owner:SetAttribute("IncomeMult", math.floor(self:GetIncomeMultiplier() * 100 + 0.5) / 100)
	owner:SetAttribute("AutoCollect", self.Stats.AutoCollect)
	owner:SetAttribute("Register", self.Register)
	local rebirths = self.Data and self.Data.Rebirths or 0
	owner:SetAttribute("RebirthCost", Config.GetRebirthCost(rebirths))
	owner:SetAttribute("RebirthItemOwned", self.Owned[Config.Rebirth.RequiredItem] == true)
end

---------------------------------------------------------------------
-- Rebirth: reset the gym + cash for a permanent income multiplier
---------------------------------------------------------------------
function Plot:Rebirth(player)
	if player ~= self.Owner or not self.Data then
		return
	end
	local data = self.Data
	local required = Config.ItemsById[Config.Rebirth.RequiredItem]
	if not data.Owned[Config.Rebirth.RequiredItem] then
		Remotes.Notify(player, "You need the " .. (required and required.Name or "final item") .. " to rebirth!", RED)
		return
	end
	local cost = Config.GetRebirthCost(data.Rebirths)
	if data.Cash < cost then
		Remotes.Notify(player, "You need $" .. Config.FormatNumber(cost) .. " to rebirth!", RED)
		return
	end

	DataService.AddRebirth(player)
	DataService.SetCash(player, Config.StartingCash)
	table.clear(data.Owned)

	self:Release()
	self:Claim(player, data)

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(self:GetSpawnCFrame())
	end
	Remotes.Notify(
		player,
		("🔁 REBIRTH #%d! Income is now permanently x%.1f"):format(data.Rebirths, Config.GetRebirthMultiplier(data.Rebirths)),
		GOLD
	)
	task.spawn(DataService.Save, player)
end

function Plot:_updateRegister()
	self.RegisterLabel.Text = "$" .. Config.FormatNumber(self.Register)
	if self.Owner then
		self.Owner:SetAttribute("Register", self.Register)
	end
end

function Plot:Earn(amount, position)
	if not self.Owner or not self.Data then
		return 0
	end
	local total = math.max(1, math.floor(amount * self:GetIncomeMultiplier() + 0.5))
	if self.Stats.AutoCollect then
		DataService.AddCash(self.Owner, total)
	else
		self.Register += total
		self:_updateRegister()
	end
	if position then
		self:FloatText(position, "+$" .. Config.FormatNumber(total), GREEN)
	end
	return total
end

function Plot:Collect()
	if not self.Owner or self.Register <= 0 then
		return
	end
	local amount = self.Register
	self.Register = 0
	DataService.AddCash(self.Owner, amount)
	self:_updateRegister()
	Remotes.Notify(self.Owner, "💵 Collected $" .. Config.FormatNumber(amount), GREEN)
end

function Plot:FloatText(position, text, color)
	local part = newPart({
		Name = "FloatText",
		Size = Vector3.one * 0.2,
		CFrame = CFrame.new(position + Vector3.new(0, 3, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = self.EffectsFolder,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(130, 36)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = part
	local label = newLabel(gui, {
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = color or GREEN,
	})
	local info = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(part, info, { CFrame = part.CFrame + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(part, 1.5)
end

---------------------------------------------------------------------
-- Customers
---------------------------------------------------------------------
function Plot:AdjustCustomers(delta, gen)
	if gen ~= self.Generation then
		return
	end
	self.ActiveCustomers = math.max(0, self.ActiveCustomers + delta)
	if self.Owner then
		self.Owner:SetAttribute("Customers", self.ActiveCustomers)
	end
end

function Plot:_startCustomerLoop()
	local gen = self.Generation
	task.spawn(function()
		task.wait(2)
		while self.Generation == gen do
			if #self.Stations > 0 and self.ActiveCustomers < self:GetMaxCustomers() then
				Customer.Spawn(self)
			end
			task.wait(self:GetSpawnInterval())
		end
	end)
end

return Plot
