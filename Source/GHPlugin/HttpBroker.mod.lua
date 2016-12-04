-- A broker for HTTP requests.
local DefaultRequestLimit = 100
local MaximumRequestLimit = 500
local RequestTimeoutTime = 60
local LimitBackoffTime = 15

local HttpService = game:GetService("HttpService")
local HttpServiceMethods = { Get = HttpService.GetAsync, Post = HttpService.PostAsync }

-- Module requiring
local Promise = require(script.Parent.Promise)

local function BuildRequest(guid, method, ...)
	return {
		Guid = guid;
		Method = method;
		Arguments = {...};
	}
end

local HttpBroker = {}
HttpBroker.__index = HttpBroker

function HttpBroker.new(requestLimit)
	requestLimit = requestLimit or DefaultRequestLimit
	
	return setmetatable({
		_queue = {};
		_used = 0;
		_limit = requestLimit;
		_requesting = false;
		_requestAvailableSignal = Instance.new("BindableEvent");
		_requestCompleteSignal = Instance.new("BindableEvent");
	}, HttpBroker)
end

function HttpBroker:_performRequest()
	if self._used >= self._limit then
		self._requestAvailableEvent.Event:Wait()
	end
	
	local request = self._queue[1]
	
	while true do
		local success, result = pcall(request.Method, HttpService, unpack(request.Arguments))
	
		if success or result ~= "Number of requests exceeded limit" then
			self._requestCompleteSignal:Fire(request.Guid, success, result)
			self._used = self._used + 1
			delay(RequestTimeoutTime, function()
				self._used = self._used - 1
				
				if self._used < self._limit then
					self._requestAvailableSignal:Fire()
				end
			end)

			table.remove(self._queue, 1)
			
			break
		else
			-- Request has stalled due to global HttpService budget exhaustion.
			-- Back off a bit.
			wait(LimitBackoffTime)
		end
	end
end

function HttpBroker:_startRequestLoop()
	if self._requesting then return end
	
	self._requesting = true
	
	while #self._queue > 0 do
		self:_performRequest()
	end
	
	self._requesting = false
end

function HttpBroker:_queueRequest(request)
	table.insert(self._queue, request)
	spawn(function() self:_startRequestLoop() end)
end

function HttpBroker:_waitOnRequest(request)
	while true do
		local completeGuid, success, result = self._requestCompleteSignal.Event:Wait()
		
		if completeGuid == request.Guid then
			return success, result
		end
	end
end

for name, method in pairs(HttpServiceMethods) do
	HttpBroker[name] = function(self, ...)
		local guid = HttpService:GenerateGUID()
		local request = {
			Guid = guid;
			Method = HttpService.GetAsync;
			Arguments = { ... };
		}
		
		self:_queueRequest(request)
		return self:_waitOnRequest(request)
	end
end

if Promise ~= nil then
	for name, method in pairs(HttpServiceMethods) do
		HttpBroker[name.."Async"] = function(self, ...)
			local promise = Promise.new()
			local request = BuildRequest(HttpService:GenerateGUID(), method, ...)
			
			self:_queueRequest(request)
			
			local connection
			connection = self._requestCompleteSignal:Connect(function(guid, status, result)
				if guid == request.Guid then
					connection:Disconnect()
					promise:Fulfill(status, result)
				end
			end)
			
			return promise
		end
	end
end

return HttpBroker
