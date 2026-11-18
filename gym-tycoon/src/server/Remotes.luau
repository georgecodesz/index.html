--!nonstrict
-- Remotes (ModuleScript, child of GymServer)
-- Creates ReplicatedStorage.GymRemotes:
--   Notify          server -> client popup messages
--   RequestRebirth  client -> server when the Rebirth button is pressed

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = ReplicatedStorage:FindFirstChild("GymRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "GymRemotes"
	folder.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

local notify = getRemote("Notify")
Remotes.RequestRebirth = getRemote("RequestRebirth")

function Remotes.Notify(player, text, color)
	if player and player.Parent then
		notify:FireClient(player, text, color)
	end
end

return Remotes
