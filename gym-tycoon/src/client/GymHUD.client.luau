--!nonstrict
-- GymHUD (LocalScript in StarterPlayer > StarterPlayerScripts)
-- Cash counter, gym stats, register reminder, popups, Gamepass Shop and Rebirth menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local remotes = ReplicatedStorage:WaitForChild("GymRemotes")
local notifyEvent = remotes:WaitForChild("Notify")
local rebirthEvent = remotes:WaitForChild("RequestRebirth")

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
local CARD = Color3.fromRGB(36, 39, 48)
local GOLD = Color3.fromRGB(255, 170, 0)
local GREEN = Color3.fromRGB(90, 230, 120)
local RED = Color3.fromRGB(231, 76, 60)
local GREY = Color3.fromRGB(90, 92, 100)
local WHITE = Color3.fromRGB(235, 236, 242)

local gui = create("ScreenGui", {
	Name = "GymHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

---------------------------------------------------------------------------
-- Top panel
---------------------------------------------------------------------------
local panel = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(380, 80),
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
	TextColor3 = WHITE,
	Text = "",
	Parent = panel,
})

local registerLabel = create("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 94),
	Size = UDim2.fromOffset(380, 30),
	BackgroundColor3 = GOLD,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = DARK,
	Visible = false,
	Text = "",
	Parent = gui,
}, { corner(10) })

-- Help text ------------------------------------------------------------------
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
	TextColor3 = WHITE,
	Text = "🟢 Step on pads to build & hire staff\n🧾 Collect customer cash at the gold register\n💪 Work out on machines to gain Strength (+income)\n🔁 Buy the Boxing Ring, then Rebirth for x income",
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

---------------------------------------------------------------------------
-- Toasts
---------------------------------------------------------------------------
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
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.45)
		label:Destroy()
	end)
	for _, child in toastHolder:GetChildren() do
		if child:IsA("TextLabel") and child.LayoutOrder <= toastCount - 5 then
			child:Destroy()
		end
	end
end

notifyEvent.OnClientEvent:Connect(toast)

---------------------------------------------------------------------------
-- Side buttons + popup windows
---------------------------------------------------------------------------
local sideBar = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(130, 104),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function sideButton(text, color, order)
	return create("TextButton", {
		Size = UDim2.fromOffset(130, 48),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		Text = text,
		LayoutOrder = order,
		AutoButtonColor = true,
		Parent = sideBar,
	}, { corner(12), create("UIStroke", { Color = DARK, Thickness = 2 }) })
end

local shopButton = sideButton("🛒 Shop", Color3.fromRGB(40, 140, 240), 1)
local rebirthButton = sideButton("🔁 Rebirth", Color3.fromRGB(170, 70, 230), 2)

local windows = {}
local function makeWindow(title, height)
	local window = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, height),
		BackgroundColor3 = DARK,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	}, {
		corner(16),
		create("UIStroke", { Color = GOLD, Thickness = 2 }),
		create("UISizeConstraint", { MaxSize = Vector2.new(440, height) }),
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -70, 0, 36),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GOLD,
		Text = title,
		ZIndex = 5,
		Parent = window,
	})
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = RED,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "X",
		ZIndex = 6,
		Parent = window,
	}, { corner(8) })
	close.Activated:Connect(function()
		window.Visible = false
	end)
	table.insert(windows, window)
	return window
end

local function toggle(window)
	local show = not window.Visible
	for _, w in windows do
		w.Visible = false
	end
	window.Visible = show
end

---------------------------------------------------------------------------
-- Gamepass shop
---------------------------------------------------------------------------
local shopWindow = makeWindow("🛒 Gamepasses", 420)
local shopList = create("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.new(1, -24, 1, -68),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 5,
	Parent = shopWindow,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local passButtons = {} -- [key] = { Button, Pass, Price }

local function refreshPassButton(key)
	local entry = passButtons[key]
	local button, pass = entry.Button, entry.Pass
	if player:GetAttribute("Pass_" .. key) then
		button.Text = "✅ Owned"
		button.BackgroundColor3 = GREY
	elseif not pass.Id or pass.Id <= 0 then
		button.Text = "Coming soon"
		button.BackgroundColor3 = GREY
	else
		button.Text = entry.Price and ("R$ " .. entry.Price) or "Buy"
		button.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
	end
end

local sortedPasses = {}
for key, pass in Config.GamePasses do
	table.insert(sortedPasses, { Key = key, Pass = pass })
end
table.sort(sortedPasses, function(a, b)
	return (a.Pass.Order or 99) < (b.Pass.Order or 99)
end)

for i, entry in sortedPasses do
	local key, pass = entry.Key, entry.Pass
	local card = create("Frame", {
		Size = UDim2.new(1, -8, 0, 78),
		BackgroundColor3 = CARD,
		LayoutOrder = i,
		ZIndex = 5,
		Parent = shopList,
	}, { corner(12) })
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -140, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = WHITE,
		Text = (pass.Icon or "") .. " " .. pass.Name,
		ZIndex = 5,
		Parent = card,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 36),
		Size = UDim2.new(1, -140, 0, 36),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(190, 195, 210),
		Text = pass.Description or "",
		ZIndex = 5,
		Parent = card,
	})
	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(112, 44),
		BackgroundColor3 = GREY,
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "...",
		ZIndex = 6,
		Parent = card,
	}, { corner(10) })
	passButtons[key] = { Button = button, Pass = pass }

	button.Activated:Connect(function()
		if player:GetAttribute("Pass_" .. key) or not pass.Id or pass.Id <= 0 then
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	end)
	player:GetAttributeChangedSignal("Pass_" .. key):Connect(function()
		refreshPassButton(key)
	end)

	if pass.Id and pass.Id > 0 then
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, pass.Id, Enum.InfoType.GamePass)
			if ok and info and info.PriceInRobux then
				passButtons[key].Price = info.PriceInRobux
				refreshPassButton(key)
			end
		end)
	end
	refreshPassButton(key)
end

shopButton.Activated:Connect(function()
	toggle(shopWindow)
end)

---------------------------------------------------------------------------
-- Rebirth window
---------------------------------------------------------------------------
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local strength = leaderstats:WaitForChild("Strength")
local rebirths = leaderstats:WaitForChild("Rebirths")

local rebirthWindow = makeWindow("🔁 Rebirth", 330)
local rebirthInfo = create("TextLabel", {
	Position = UDim2.fromOffset(18, 56),
	Size = UDim2.new(1, -36, 0, 190),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 17,
	TextWrapped = true,
	RichText = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = WHITE,
	Text = "",
	ZIndex = 5,
	Parent = rebirthWindow,
})
local confirmButton = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(240, 52),
	BackgroundColor3 = Color3.fromRGB(170, 70, 230),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "REBIRTH!",
	ZIndex = 6,
	Parent = rebirthWindow,
}, { corner(12) })

local function rebirthReady()
	local cost = player:GetAttribute("RebirthCost") or math.huge
	return player:GetAttribute("RebirthItemOwned") == true and cash.Value >= cost
end

local function check(ok)
	return ok and '<font color="#5AE678">✅</font>' or '<font color="#E74C3C">❌</font>'
end

local function refreshRebirth()
	local count = rebirths.Value
	local cost = player:GetAttribute("RebirthCost") or Config.GetRebirthCost(count)
	local itemOwned = player:GetAttribute("RebirthItemOwned") == true
	local item = Config.ItemsById[Config.Rebirth.RequiredItem]
	rebirthInfo.Text = string.format(
		"Rebirths so far: <b>%d</b>  (income x%.1f)\n\n<b>Requirements</b>\n%s Own the %s\n%s Have $%s cash\n\n<b>Reward:</b> income forever x%.1f → <font color=\"#5AE678\">x%.1f</font>\n<font color=\"#AAAAB4\">Your gym and cash reset. Strength and gamepasses stay.</font>",
		count,
		Config.GetRebirthMultiplier(count),
		check(itemOwned),
		item and item.Name or "final item",
		check(cash.Value >= cost),
		Config.FormatNumber(cost),
		Config.GetRebirthMultiplier(count),
		Config.GetRebirthMultiplier(count + 1)
	)
	local ready = rebirthReady()
	confirmButton.BackgroundColor3 = ready and Color3.fromRGB(170, 70, 230) or GREY
	confirmButton.Text = ready and "REBIRTH!" or "Not ready yet"
	rebirthButton.Text = ready and "🔁 Rebirth!" or "🔁 Rebirth"
end

confirmButton.Activated:Connect(function()
	if rebirthReady() then
		rebirthEvent:FireServer()
		rebirthWindow.Visible = false
	end
end)
rebirthButton.Activated:Connect(function()
	refreshRebirth()
	toggle(rebirthWindow)
end)

---------------------------------------------------------------------------
-- Cash + stats
---------------------------------------------------------------------------
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
	TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
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
	refreshRebirth()
end

local function updateStats()
	statsLabel.Text = string.format(
		"⭐ %d   👥 %d/%d   💪 %s   🔁 %d   📈 x%.2f",
		player:GetAttribute("GymRating") or 0,
		player:GetAttribute("Customers") or 0,
		player:GetAttribute("MaxCustomers") or 0,
		Config.FormatNumber(strength.Value),
		rebirths.Value,
		player:GetAttribute("IncomeMult") or 1
	)
	local register = player:GetAttribute("Register") or 0
	registerLabel.Visible = register > 0 and not player:GetAttribute("AutoCollect")
	registerLabel.Text = "🧾 $" .. Config.FormatNumber(register) .. " waiting at your register!"
	refreshRebirth()
end

cash.Changed:Connect(updateCash)
strength.Changed:Connect(updateStats)
rebirths.Changed:Connect(updateStats)
for _, attribute in { "GymRating", "Customers", "MaxCustomers", "IncomeMult", "Register", "AutoCollect", "RebirthCost", "RebirthItemOwned" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateStats)
end
updateCash()
updateStats()
