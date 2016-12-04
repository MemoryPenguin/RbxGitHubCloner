local ExpandedSize = UDim2.new(0, 400, 0, 390)
local NormalSize = UDim2.new(0, 400, 0, 360)
local EnabledColor = Color3.fromRGB(47, 165, 255)
local DisabledColor = Color3.fromRGB(150, 150, 150)

local SelectionService = game:GetService("Selection")

local gui = script.GHCloneGui
local mainFrame = gui.Main
local repoUrlBox = mainFrame.RepositoryInput.Input
local subfolderBox = mainFrame.Subfolder.Input
local branchBox = mainFrame.Branch.Input
local setLocationButton = mainFrame.CloneLocation.SetButton
local locationView = mainFrame.CloneLocation.Value
local statusView = mainFrame.Status
local cloneButton = mainFrame.StartClone

local cloneTarget = game.ReplicatedStorage
local requestsEnabled = true
local userRequestsEnabled = true

local function EnableButton(button)
	button.BackgroundColor3 = EnabledColor
	button.AutoButtonColor = true
	button.Active = true
end

local function DisableButton(button)
	button.BackgroundColor3 = DisabledColor
	button.AutoButtonColor = false
	button.Active = false
end

local function UpdateCloneButton()
	if userRequestsEnabled and requestsEnabled then
		EnableButton(cloneButton)
	else
		DisableButton(cloneButton)
	end
end

local function ChangeCloneTarget(newTarget)
	cloneTarget = newTarget
	locationView.Text = newTarget:GetFullName()
end

local GuiController = {}
GuiController.CloneAttempt = cloneButton.MouseButton1Click

function GuiController.SetCloneAttemptsEnabled(enabled)
	userRequestsEnabled = enabled
	UpdateCloneButton()
end

function GuiController.AreCloneAttemptsEnabled()
	return userRequestsEnabled and requestsEnabled
end

function GuiController.SetCloneButtonText(text)
	cloneButton.Text = text
end

function GuiController.SetStatus(statusText)
	local goalSize = NormalSize

	if statusText and statusText:len() > 0 then
		statusView.Text = statusText
		goalSize = ExpandedSize
	end
	
	mainFrame:TweenSize(goalSize, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.2, true)
end

function GuiController.DisableCloneAttempts()
	DisableButton(cloneButton)
end

function GuiController.GetCloneTarget()
	return cloneTarget
end

function GuiController.GetSubfolder()
	return subfolderBox.Text
end

function GuiController.GetBranch()
	return branchBox.Text
end

function GuiController.GetRepositoryInfo()
	local user, repository = repoUrlBox.Text:match("github%.com/([%w-_]+)/([%w-_]+)")
	return {
		Username = user;
		Repository = repository;
		Valid = user ~= nil and repository ~= nil and user:len() > 0 and repository:len() > 0;
	}
end

function GuiController.SetVisible(visible)
	mainFrame.Visible = visible
end

repoUrlBox.Changed:Connect(function(property)
	if property == "Text" then
		requestsEnabled = GuiController.GetRepositoryInfo().Valid
		UpdateCloneButton()
	end
end)

SelectionService.SelectionChanged:Connect(function()
	local items = SelectionService:Get()
	
	if #items ~= 1 then
		DisableButton(setLocationButton)
	else
		EnableButton(setLocationButton)
	end
end)

setLocationButton.MouseButton1Click:Connect(function()
	if setLocationButton.Active then
		ChangeCloneTarget(SelectionService:Get()[1])
	end
end)

repoUrlBox.Text = ""
ChangeCloneTarget(game.ReplicatedStorage)
gui.Parent = game:GetService("CoreGui")

return GuiController