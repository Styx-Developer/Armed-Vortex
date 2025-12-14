-- Made with the help of ChatGPT, this GUI is entirely hand coded (hence the need for GPT). 
-- THIS IS A LOCAL SCRIPT!
-- StarterGui --> Make a folder and name it "Jupiter" --> This script
-- Replicated Storage --> Make a folder and name it "Remotes" --> Create a remote in that folder called "NotificationEvent"

--[[
    Project: Armed-Vortex;
    Developers: StyxDeveloper;
    Contributors: ChatGPT;
    Description: This GUI is entirely hand coded;
    Version: v1.0.1;
    Update Date: 10/4/25;
    Update Log: Fixed the issue where the GUI would shut too quick!
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage");
local player = game:GetService("Players").LocalPlayer;

local screenGui, frame, titleLabel, messageLabel, closeButton;

local function createGUIElements()
	screenGui = Instance.new("ScreenGui");
	screenGui.Name = "WarningGUI";
	screenGui.Parent = player:WaitForChild("PlayerGui");
	frame = Instance.new("Frame");
	frame.Size = UDim2.new(0.4, 0, 0.2, 0);
	frame.Position = UDim2.new(0.3, 0, 0.4, 0);
	frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	frame.BackgroundTransparency = 0.2;
	frame.BorderSizePixel = 0;
	frame.Parent = screenGui;
	local frameCorner = Instance.new("UICorner");
	frameCorner.CornerRadius = UDim.new(0.05, 0);
	frameCorner.Parent = frame;
	titleLabel = Instance.new("TextLabel");
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0);
	titleLabel.Position = UDim2.new(0, 0, 0, 0);
	titleLabel.BackgroundTransparency = 1;
	titleLabel.Text = "Warning!";
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
	titleLabel.TextScaled = true;
	titleLabel.Font = Enum.Font.SourceSansBold;
	titleLabel.Parent = frame;
	messageLabel = Instance.new("TextLabel");
	messageLabel.Size = UDim2.new(1, -20, 0.5, -20);
	messageLabel.Position = UDim2.new(0, 10, 0.3, 10);
	messageLabel.BackgroundTransparency = 1;
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
	messageLabel.TextScaled = true;
	messageLabel.Font = Enum.Font.SourceSans;
	messageLabel.TextWrapped = true;
	messageLabel.Parent = frame;
	closeButton = Instance.new("TextButton");
	closeButton.Size = UDim2.new(0.3, 0, 0.2, 0);
	closeButton.Position = UDim2.new(0.35, 0, 0.8, 0);
	closeButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	closeButton.Text = "Close";
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255);
	closeButton.TextScaled = true;
	closeButton.Font = Enum.Font.SourceSansBold;
	closeButton.Parent = frame;
	local buttonCorner = Instance.new("UICorner");
	buttonCorner.CornerRadius = UDim.new(0.1, 0);
	buttonCorner.Parent = closeButton;
end;

local function closeGUI()
	if frame then
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local tween = game:GetService("TweenService"):Create(frame, tweenInfo, {BackgroundTransparency = 1});
		tween:Play();
		tween.Completed:Connect(function()
			if screenGui then
				screenGui:Destroy();
				screenGui = nil;
				frame, titleLabel, messageLabel, closeButton = nil, nil, nil, nil;
			end;
		end);
	end;
end;

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NotificationEvent").OnClientEvent:Connect(function(message)
	if player.PlayerGui:FindFirstChild("WarningGUI") then
		return;
	end;
	if not screenGui then
		createGUIElements();
	end;
	messageLabel.Text = message;
	closeButton.MouseButton1Click:Connect(closeGUI);
	task.delay(10, function()
		if screenGui and screenGui.Parent then
			closeGUI();
		end;
	end);
end);
