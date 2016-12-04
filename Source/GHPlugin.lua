-- Squelch warnings.
plugin = plugin

local MaxStatusTime = 2
local ClassNameShorthands = {
	loc = "LocalScript";
	["local"] = "LocalScript";
	mod = "ModuleScript";
	module = "ModuleScript";
}

local AllowedExtensions = {
	lua = true,
	rbxs = true
}

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local GuiController = require(script.GuiController)
local GitHubCloner = require(script.GitHubCloner)

local toolbar = plugin:CreateToolbar("GitHub Cloner")
local uiToggleButton = toolbar:CreateButton("Clone from GitHub", "Opens the plugin's user interface, allowing you to clone a repository from GitHub.", "")

local uiOpen = false
local lastStatusSet = 0

local function PushStatus(text)
	GuiController.SetStatus(text)
	local sentTick = tick()
	lastStatusSet = sentTick
	
	delay(MaxStatusTime, function()
		if lastStatusSet == sentTick then
			GuiController.SetStatus(nil)
		end
	end)
end

local function CloneTo(path, root, source)
	local level = root
	
	local parts = {}
	
	for chunk in path:gmatch("[^\\/]+") do
		table.insert(parts, chunk)
	end
	
	for index, chunk in ipairs(parts) do
		if index == #parts then
			local name = chunk:match("^([^%.]+)")
			local objectType = chunk:match("^[^%.]+%.(%w+)"):lower()
			local object
			
			if ClassNameShorthands[objectType] then
				object = Instance.new(ClassNameShorthands[objectType])
			else
				local inSourceType = source:match("%-%-#%s*type=(%w+)")
				
				if inSourceType ~= nil and inSourceType:len() > 0 and ClassNameShorthands[inSourceType] ~= nil then
					object = Instance.new(ClassNameShorthands[inSourceType])
				else
					object = Instance.new("Script")
				end
			end
			
			object.Source = source
			object.Name = name
			object.Parent = level
		else
			if level:FindFirstChild(chunk) then
				level = level[chunk]
			else
				local newLevel = Instance.new("Folder", level)
				newLevel.Name = chunk
				level = newLevel
			end
		end
	end
end

GuiController.CloneAttempt:Connect(function()
	if not GuiController.AreCloneAttemptsEnabled() then
		return
	end
	
	ChangeHistoryService:SetWaypoint("GitHub Clone")
	
	GuiController.SetStatus("Checking info")
	local info = GuiController.GetRepositoryInfo()
	local branch = GuiController.GetBranch()
	local subfolder = GuiController.GetSubfolder()
	local rateLimit = GitHubCloner.GetRateLimit()
	
	-- Over rate limit; no requests will succeed
	if rateLimit.Remaining <= 0 then
		local minutes = math.ceil((rateLimit.Reset - os.time()) / 60)
		PushStatus("Rate limit exceeded; try again in "..minutes.." minute"..(minutes == 1 and "" or "s"))
		return
	end
	
	if not info.Valid then
		PushStatus("Please enter a valid repository URL.")
		return
	end
	
	print("Cloning repository. User: "..info.Username.."; repository: "..info.Repository.."; branch/tag: "..branch.."; subfolder: "..subfolder)
	GuiController.SetStatus("Cloning")
	local success, result = pcall(GitHubCloner.Clone, info.Username, info.Repository, branch)
	
	if not success then
		PushStatus("Error cloning; see Output for more details.")
		print("Error cloning: "..result)
		return
	end
	
	GuiController.SetStatus("Instantiating")
	print("Repository cloned, creating objects.")
	
	table.sort(result, function(a, b)
		return a.Path:len() < b.Path:len()
	end)
	
	for _, file in ipairs(result) do
		if file.Path:match("^"..subfolder) and AllowedExtensions[file.Path:match("%.(%w+)$")] then
			CloneTo(file.Path:gsub("^"..subfolder, ""), GuiController.GetCloneTarget(), file.Content)
		end
	end
	
	print("Done!")
	GuiController.SetStatus(nil)
end)

uiToggleButton.Click:Connect(function()
	uiOpen = not uiOpen
	uiToggleButton:SetActive(uiOpen)
	GuiController.SetVisible(uiOpen)
end)

GuiController.SetVisible(false)
