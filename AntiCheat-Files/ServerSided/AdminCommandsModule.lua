-- PLACE THIS INSIDE REPLICATED STORAGE TO ENSURE 100% WORKAGE!
--[[ 
    Project: Armed-Vortex; 
    Developers: StyxDeveloper; 
    Contributors: nil; 
    Description: Admin Commands for owners with StyxInterpreter; (This is now based on a different handler) 
    Version: v1.2.0; 
    Update Date: 10/31/2025; 
]]

local Admin = {};
local Commands = {};
local RS = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local DSS = game:GetService("DataStoreService");
local iHM = require(RS:WaitForChild("InfoHolderModule"));
local Prefix = ";";

local function sim(a,b)
	a,b=a:lower(),b:lower();
	local m,n=#a,#b;
	local d={};
	for i=0,m do d[i]={};d[i][0]=i;end;
	for j=0,n do d[0][j]=j;end;
	for i=1,m do for j=1,n do
			local cost=(a:sub(i,i)==b:sub(j,j))and 0 or 1;
			d[i][j]=math.min(d[i-1][j]+1,d[i][j-1]+1,d[i-1][j-1]+cost);
		end;end;
	return 1-d[m][n]/math.max(m,n);
end;

local function findPlayer(txt)
	if not txt or txt=="" then return; end;
	if txt=="me" then return"me";end;
	for _,p in ipairs(Players:GetPlayers())do
		if sim(p.Name,txt)>=0.6 or sim(p.DisplayName,txt)>=0.6 then return p;end;
	end;
end;

local function addCommand(name,aliases,func)
	Commands[name]={func=func;aliases=aliases or{name}};
end;

local function getCommand(cmd)
	for name,data in pairs(Commands)do
		for _,alias in ipairs(data.aliases)do
			if sim(alias,cmd)>=0.7 then return data.func,name;end;
		end;
	end;
end;

local function notify(txt,plrName)
	iHM.sendNotification(txt,plrName);
end;

local function runCommand(plr,cmd,args)
	local func,realName=getCommand(cmd);
	if not func then
		notify("🟡 Command not found; double-check your input: "..cmd,plr.Name);
		iHM.Log("WARN","Unknown command attempt: "..cmd,plr,{msg="Invalid command"});return;
	end;
	iHM.Log("INFO",("Command executed: %s by %s | Args: %s"):format(realName,plr.Name,table.concat(args," ")),plr);
	local suc,err=pcall(func,plr,args);
	if not suc then
		notify("⛔ Oops; error in "..cmd..": "..err,plr.Name);
		iHM.Log("ERROR",("Command '%s' failed: %s"):format(realName,err),plr);
	end;
end;

addCommand("kick",{"kick"},function(plr,args)
	local target=findPlayer(args[1]);
	if target and typeof(target)=="Instance"then
		target:Kick(table.concat(args," ",2)~=""and table.concat(args," ",2)or"Kicked by admin; take care.");
		notify("✅ Player "..target.Name.." kicked; action completed.",plr.Name);
		iHM.Log("WARN","Kick command executed on "..target.Name,plr);
	end;
end);

addCommand("ws",{"ws","walkspeed"},function(plr,args)
	local v=tonumber(args[1])or 16;
	if plr.Character and plr.Character:FindFirstChild("Humanoid")then
		plr.Character.Humanoid.WalkSpeed=v;
		notify("WalkSpeed set to "..v.."; move wisely.",plr.Name);
		iHM.Log("INFO","WalkSpeed set to "..v,plr);
	end;
end);

addCommand("jp",{"jp","jumppower"},function(plr,args)
	local v=tonumber(args[1])or 50;
	if plr.Character and plr.Character:FindFirstChild("Humanoid")then
		plr.Character.Humanoid.JumpPower=v;
		notify("JumpPower set to "..v.."; jump carefully.",plr.Name);
		iHM.Log("INFO","JumpPower set to "..v,plr);
	end;
end);

addCommand("tp",{"tp","goto"},function(plr,args)
	local tgt=findPlayer(args[1]);
	if tgt=="me"then return;end;
	if tgt and plr.Character and tgt.Character then
		plr.Character:PivotTo(tgt.Character:GetPrimaryPartCFrame());
		notify("Teleported to "..tgt.Name.."; hope that’s okay.",plr.Name);
		iHM.Log("INFO","Teleported to "..tgt.Name,plr);
	end;
end);

addCommand("bring",{"bring"},function(plr,args)
	local target=findPlayer(args[1]);
	if target and target.Character and plr.Character then
		target.Character:PivotTo(plr.Character:GetPrimaryPartCFrame());
		notify("Brought "..target.Name.." to you; handle responsibly.",plr.Name);
		iHM.Log("INFO","Brought "..target.Name.." to self",plr);
	end;
end);

addCommand("kill",{"kill","k"},function(plr,args)
	if args[1]=="all"then
		for _,p in ipairs(Players:GetPlayers())do if p.Character then p.Character:BreakJoints();end;end;
		notify("⚠️ All players killed; proceed with caution.",plr.Name);
		iHM.Log("WARN","Mass kill executed by "..plr.Name,plr);
	else
		local tgt=findPlayer(args[1]);
		if tgt and tgt.Character then tgt.Character:BreakJoints(); notify("Killed "..tgt.Name.."; noted.",plr.Name); iHM.Log("WARN","Killed "..tgt.Name,plr);end;
	end;
end);

addCommand("say",{"say"},function(plr,args)
	local txt=table.concat(args," ");
	notify(txt,plr.Name);
	iHM.Log("INFO","Executed say: "..txt,plr);
end);

function Admin.init(plr)
	plr.Chatted:Connect(function(msg)
		if msg:sub(1,#Prefix)~=Prefix then return;end;
		local cmd,rest=msg:match("^"..Prefix.."(%S+)%s*(.*)$");
		if not cmd then return;end;
		local args={};for w in rest:gmatch("%S+")do table.insert(args,w);end;
		runCommand(plr,cmd:lower(),args);
	end);
end;

return Admin;
