local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets

local Jobs = Assets.Events

local RemoteClass = {}
RemoteClass.__index = RemoteClass

function RemoteClass:CompleteAction(...)
	local Callback = self.Callback
	
	if not Callback then
		return
	end
	
	return Callback(...)
end

function RemoteClass:CreateEvent()
	local Event = self.RemoteEvent
	local Function = self.RemoteFunction
	
	Event.OnServerEvent:Connect(function(...)
		self:CompleteAction(...)
	end)
	
	Function.OnServerInvoke = function(...)
		return self:CompleteAction(...)
	end
	
	return self
end

function RemoteClass.new(Job, Callback)
	local Folder = Instance.new("Folder", Jobs)
	Folder.Name = Job
	
	local self = setmetatable({}, RemoteClass)
	
	self.Job = Job
	self.Folder = Folder
	self.RemoteEvent = Instance.new("RemoteEvent", Folder)
	self.RemoteFunction = Instance.new("RemoteFunction", Folder)
	self.Callback = Callback
	
	return self:CreateEvent()
end

return RemoteClass
