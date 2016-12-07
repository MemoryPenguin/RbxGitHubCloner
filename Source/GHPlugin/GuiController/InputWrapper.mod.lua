local InvalidInputColor = Color3.new(1, 0, 0)
local InvalidInputTransparency = 0.5
local ValidInputColor = Color3.new(0, 0, 0)
local ValidInputTransparency = 0.8
local EnabledButtonColor = Color3.fromRGB(47, 165, 255)
local DisabledButtonColor = Color3.fromRGB(150, 150, 150)

local SelectionService = game:GetService("Selection")

local InputWrapper = {}

function InputWrapper.WrapTextual(inputObject, verifier)
	local box = inputObject.Input
	local errorReason = inputObject.ErrorReason
	local returnState = {
		Valid = true;
		Value = box.Text;
	}
	
	local function Update()
		local valid, reason = verifier(box.Text)
		local color = valid and ValidInputColor or InvalidInputColor
		local transparency = valid and ValidInputTransparency or InvalidInputTransparency
		
		box.BorderColor3 = color
		box.Shadow.BackgroundColor3 = color
		box.BackgroundTransparency = transparency
		box.Shadow.BackgroundTransparency = transparency
		errorReason.Visible = not valid
		
		if not valid then
			errorReason.Text = reason
		end
		
		returnState.Valid = valid
		returnState.Value = box.Text
	end
	
	box.FocusLost:Connect(Update)
	
	function returnState.SetValue(value)
		box.Text = value
		Update()
	end
	
	return returnState
end

function InputWrapper.WrapEnumerated(inputObject, values, startingIndex)
	local downButton = inputObject.Down
	local upButton = inputObject.Up
	local valueDisplay = inputObject.Value
	local index = startingIndex
	
	local returnState = {
		Value = values[startingIndex];
	}
	
	local function Update()
		valueDisplay.Text = values[index]
		returnState.Value = values[index]
	end
	
	-- Simple functor.
	local function ButtonConnector(increment)
		return function()
			index = index + increment
			
			-- Wrap around if we've overshot the array.
			if index < 1 then
				index = #values
			elseif index > #values then
				index = 1
			end
			
			Update()
		end
	end
	
	-- Update once to set the GUI into a known state.
	Update()
	downButton.MouseButton1Click:Connect(ButtonConnector(-1))
	upButton.MouseButton1Click:Connect(ButtonConnector(1))
	
	return returnState
end

function InputWrapper.WrapCloneLocation(inputObject, defaultObject)
	local setButton = inputObject.SetButton
	local valueDisplay = inputObject.Value
	
	local returnState = {
		Value = defaultObject;
	}
	
	local function ChangeSelection(object)
		valueDisplay.Text = object:GetFullName()
		returnState.Value = object
	end
	
	-- Not declared as an anonymous function to allow initializing the GUI
	local function UpdateButton()
		local valid = #SelectionService:Get() == 1
		setButton.Active = valid
		setButton.AutoButtonColor = valid
		setButton.BackgroundColor3 = valid and EnabledButtonColor or DisabledButtonColor
	end
	
	SelectionService.SelectionChanged:Connect(UpdateButton)
	setButton.MouseButton1Click:Connect(function()
		-- Active doesn't stop input events.
		if setButton.Active and #SelectionService:Get() == 1 then
			ChangeSelection(SelectionService:Get()[1])
		end
	end)
	
	ChangeSelection(defaultObject)
	UpdateButton()
	
	return returnState
end

return InputWrapper