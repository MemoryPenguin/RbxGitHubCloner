local EnabledColor = Color3.fromRGB(47, 165, 255)
local DisabledColor = Color3.fromRGB(150, 150, 150)
local DefaultCloneTarget = game.ReplicatedStorage
local ScriptTypes = { "Script", "LocalScript", "ModuleScript" }

local CoreGuiService = game:GetService("CoreGui")

local InputWrapper = require(script.InputWrapper)

local gui = script.GHCloneGui
local mainFrame = gui.Main
local statusView = mainFrame.Status
local cloneButton = mainFrame.StartClone
local inputContainer = mainFrame.Inputs

local inputs = {
	CloneLocation = InputWrapper.WrapCloneLocation(inputContainer.CloneLocation, DefaultCloneTarget);
	ApiKey = InputWrapper.WrapTextual(inputContainer.ApiKey, function(value)
		if value ~= "" and (value:len() ~= 40 or not value:match("^[0-9a-f]+$")) then
			return false, "Invalid API key"
		end
		
		return true
	end);
	-- No branch validation so far.
	Branch = InputWrapper.WrapTextual(inputContainer.Branch, function() return true end);
	RepositoryUrl = InputWrapper.WrapTextual(inputContainer.Repository, function(value)
		if not value:match("^https?://github%.com/[%w_-]+/[%w_-]+/?$") then
			return false, "Invalid repository URL"
		end
		
		return true
	end);
	Subfolder = InputWrapper.WrapTextual(inputContainer.Subfolder, function() return true end);
	DefaultType = InputWrapper.WrapEnumerated(inputContainer.DefaultType, ScriptTypes, 1);
}

local lastStatusMessage = tick()

local GuiController = {}
GuiController.Inputs = inputs
GuiController.CloneAttempt = cloneButton.MouseButton1Click

function GuiController.SetStatus(statusText)
	statusView.Text = statusText
end

function GuiController.DisplayStatus(statusText, duration)
	duration = duration or 2
	GuiController.SetStatus(statusText)
	
	local sentAt = tick()
	lastStatusMessage = sentAt
	
	delay(duration, function()
		if lastStatusMessage == sentAt then
			GuiController.SetStatus("")
		end
	end)
end

function GuiController.SetVisible(visible)
	mainFrame.Visible = visible
end

function GuiController.GetRepositoryInfo()
	local text = inputs.RepositoryUrl.Value
	local isValid = inputs.RepositoryUrl.Valid
	local user, repository = text:match("github%.com/([%w_-]+)/([%w_-]+)")
	
	return {
		Valid = isValid;
		Username = user;
		Repository = repository;
	}
end

gui.Parent = CoreGuiService

return GuiController
