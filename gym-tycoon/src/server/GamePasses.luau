--!nonstrict
-- GamePasses (ModuleScript, child of GymServer)
-- Checks which passes a player owns and marks them with attributes like "Pass_DoubleCash".
-- The effects themselves are applied in Plot.luau.

local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Remotes = require(script.Parent.Remotes)

local GamePasses = {}

local function grant(player, key)
	if player.Parent then
		player:SetAttribute("Pass_" .. key, true)
	end
end

function GamePasses.Has(player, key)
	return player ~= nil and player:GetAttribute("Pass_" .. key) == true
end

function GamePasses.Load(player)
	for key, pass in Config.GamePasses do
		if Config.GiveAllPassesInStudio and RunService:IsStudio() then
			grant(player, key)
		elseif pass.Id and pass.Id > 0 then
			task.spawn(function()
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
				if ok and owns then
					grant(player, key)
				end
			end)
		end
	end
end

-- Give the pass right away when it's bought in-game (no rejoin needed)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	for key, pass in Config.GamePasses do
		if pass.Id == passId then
			grant(player, key)
			Remotes.Notify(player, "🎉 Thanks for buying " .. pass.Name .. "!", Color3.fromRGB(255, 200, 40))
		end
	end
end)

return GamePasses
