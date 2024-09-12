local Maid = {}
Maid.__index = Maid

function Maid:Destroy(Task)
	local type = typeof(Task)
	local isTable = type == "table"
	
	local isInstance = type == "Instance" or (isTable and Task.Destroy)
	
	if not isInstance then
		return
	end
	
	return Task:Destroy()
end

function Maid:Cancel(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isDisconnect = type == "Tween" or (isTable and Task.Cancel)

	if not isDisconnect then
		return
	end

	return Task:Cancel()
end

function Maid:Close(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isDisconnect = type == "function" or (isTable and Task.close)

	if not isDisconnect then
		return
	end
	
	if Task.close then
		return Task.close()
	end

	return coroutine.close(Task)
end

function Maid:Disconnect(Task)
	local type = typeof(Task)
	local isTable = type == "table"
	
	local isDisconnect = type == "RBXScriptConnection" or (isTable and Task.Disconnect)

	if not isDisconnect then
		return
	end

	return Task:Disconnect()
end

function Maid:Clean()
	local Tasks = self.Tasks
	
	for _, Task in Tasks do
		self:Destroy(Task)
		self:Cancel(Task)
		self:Disconnect(Task)
	end
	
	table.clear(self)
end

function Maid:GiveTask(Task)
	if not self.Tasks then
		return
	end
	
	return Task, table.insert(
		self.Tasks,
		Task
	)
end

function Maid.new()
	return setmetatable({Tasks = {}}, Maid)
end

return Maid
