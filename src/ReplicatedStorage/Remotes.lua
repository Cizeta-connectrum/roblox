local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

if RunService:IsServer() then
    local folder = Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage
    
    local events = {"CoinsUpdated", "EventAnnounce", "ShowEffect"}
    for _, name in ipairs(events) do
        local e = Instance.new("RemoteEvent")
        e.Name = name
        e.Parent = folder
    end
    
    local funcs = {"PurchaseUpgrade"}
    for _, name in ipairs(funcs) do
        local f = Instance.new("RemoteFunction")
        f.Name = name
        f.Parent = folder
    end
    
    Remotes.folder = folder
else
    Remotes.folder = ReplicatedStorage:WaitForChild("Remotes", 10)
end

function Remotes:Get(name)
    return self.folder:WaitForChild(name, 10)
end

return Remotes
