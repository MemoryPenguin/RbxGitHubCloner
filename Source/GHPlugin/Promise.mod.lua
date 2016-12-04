local Promise = {}
Promise.__index = Promise

function Promise.new()
	local self = setmetatable({
		IsFulfilled = false;
		_fulfilledSignal = Instance.new("BindableEvent");
	}, Promise)
	
	self.Fulfilled = self._fulfilledSignal.Event
	return self
end

function Promise:Fulfill(...)
	if not self.IsFulfilled then
		self.Values = {...}
		self.IsFulfilled = true
		self._fulfilledSignal:Fire(...)
	end
end

function Promise.All(...)
	local agglomerate = Promise.new()
	local waitingOn = select("#", ...)
	local values = {}
	
	for i = 1, select("#", ...) do
		local promise = select(i, ...)
		local connection
		connection = promise.Fulfilled:Connect(function(...)
			connection:Disconnect()
			waitingOn = waitingOn - 1

			table.insert(values, {...})
			
			if waitingOn == 0 then
				agglomerate:Fulfill(values)
			end
		end)
	end
	
	return agglomerate
end

function Promise.Any(...)
	local agglomerate = Promise.new()
	local connections = {}
	
	for i = 1, select("#", ...) do
		local promise = select(i, ...)
		table.insert(connections, promise.Fulfilled:Connect(function(...)
			for _, connection in ipairs(connections) do
				if connection.Connected then
					connection:Disconnect()
				end
			end
			
			agglomerate:Fulfill(...)
		end))
	end
	
	return agglomerate
end

function Promise.FromEvent(event)
	local connection
	local promise = Promise.new()
	
	connection = event:Connect(function(...)
		promise:Fulfill(...)
		connection:Disconnect()
	end)
	
	return promise
end

return Promise