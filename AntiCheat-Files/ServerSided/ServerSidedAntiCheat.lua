-- Place inside ServerScriptService
-- Fully Tested
-- NOT EDITABLE (unless you know what your doing)
--[[
	Project: Armed-Vortex;
	Developers: StyxDeveloper;
	Contributors: nil;
	Description: Serversided anticheat;
	Version: v1.1.5;
	Update Date: 10/31/2025;
	Notes:

]]

local iHM = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("InfoHolderModule"))
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

if iHM.avCon.DEBUGINFO.dOO then
	print("AntiCheat Disabled!")
	return
end

iHM.Initialize()

local vehicleSystem = {
	vehicleSpeed = {},
	playerVehicleState = {},
	DEFAULT_MAX_SPEED = 160,
	SPEED_TOLERANCE = 10,
	SPEED_INTERVAL = 0.2,
	SCALING = (10/12) * (60/88)
}

BAD_ANIMATION_IDS = {
	["rbxassetid://72042024"] = true;
	["rbxassetid://698251653"] = true;
	["rbxassetid://148840371"] = true;
	["rbxassetid://5918726674"] = true;
}

local function unifiedStrike(player, reason, data)
	local userId = player.UserId
	local msg = ("Strike added to %s (reason: %s)"):format(userId, reason or "unspecified")
	iHM.addStrike(userId, reason)
	iHM.Log("INFO", msg, player, data or {})
end

local function monitorVehicle(player, model)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local running = true
	task.spawn(function()
		while running and humanoid and humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(model) do
			task.wait(0.5)
		end
		if running then
			local state = vehicleSystem.playerVehicleState[player]
			if state then
				state.inVehicle = false
				state.model = nil
				state.lastExit = os.clock()
			end
		end
	end)
	return function()
		running = false
	end
end

local function handleSeated(player, active)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local state = vehicleSystem.playerVehicleState[player] or {}
	vehicleSystem.playerVehicleState[player] = state

	if active then
		local seat = humanoid.SeatPart
		if seat then
			local model = seat:FindFirstAncestorOfClass("Model")
			local isVehicle = model and (model:GetAttribute("IsVehicle") == true or model:FindFirstChildWhichIsA("VehicleSeat", true))
			local isDriver = seat:IsA("VehicleSeat") and isVehicle
			local isPassenger = seat:IsA("Seat") and isVehicle

			if isDriver then
				state.inVehicle = true
				state.model = model
				state.lastExit = nil
				if not state.cancel then
					state.cancel = monitorVehicle(player, model)
				end
			elseif isPassenger then
				state.inVehicle = true
				state.model = model
				state.lastExit = nil
			end
		end
	else
		if state.cancel then
			state.cancel()
			state.cancel = nil
		end
		state.inVehicle = false
		state.model = nil
		state.lastExit = os.clock()
	end
end

local function detectSpeedHacks(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart");
	local hum = character:WaitForChild("Humanoid");

	local lastPos = root.Position;
	local lastTime = os.clock();
	local lastVehicleExit = 0;

	local MAX = 35;           -- studs/sec
	local INTERVAL = 1;       -- time

	while player.Parent do
		task.wait(INTERVAL);

		local vehicle = vehicleSystem.playerVehicleState[player];
		if vehicle and vehicle.inVehicle then
			lastPos = root.Position;
			lastTime = os.clock();
			lastVehicleExit = os.clock();
			continue;
		end;

		if os.clock() - lastVehicleExit < 3 or hum.Sit then
			lastPos = root.Position;
			lastTime = os.clock();
			continue;
		end;

		local now = os.clock();
		local dt = now - lastTime;
		if dt <= 0 or dt > 2 then
			lastPos = root.Position;
			lastTime = now;
			continue;
		end;

		local speed = ((root.Position.X - lastPos.X)^2 + (root.Position.Z - lastPos.Z)^2)^0.5 / dt;

		if speed > MAX then
			unifiedStrike(player, ("Speed Hack Detected (%.1f / %.1f)"):format(speed, MAX), {
				speed = speed;
				maxSpeed = MAX;
				position = root.Position;
			});
			task.wait(5);
		end;

		lastPos = root.Position;
		lastTime = now;
	end;
end;

local function detectJumpHacks(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid");
	local root = character:WaitForChild("HumanoidRootPart");
	local lastY = root.Position.Y;
	local lastTime = os.clock();
	local lastVehicleExit = 0;
	local MAX = 19;
	local INTERVAL = 0.3;

	while player.Parent do
		task.wait(INTERVAL);
		if not root.Parent then break end;
		local vehicle = vehicleSystem.playerVehicleState[player];
		if vehicle and vehicle.inVehicle or hum.Sit then
			lastY = root.Position.Y;
			lastTime = os.clock();
			continue;
		end;

		local now = os.clock();
		local dt = now - lastTime;

		if dt <= 0 or dt > 1.2 then
			lastY = root.Position.Y;
			lastTime = now;
			continue;
		end;

		local currentY = root.Position.Y;
		local diff = currentY - lastY;
		if diff > MAX then
			unifiedStrike(
				player,
				("Jump Power Bypass Detected (%.1f / %.1f)"):format(diff, MAX),
				{
					height = diff;
					maxHeight = MAX;
					position = root.Position;
				}
			);
			task.wait(3);
		end;
		lastY = currentY;
		lastTime = now;
	end;
end;

game:GetService("Players").PlayerAdded:Connect(function(player)
	local oS, aD = iHM.checkLevel(player)
	if (oS == "Owner" or oS == "Admin") and aD == true then return end
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		task.spawn(detectSpeedHacks, player, character)
		task.spawn(detectJumpHacks, player, character)
	end)
	iHM.sendNotification("The game is protected by Jupiter Development!", player.Name)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	vehicleSystem.playerVehicleState[player] = nil
end)
