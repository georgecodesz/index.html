--!nonstrict
-- GymHUD (LocalScript in StarterPlayer > StarterPlayerScripts)
-- Cash counter, gym stats, register reminder and popup notifications.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local notifyEvent = ReplicatedStorage:WaitForChild("GymRemotes"):WaitForChild("Notify")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function create(className, props, children)
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local DARK = Color3.fromRGB(20, 22, 28)
local GOLD = Color3.fromRGB(255, 170, 0)
local GREEN = Color3.fromRGB(90, 230, 120)

local gui = create("ScreenGui", {
	Name = "GymHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Top panel ---------------------------------------------------------
local panel = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(340, 80),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, {
	corner(14),
	create("UIStroke", { Color = GOLD, Thickness = 2 }),
})

local cashLabel = create("TextLabel", {
	Position = UDim2.fromOffset(0, 4),
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 34,
	TextColor3 = GREEN,
	Text = "$0",
	Parent = panel,
})

local statsLabel = create("TextLabel", {
	Position = UDim2.fromOffset(0, 50),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(220, 222, 232),
	Text = "",
	Parent = panel,
})

local registerLabel = create("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 94),
	Size = UDim2.fromOffset(340, 30),
	BackgroundColor3 = GOLD,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = DARK,
	Visible = false,
	Text = "",
	Parent = gui,
}, { corner(10) })

-- Help text --------------------------------------------------------------
create("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 10, 1, -10),
	Size = UDim2.fromOffset(310, 78),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.35,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(230, 230, 240),
	Text = "🟢 Step on pads to build your gym\n🧾 Collect customer cash at the gold register\n💪 Work out on machines to gain Strength (+income)\n⭐ Higher rating = more customers",
	Parent = gui,
}, {
	corner(10),
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}),
})

-- Toasts --------------------------------------------------------------
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -100),
	Size = UDim2.fromOffset(420, 220),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}),
})

local toastCount = 0
local function toast(text, color)
	toastCount += 1
	local label = create("TextLabel", {
		Size = UDim2.fromOffset(400, 34),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextWrapped = true,
		Text = text,
		LayoutOrder = toastCount,
		Parent = toastHolder,
	}, { corner(10) })
	task.delay(3, function()
		local info = TweenInfo.new(0.4)
		TweenService:Create(label, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.45)
		label:Destroy()
	end)
	local children = toastHolder:GetChildren()
	if #children > 6 then
		for _, child in children do
			if child:IsA("TextLabel") and child.LayoutOrder <= toastCount - 5 then
				child:Destroy()
			end
		end
	end
end

notifyEvent.OnClientEvent:Connect(toast)

-- Cash + stats ---------------------------------------------------------------
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local strength = leaderstats:WaitForChild("Strength")

local function popDelta(text)
	local label = create("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 8, 0, 26),
		Size = UDim2.fromOffset(140, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GREEN,
		TextStrokeTransparency = 0.5,
		Text = text,
		Parent = panel,
	})
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, {
		Position = UDim2.new(1, 8, 0, -6),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1.05, function()
		label:Destroy()
	end)
end

local lastCash = cash.Value
local function updateCash()
	local delta = cash.Value - lastCash
	lastCash = cash.Value
	cashLabel.Text = "$" .. Config.FormatNumber(cash.Value)
	if delta > 0 then
		popDelta("+$" .. Config.FormatNumber(delta))
		cashLabel.TextSize = 38
		TweenService:Create(cashLabel, TweenInfo.new(0.25), { TextSize = 34 }):Play()
	end
end

local function updateStats()
	local rating = player:GetAttribute("GymRating") or 0
	local customers = player:GetAttribute("Customers") or 0
	local maxCustomers = player:GetAttribute("MaxCustomers") or 0
	local mult = player:GetAttribute("IncomeMult") or 1
	statsLabel.Text = string.format(
		"⭐ %d   👥 %d/%d   💪 %s   📈 x%.2f",
		rating,
		customers,
		maxCustomers,
		Config.FormatNumber(strength.Value),
		mult
	)

	local register = player:GetAttribute("Register") or 0
	local auto = player:GetAttribute("AutoCollect")
	registerLabel.Visible = register > 0 and not auto
	registerLabel.Text = "🧾 $" .. Config.FormatNumber(register) .. " waiting at your register!"
end

cash.Changed:Connect(updateCash)
strength.Changed:Connect(updateStats)
for _, attribute in { "GymRating", "Customers", "MaxCustomers", "IncomeMult", "Register", "AutoCollect" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateStats)
end
updateCash()
updateStats()
