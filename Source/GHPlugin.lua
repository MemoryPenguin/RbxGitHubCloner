-- Squelch warnings.
plugin = plugin

local MaxStatusTime = 2
local ClassNameShorthands = {
	loc = "LocalScript";
	["local"] = "LocalScript";
	mod = "ModuleScript";
	module = "ModuleScript";
	scr = "Script";
	server = "Script";
	["script"] = "Script";
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
					object = Instance.new(GuiController.Inputs.DefaultType.Value)
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
	ChangeHistoryService:SetWaypoint("GitHub Clone")
	
	GuiController.SetStatus("Checking info")
	
	for key, value in pairs(GuiController.Inputs) do
		if value.Valid == false then
			GuiController.DisplayStatus(key.." is invalid.")
			return
		end
	end
	
	local info = GuiController.GetRepositoryInfo()
	local branch = GuiController.Inputs.Branch.Value
	local subfolder = GuiController.Inputs.Subfolder.Value
	local apiKey = GuiController.Inputs.ApiKey.Value
	
	local success, rateLimit = pcall(GitHubCloner.GetRateLimit)
	
	if not success then
		if rateLimit == "Http requests are not enabled" then
			GuiController.DisplayStatus("HTTP requests are disabled")
		else
			GuiController.DisplayStatus("Error retrieving rate limit; see Output for more details.")
			print("Error cloning: "..rateLimit)
		end
		
		return
	end
	
	-- Over rate limit; no requests will succeed
	if rateLimit.Remaining <= 0 then
		local minutes = math.ceil((rateLimit.Reset - os.time()) / 60)
		GuiController.DisplayStatus("Rate limit exceeded; try again in "..minutes.." minute"..(minutes == 1 and "" or "s"))
		return
	end
	
	if not info.Valid then
		GuiController.DisplayStatus("Please enter a valid repository URL.")
		return
	end
	
	print("Cloning repository. User: "..info.Username.."; repository: "..info.Repository.."; branch/tag: "..branch.."; subfolder: "..subfolder)
	
	if apiKey ~= nil and apiKey ~= "" then
		print("Using API key "..apiKey)
	end
	
	GuiController.SetStatus("Cloning")
	local success, result = pcall(GitHubCloner.Clone, info.Username, info.Repository, branch, apiKey)
	
	if not success then
		GuiController.DisplayStatus("Error cloning; see Output for more details.")
		print("Error cloning: "..result)
		return
	else
		plugin:SetSetting("GHApiKey", GuiController.Inputs.ApiKey.Value)
	end
	
	GuiController.SetStatus("Instantiating")
	print("Repository cloned, creating objects.")
	
	table.sort(result, function(a, b)
		return a.Path:len() < b.Path:len()
	end)
	
	for _, file in ipairs(result) do
		if file.Path:match("^"..subfolder) and AllowedExtensions[file.Path:match("%.(%w+)$")] then
			CloneTo(file.Path:gsub("^"..subfolder, ""), GuiController.Inputs.CloneLocation.Value, file.Content)
		end
	end
	
	print("Done!")
	GuiController.SetStatus("")
end)

uiToggleButton.Click:Connect(function()
	uiOpen = not uiOpen
	uiToggleButton:SetActive(uiOpen)
	GuiController.SetVisible(uiOpen)
end)

local savedKey = plugin:GetSetting("GHApiKey")
if savedKey ~= nil and savedKey ~= "" then
	GuiController.Inputs.ApiKey.SetValue(savedKey)
end

GuiController.SetVisible(false)
