-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Communication = Assets.Communication
local Events = Assets.Events

-------------------------- Framework --------------------------

local Network = {}

Network.Jobs = {}

Network.NetworkingEvent = Communication.SendToClient
Network.NetworkFunction = Communication.UpdateClient

function Network:FireServer(Job, ...)
	local Event = Events:FindFirstChild(Job)

	if not Event then
		return
	end

	local RemoteEvent = Event.RemoteEvent

	return RemoteEvent:FireServer(...)
end

function Network:InvokeServer(Job, ...)
	local Event = Events:FindFirstChild(Job)
	
	if not Event then
		return
	end
	
	local RemoteFunction = Event.RemoteFunction

	return RemoteFunction:InvokeServer(...)
end

function Network:Bind(Job, Callback)
	self.Jobs[Job] = Callback
end

function Network:Call(Job, ...)
	if not self.Jobs[Job] then
		return
	end

	return self.Jobs[Job](...)
end

Network.NetworkingEvent.OnClientEvent:Connect(function(Job, ...)
	Network:Call(Job, ...)
end)

Network.NetworkFunction.OnClientInvoke = function(Job, ...)
	return Network:Call(Job, ...)
end

return Network
