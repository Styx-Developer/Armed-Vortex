-- PLACE THIS INSIDE REPLICATED STORAGE TO ENSURE 100% WORKAGE!
-- Set your webhook below!

-- Half of this is made to be edited for others, not just us (StyxDeveloper, Jermiah)
--[[
    Project: Armed-Vortex;
    Developers: StyxDeveloper, Jeremiah;
    Contributors: nil;
    Description: InfoHandlerModule;
    Version: v1.1.3;
    Update Date: 5/13/2025;
    	Added support for bad animations;
]]

local aVM = {};

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");
local HttpService = game:GetService("HttpService");

aVM.avCon = {
	DEBUGINFO = { dM = false; dOO = false; };
	MECHANICS = { STRIKES = { sT = 3; bS = { firstBan = 3; secondBan = 7; thirdBan = -1; }; }; SYSTEM = { kS = true; bS = false; wH = ""; }; };
	OWNERCONFIGS = {
		["Jupiter_Development"] = { LEVEL = 1; ADMIN = true; };
	};
	PLAYERS = {};
};

local webhookUrl; pcall(function() webhookUrl = require(ServerScriptService:WaitForChild("LOL")); end); -- WEBHOOK!

aVM.Logs = {};
aVM.Settings = { PrintToOutput = false; SendWebhook = true; };

local function getTimeStr()
	local t = os.date("*t");
	return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec);
end;

function aVM.sendDiscordEmbed(player, logType, details)
	if not webhookUrl or webhookUrl == "" then return end;
	local colors = { Info = 5814783; Warn = 16744192; Error = 16711680; Success = 65280; };
	local embedColor = colors[logType] or 5814783;

	local fields = {
		{ name = "👤 Player"; value = string.format("**%s** (@%s)", player.Name, player.DisplayName); inline = true; };
		{ name = "🆔 User ID"; value = tostring(player.UserId); inline = true; };
		{ name = "📅 Account Age"; value = string.format("%d days", player.AccountAge); inline = true; };
	};

	if details then
		if details.speed then table.insert(fields, { name = "⚡ Speed Detected"; value = string.format("%.1f studs/s", details.speed); inline = true; }); end;
		if details.height then table.insert(fields, { name = "📈 Jump Height"; value = string.format("%.1f studs", details.height); inline = true; }); end;
		if details.animationId then table.insert(fields, { name = "🎬 Animation ID"; value = details.animationId; inline = false; }); end;
		if details.position then
			table.insert(fields, { name = "📍 Position"; value = string.format("X: %.1f, Y: %.1f, Z: %.1f", details.position.X, details.position.Y, details.position.Z); inline = false; });
		end;
	end;
	local msgText = tostring(details and details.msg or "No message provided")
	local description
	if logType == "Info" then
		description = msgText
	elseif logType == "ADD MONEY" then
		description = string.format("**Admin Command Executed:** %s\n```%s```", logType, msgText)
	else
		description = string.format("**Violation Detected: %s**\n```%s```", logType, msgText)
	end
	local embed = {
		title = (logType == "Info") and "ℹ️ Info" or "🚨 Armed-Vortex AntiCheat";
		description = description;
		color = embedColor;
		fields = fields;
		timestamp = DateTime.now():ToIsoDate();
		footer = { text = "Jupiter Development • Armed-Vortex v1.3.0"; };
	};
	local payload = { embeds = { embed }; };
	pcall(function()
		HttpService:RequestAsync({
			Url = webhookUrl;
			Method = "POST";
			Headers = { ["Content-Type"] = "application/json"; };
			Body = HttpService:JSONEncode(payload);
		});
	end);
end;

function aVM.Log(level, msg, player, details)
	level = (level or "INFO"):upper();
	local icons = { INFO = "🟠"; WARN = "🟡"; ERROR = "🔴"; SUCCESS = "🟢"; DEBUG = "⚪"; };
	local icon = icons[level] or "⚪";
	local formatted = string.format("[%s] %s {%s} %s", icon, level, getTimeStr(), tostring(msg));
	table.insert(aVM.Logs, {
		time = os.time();
		level = level;
		icon = icon;
		message = tostring(msg);
		formatted = formatted;
	});
	task.defer(function()
		if aVM.Settings.SendWebhook and player then
			if level == "WARN" or level == "ERROR" then
				aVM.sendDiscordEmbed(player, level, details or { msg = msg });
			end
		end
	end);
	if aVM.Settings.PrintToOutput then
		pcall(function() print(formatted); end);
	end
end;

function aVM.GetLogs() return aVM.Logs; end;
function aVM.ClearLogs() table.clear(aVM.Logs); aVM.Log("INFO", "Log memory cleared."); end;

function aVM.sendNotification(message: string?, who: string?)
	if not message or message == "" then return end
	local notificationEvent = game:GetService("ReplicatedStorage").Remotes:WaitForChild("NotificationEvent")
	if not notificationEvent then repeat task.wait() until notificationEvent; return end

	if who == nil or who == "all" then
		notificationEvent:FireAllClients(nil, message)
	else
		notificationEvent:FireClient(game:GetService("Players")[who], message)
	end
end

function aVM.checkLevel(user)
	if not user then return "false", false; end;
	local cfg = aVM.avCon.OWNERCONFIGS[user.Name];
	local lvl = cfg and cfg.LEVEL;
	local admin = cfg and cfg.ADMIN or false;
	local status = "false";
	if lvl == 1 then status = "Owner"; aVM.Log("INFO", "Owner detected: "..user.Name, user);
	elseif lvl == 2 then status = "Admin";
	elseif lvl == 3 then status = "Mod"; aVM.Log("INFO", "Mod detected: "..user.Name, user);
	end;
	return status, admin;
end;

function aVM.addStrike(userId, reason)
	local P = aVM.avCon.PLAYERS;
	if not userId then return; end;
	pcall(function()
		if P[userId] and P[userId].TEMPPASS == false then
			P[userId].STRIKES = (P[userId].STRIKES or 0) + 1;
			local pl = Players:GetPlayerByUserId(userId);
			if pl then aVM.sendNotification("Exploit Detected, stop exploiting!", pl.Name); end;
			aVM.Log("WARN", ("Strike added to %s (reason: %s)"):format(userId, reason or "unspecified"), pl);
		end;
	end);
end;

function aVM.Initialize()
	Players.PlayerAdded:Connect(function(user)
		if not user then return; end;
		aVM.avCon.PLAYERS[user.UserId] = aVM.avCon.PLAYERS[user.UserId] or { STRIKES = 0; SERVERBAN = false; TEMPPASS = false; };

		task.spawn(function()
			while Players:FindFirstChild(user.Name) and task.wait(1) do
				local d = aVM.avCon.PLAYERS[user.UserId]; if not d then break; end;
				if d.STRIKES >= (aVM.avCon.MECHANICS.STRIKES.sT or 3) and aVM.avCon.MECHANICS.SYSTEM.kS then
					pcall(function() user:Kick("You have been kicked by the Anti-Cheat."); end);
					aVM.Log("WARN", user.Name.." kicked by anti-cheat (strikes: "..d.STRIKES..")", user);
				end;
			end;
		end);

		task.spawn(function()
			local role, isAdmin = aVM.checkLevel(user);
			if (role == "Owner" or role == "Admin") and isAdmin then
				local mod = ReplicatedStorage:FindFirstChild("AdminCommandsModule");
				if mod then pcall(function() require(mod).init(user); aVM.Log("SUCCESS", "Admin commands initialized for "..user.Name, user); end);
				else aVM.Log("WARN", "AdminCommandsModule not found in ReplicatedStorage", user); end;
			end;
		end);

		aVM.sendNotification("The game is protected by Jupiter Development!", user.Name);
		aVM.Log("INFO", "PlayerAdded handled for "..user.Name, user);
	end);

	Players.PlayerRemoving:Connect(function(p)
		aVM.avCon.PLAYERS[p.UserId] = nil;
		aVM.Log("INFO", "Player removed: "..tostring(p.Name));
	end);

	aVM.Log("SUCCESS", "InfoHolderModule initialized and ready.");
end;

if aVM.avCon.DEBUGINFO.dOO then aVM.Log("WARN", "Anti-Cheat disabled via DEBUGINFO.dOO"); return aVM; end;

return aVM;
