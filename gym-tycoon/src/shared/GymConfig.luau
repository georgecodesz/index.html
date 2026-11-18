--!nonstrict
-- GymConfig (ModuleScript in ReplicatedStorage)
-- Every number you'd want to tweak lives here: prices, layout, customer behaviour.

local Config = {}

---------------------------------------------------------------------
-- General
---------------------------------------------------------------------
Config.StartingCash = 150
Config.PlotCount = 6 -- one gym per player, so this is also the max server size
Config.PlotSize = 90 -- studs (square)
Config.PlotSpacing = 100
Config.FloorHeight = 0.2 -- top of each gym floor (sits just above a standard Baseplate)
Config.AutosaveInterval = 60
Config.DataStoreName = "GymTycoon_v1"

-- Working out yourself gives Strength. Each point of Strength boosts your gym's income.
Config.StrengthIncomeBonus = 0.002 -- +0.2% income per Strength
Config.MaxStrengthBonus = 2 -- capped at +200%
Config.WorkoutCooldown = 0.6

---------------------------------------------------------------------
-- Rebirths
-- Once you own the RequiredItem and have enough cash you can rebirth:
-- your gym + cash reset, but you keep a permanent income multiplier.
-- Strength and gamepasses are kept.
---------------------------------------------------------------------
Config.Rebirth = {
	RequiredItem = "BoxingRing",
	BaseCost = 100000, -- cash needed for the 1st rebirth
	CostMultiplier = 2, -- each rebirth needs 2x more
	IncomeBonus = 0.5, -- +50% income per rebirth (permanent)
}

---------------------------------------------------------------------
-- Gamepasses
-- 1. Create each pass on create.roblox.com > your experience > Monetization > Passes
-- 2. Paste its ID below (0 = not set up yet; it shows as "coming soon" in the shop)
---------------------------------------------------------------------
Config.GamePasses = {
	DoubleCash = { Order = 1, Id = 0, Icon = "💰", Name = "2x Cash", Description = "Double money from every customer, forever." },
	AutoCollect = { Order = 2, Id = 0, Icon = "🧾", Name = "Auto Collect", Description = "Customer cash goes straight into your wallet." },
	VIPGym = { Order = 3, Id = 0, Icon = "⭐", Name = "VIP Gym", Description = "+50% customer arrivals and +5 max customers." },
	SuperStrength = { Order = 4, Id = 0, Icon = "💪", Name = "Super Strength", Description = "2x Strength from every workout." },
}
-- Set true to get every pass for free while testing in Studio
Config.GiveAllPassesInStudio = false

---------------------------------------------------------------------
-- Customers
---------------------------------------------------------------------
Config.Customer = {
	BaseSpawnInterval = 7, -- seconds between customers with an empty gym
	MinSpawnInterval = 1.5,
	RatingSpawnBonus = 0.08, -- each rating point makes customers arrive 8% faster
	BaseMaxCustomers = 2,
	CustomersPerStation = 1.5,
	EntryFee = 5, -- paid at the front desk
	WalkSpeed = 14,
	MinVisits = 1, -- how many machines each customer uses
	MaxVisits = 3,
	MaxWait = 8, -- seconds they'll wait for a free machine before leaving
	MaxLifetime = 180, -- safety: despawn anyone who gets stuck
}

---------------------------------------------------------------------
-- Fixed plot layout (local coordinates, +Z is the street side / entrance)
---------------------------------------------------------------------
Config.Layout = {
	Desk = Vector3.new(0, 0, 30),
	DeskPoint = Vector3.new(0, 0, 34.5),
	Entrance = Vector3.new(0, 0, 49),
	CustomerSpawn = Vector3.new(0, 0, 68),
	WaitSpot = Vector3.new(12, 0, 36),
	CollectPad = Vector3.new(36, 0, 38),
	PlayerSpawn = Vector3.new(0, 0, 58),
}

-- Status text customers show while using each machine
Config.Verbs = {
	Treadmill = "🏃 Running",
	DumbbellRack = "💪 Curling",
	Bench = "🏋️ Bench pressing",
	SquatRack = "🦵 Squatting",
	Rowing = "🚣 Rowing",
	PunchingBag = "🥊 Hitting the bag",
	CableMachine = "💪 Pulling cables",
	YogaMat = "🧘 Stretching",
	SmoothieBar = "🥤 Drinking a smoothie",
	Sauna = "♨️ Relaxing",
	BoxingRing = "🥊 Sparring",
}

---------------------------------------------------------------------
-- Items
--  Kind = "Station" -> customers use it and pay `Pay`; you can work out on it for `Strength`
--  Kind = "Decor"   -> only adds Rating (more rating = more customers)
--  Kind = "Upgrade" -> no model, applies an Effect
-- A buy-pad appears once everything in `Requires` is owned.
---------------------------------------------------------------------
local function v(x, z)
	return Vector3.new(x, 0, z)
end

Config.Items = {
	-- Starter equipment
	{ Id = "Treadmill1", Name = "Treadmill", Kind = "Station", Model = "Treadmill", Price = 50, Position = v(-38, 10), Rating = 1, Pay = 6, Duration = 6, Strength = 1 },
	{ Id = "Treadmill2", Name = "Treadmill #2", Kind = "Station", Model = "Treadmill", Price = 150, Position = v(-32, 10), Requires = "Treadmill1", Rating = 1, Pay = 6, Duration = 6, Strength = 1 },
	{ Id = "DumbbellRack", Name = "Dumbbell Rack", Kind = "Station", Model = "DumbbellRack", Price = 250, Position = v(-36, -12), Requires = "Treadmill1", Rating = 1, Pay = 8, Duration = 6, Strength = 2 },
	{ Id = "Flyers", Name = "Hand Out Flyers", Kind = "Upgrade", Price = 300, Position = v(-40, 40), Requires = "Treadmill2", Effect = { Type = "SpawnRate", Value = 0.3 }, Description = "+30% customer arrivals" },
	{ Id = "Bench1", Name = "Bench Press", Kind = "Station", Model = "Bench", Price = 450, Position = v(-14, 10), Requires = "DumbbellRack", Rating = 2, Pay = 10, Duration = 7, Strength = 3 },
	{ Id = "Walls", Name = "Gym Walls", Kind = "Decor", Model = "Walls", Price = 600, Position = v(0, 0), ButtonPosition = v(38, 28), Requires = "Treadmill2", Rating = 4 },
	{ Id = "Membership1", Name = "Monthly Memberships", Kind = "Upgrade", Price = 700, Position = v(-33, 40), Requires = "Bench1", Effect = { Type = "IncomeMult", Value = 0.25 }, Description = "+25% income" },
	{ Id = "Treadmill3", Name = "Treadmill #3", Kind = "Station", Model = "Treadmill", Price = 800, Position = v(-26, 10), Requires = "Treadmill2", Rating = 1, Pay = 6, Duration = 6, Strength = 1 },
	{ Id = "Plants", Name = "Potted Plants", Kind = "Decor", Model = "Plants", Price = 900, Position = v(0, 0), ButtonPosition = v(22, 28), Requires = "Walls", Rating = 2 },
	{ Id = "SquatRack1", Name = "Squat Rack", Kind = "Station", Model = "SquatRack", Price = 1000, Position = v(-24, -12), Requires = "Bench1", Rating = 2, Pay = 14, Duration = 7, Strength = 4 },
	{ Id = "Lockers", Name = "Bigger Locker Room", Kind = "Upgrade", Price = 1200, Position = v(-26, 40), Requires = "SquatRack1", Effect = { Type = "Capacity", Value = 4 }, Description = "+4 max customers" },
	{ Id = "Rowing1", Name = "Rowing Machine", Kind = "Station", Model = "Rowing", Price = 1500, Position = v(-15, -12), Requires = "SquatRack1", Rating = 2, Pay = 18, Duration = 7, Strength = 2 },
	{ Id = "RubberFloor", Name = "Rubber Flooring", Kind = "Decor", Model = "RubberFloor", Price = 1800, Position = v(0, 0), ButtonPosition = v(30, 28), Requires = "Walls", Rating = 3 },
	{ Id = "PunchingBag1", Name = "Punching Bag", Kind = "Station", Model = "PunchingBag", Price = 2200, Position = v(26, -12), Requires = "Rowing1", Rating = 3, Pay = 24, Duration = 6, Strength = 3 },
	{ Id = "CardReader", Name = "Card Reader", Kind = "Upgrade", Price = 3000, Position = v(-19, 40), Requires = "Membership1", Effect = { Type = "AutoCollect" }, Description = "Cash goes straight to you" },
	{ Id = "Cable1", Name = "Cable Machine", Kind = "Station", Model = "CableMachine", Price = 3000, Position = v(26, 10), Requires = "PunchingBag1", Rating = 3, Pay = 30, Duration = 7, Strength = 4 },
	{ Id = "Bench2", Name = "Bench Press #2", Kind = "Station", Model = "Bench", Price = 3800, Position = v(14, 10), Requires = "Cable1", Rating = 2, Pay = 10, Duration = 7, Strength = 3 },
	{ Id = "Billboard", Name = "Billboard Ads", Kind = "Upgrade", Price = 4000, Position = v(-40, 33), Requires = "Flyers", Effect = { Type = "SpawnRate", Value = 0.5 }, Description = "+50% customer arrivals" },
	{ Id = "Mirrors", Name = "Wall Mirrors", Kind = "Decor", Model = "Mirrors", Price = 4500, Position = v(0, 0), ButtonPosition = v(38, 21), Requires = "RubberFloor", Rating = 3 },
	{ Id = "YogaMat1", Name = "Yoga Mat", Kind = "Station", Model = "YogaMat", Price = 5000, Position = v(-40, -32), Requires = "Bench2", Rating = 2, Pay = 38, Duration = 8, Strength = 2 },
	{ Id = "Rowing2", Name = "Rowing Machine #2", Kind = "Station", Model = "Rowing", Price = 6000, Position = v(-10, -12), Requires = "YogaMat1", Rating = 2, Pay = 18, Duration = 7, Strength = 2 },
	{ Id = "Membership2", Name = "Premium Memberships", Kind = "Upgrade", Price = 7500, Position = v(-33, 33), Requires = { "Membership1", "Cable1" }, Effect = { Type = "IncomeMult", Value = 0.5 }, Description = "+50% income" },
	{ Id = "SquatRack2", Name = "Squat Rack #2", Kind = "Station", Model = "SquatRack", Price = 8000, Position = v(16, -12), Requires = "Rowing2", Rating = 2, Pay = 14, Duration = 7, Strength = 4 },
	{ Id = "Speakers", Name = "Sound System", Kind = "Decor", Model = "Speakers", Price = 8000, Position = v(0, 0), ButtonPosition = v(30, 21), Requires = "Mirrors", Rating = 3 },
	{ Id = "PunchingBag2", Name = "Punching Bag #2", Kind = "Station", Model = "PunchingBag", Price = 10000, Position = v(35, -12), Requires = "SquatRack2", Rating = 3, Pay = 24, Duration = 6, Strength = 3 },
	{ Id = "YogaMat2", Name = "Yoga Mat #2", Kind = "Station", Model = "YogaMat", Price = 11000, Position = v(-34.5, -32), Requires = "PunchingBag2", Rating = 2, Pay = 38, Duration = 8, Strength = 2 },
	{ Id = "Cable2", Name = "Cable Machine #2", Kind = "Station", Model = "CableMachine", Price = 13000, Position = v(36, 10), Requires = "YogaMat2", Rating = 3, Pay = 30, Duration = 7, Strength = 4 },
	{ Id = "NeonSign", Name = "Giant Neon Sign", Kind = "Decor", Model = "NeonSign", Price = 15000, Position = v(0, 0), ButtonPosition = v(22, 21), Requires = "Speakers", Rating = 6 },
	{ Id = "SmoothieBar", Name = "Smoothie Bar", Kind = "Station", Model = "SmoothieBar", Price = 18000, Position = v(28, -32), Requires = "Cable2", Rating = 4, Pay = 55, Duration = 4, Strength = 1 },
	{ Id = "TVAds", Name = "TV Commercial", Kind = "Upgrade", Price = 20000, Position = v(-26, 33), Requires = { "Billboard", "SmoothieBar" }, Effect = { Type = "SpawnRate", Value = 1 }, Description = "+100% customer arrivals" },
	{ Id = "Sauna", Name = "Sauna", Kind = "Station", Model = "Sauna", Price = 28000, Position = v(-20, -32), Requires = "SmoothieBar", Rating = 5, Pay = 90, Duration = 10, Strength = 1 },
	{ Id = "Membership3", Name = "VIP Memberships", Kind = "Upgrade", Price = 40000, Position = v(-19, 33), Requires = { "Membership2", "Sauna" }, Effect = { Type = "IncomeMult", Value = 1 }, Description = "+100% income" },
	{ Id = "BoxingRing", Name = "Boxing Ring", Kind = "Station", Model = "BoxingRing", Price = 60000, Position = v(3, -32), Requires = "Sauna", Rating = 8, Pay = 150, Duration = 9, Strength = 6 },

	-- Staff (Kind = "Staff"): hired NPCs that walk around your gym and give a bonus
	{ Id = "Receptionist", Name = "Receptionist", Kind = "Staff", Role = "Receptionist", Price = 1500, Position = v(16, 41), Requires = "Membership1", Rating = 2, Effect = { Type = "EntryFee", Value = 1 }, Description = "2x check-in fees" },
	{ Id = "Trainer1", Name = "Personal Trainer", Kind = "Staff", Role = "Trainer", Price = 2500, Position = v(23, 41), Requires = "SquatRack1", Rating = 2, Effect = { Type = "IncomeMult", Value = 0.2 }, Description = "+20% income" },
	{ Id = "Janitor", Name = "Janitor", Kind = "Staff", Role = "Janitor", Price = 3500, Position = v(29, 41), Requires = "RubberFloor", Rating = 6, Description = "+6 rating (clean gym!)" },
	{ Id = "Trainer2", Name = "Personal Trainer #2", Kind = "Staff", Role = "Trainer", Price = 9000, Position = v(16, 34), Requires = { "Trainer1", "Bench2" }, Rating = 2, Effect = { Type = "IncomeMult", Value = 0.25 }, Description = "+25% income" },
	{ Id = "DJ", Name = "Gym DJ", Kind = "Staff", Role = "DJ", Model = "DJBooth", Price = 12000, Position = v(-9, -40), ButtonPosition = v(23, 34), Requires = "Speakers", Rating = 3, Effect = { Type = "SpawnRate", Value = 0.4 }, Description = "+40% customer arrivals" },
	{ Id = "Manager", Name = "Gym Manager", Kind = "Staff", Role = "Manager", Price = 25000, Position = v(29, 34), Requires = "SmoothieBar", Rating = 3, Effect = { Type = "ExtraVisits", Value = 1 }, Description = "Customers use +1 machine" },
	{ Id = "Trainer3", Name = "Head Coach", Kind = "Staff", Role = "Trainer", Price = 45000, Position = v(16, 27), Requires = { "Trainer2", "Sauna" }, Rating = 3, Effect = { Type = "IncomeMult", Value = 0.35 }, Description = "+35% income" },
}

Config.ItemsById = {}
for index, item in Config.Items do
	item.Order = index
	if type(item.Requires) == "string" then
		item.Requires = { item.Requires }
	end
	Config.ItemsById[item.Id] = item
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
function Config.FormatNumber(n: number): string
	n = math.floor(n or 0)
	local sign = n < 0 and "-" or ""
	local a = math.abs(n)
	if a >= 1e9 then
		return sign .. string.format("%.2fB", a / 1e9)
	elseif a >= 1e6 then
		return sign .. string.format("%.2fM", a / 1e6)
	elseif a >= 1e5 then
		return sign .. string.format("%.1fK", a / 1e3)
	end
	local s = tostring(a):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if s:sub(1, 1) == "," then
		s = s:sub(2)
	end
	return sign .. s
end

function Config.GetRebirthCost(rebirths: number): number
	return math.floor(Config.Rebirth.BaseCost * Config.Rebirth.CostMultiplier ^ (rebirths or 0))
end

function Config.GetRebirthMultiplier(rebirths: number): number
	return 1 + (rebirths or 0) * Config.Rebirth.IncomeBonus
end

return Config
