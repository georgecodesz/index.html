--!nonstrict
-- Remotes (ModuleScript, child of GymServer)
-- Creates ReplicatedStorage.GymRemotes so the HUD can show popup messages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = ReplicatedStorage:FindFirstChild("GymRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "GymRemotes"
	folder.Parent = ReplicatedStorage
end

local notify = folder:FindFirstChild("Notify")
if not notify then
	notify = Instance.new("RemoteEvent")
	notify.Name = "Notify"
	notify.Parent = folder
end

function Remotes.Notify(player, text, color)
	if player and player.Parent then
		notify:FireClient(player, text, color)
	end
end

return Remotes
