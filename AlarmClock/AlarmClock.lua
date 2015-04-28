-----------------------------------
--    Alarm Clock Version 0.0.1  --
-----------------------------------

local _prefix ="[Alarm Clock]: "
local _settings = { enabled = true, alarms={} }
local _cmds = {}

local function isOnString(str)
	str = string.lower(str)
	return str == "+" or str == "on"
end

local function isOffString(str)
	str = string.lower(str)
	return str == "-" or str == "off"
end

local function stringNilOrEmpty(str)
	return str == nil or str == ""
end

local function stringSplit(str,pattern)
	local split ={}
	
	for s in string.gmatch(str,pattern) do
		table.insert(split,s)
	end
	
	return split
end

local function GetCurrentTime()
	local ticks = GetSecondsSinceMidnight()
	local secs = math.fmod(ticks,60)
	local mins = math.fmod(math.floor(ticks / 60),60)
	local hour = math.floor((ticks / 60) / 60)
	return hour,mins,secs,ticks
end

local function ParseCmd(str,callback)
	local split = stringSplit(str,"%S+")
	if callback == nil then return unpack(split) end
	return callback(unpack(split))
end

local function TryParseTime(str)
	local hour,mins = string.match(str,"(%d+):(%d+)")
	if hour == nil or mins == nil then return false end 
	hour = tonumber(hour)
	mins = tonumber(mins)
	if hour < 0 or hour > 23 or mins < 0 or mins > 59 then return false end
	return true,hour,mins 
end

local function GetTimeString(hour,mins)
	return ((hour < 10 and "0") or "")..tostring(hour)..":"..((mins < 10 and "0") or "")..tostring(mins)
end

local function Clamp(num,minValue,maxValue)
	return math.min(math.max(num,minValue),maxValue)
end

local function TryParseNumber(str,minValue,maxValue,defaultValue)
	local num = tonumber(str)
	local parsed = num ~= nil 
	num = num or defaultValue or minValue
	num = Clamp(num,minValue,maxValue)
	return parsed, num
end

local function Pack(...)
	local count = select('#',...)
	local tbl = {}
	local value
	for i=1, count do
		value = select(i,...)
		table.insert(tbl,value)
	end
	
	return tbl,count
end

local function SetAlarm(strTime,...)

	local parsed,hour,mins = TryParseTime(strTime)
	
	if parsed == false then return end
	
	local arg,count = Pack(...)

	local iparsed,interval = TryParseNumber(arg[count],1,60,15)
	local dparsed,duration = TryParseNumber(arg[count-1],1,5)
	
	if iparsed == true then table.remove(arg) end
	if dparsed == true then 
		table.remove(arg) 
	elseif iparsed == true then
		duration = Clamp(interval,1,5)
		interval = 15
	end
	
	local message = table.concat(arg," ")
	
	local alarms = _settings.alarms
	local str = GetTimeString(hour,mins)

	if stringNilOrEmpty(message) == true then
		message = "[No Message]"
	end
	
	alarms[str] = {message=message, duration=duration, interval=interval}
	
	d(_prefix.."Alarm set ["..str.."] "..message.." for "..tostring(duration).." minute(s) every "..tostring(interval).." seconds")
end

local function ClearAlarm(strTime,silent)

	if stringNilOrEmpty(strTime) == true then 
		_settings.alarms = {}
		d(_prefix.."Alarms cleared")
		return 
	end

	local parsed,hour,mins = TryParseTime(strTime)
	
	if parsed == false then return end
	local alarms = _settings.alarms
	
	local str = GetTimeString(hour,mins)
	local alarm = alarms[str]
	if alarm ~= nil then 
		alarms[str] = nil
		if (silent or false) == false then
			d(_prefix.."Alarm cleared ["..str.."] "..alarm.message)
		end
	end

end

local function TryGetAlarm(hour,mins)
	local alarms = _settings.alarms
	local str = GetTimeString(hour,mins)
	local alarm = alarms[str]
	return alarm
end

local function ShowAlert(message,sound)
	if message == nil then return end 
	sound = tonumber(sound) or 0
	ZO_Alert(UI_ALERT_CATEGORY_ALERT,sound,message)
end

local function SetTimeouts(func,interval,duration)
	local v = interval
	repeat 
		zo_callLater(func,v)
		v = v + interval
	until v >= duration
end

local lastTicks = nil  
local function CheckTime()

	local ticks = GetSecondsSinceMidnight()
	
	if lastTicks == ticks then return end
	
	local hour, mins, secs,ticks = GetCurrentTime()

	local alarm = TryGetAlarm(hour,mins)
	
	if alarm ~= nil then
		local strTime = GetTimeString(hour,mins)
		
		ClearAlarm(strTime,true)
		
		local msg ="["..strTime.."] "..alarm.message
		
		local func = function()
			ShowAlert(msg)
			d(_prefix..msg)
		end

		SetTimeouts(func, alarm.interval * 1000, alarm.duration * 60000)
		
		func()
		
	end

end

local function Initialise()

	_cmds["set"] = SetAlarm
	_cmds["clear"] = ClearAlarm
	_cmds["alert"] = ShowAlert
	
	SLASH_COMMANDS["/alarm"] = function(arg)
		
		if isOnString(arg) then
			_settings.enabled = true
			d(_prefix.."Enabled")
		elseif isOffString(arg) then
			_settings.enabled = false
			d(_prefix.."Disabled")
		elseif stringNilOrEmpty(arg) == false then
		
			ParseCmd(arg,function(cmd,...)			
				if cmd ~= nil then
					local command = _cmds[string.lower(cmd)]
					if command ~= nil then
						command(...)
					end
				end
			
			end)			
		end
	end
	
	-- attach for update
	local container = COMPASS.container
	
	local handler = container:GetHandler("OnUpdate")
	
	local lastValue = nil
	
	container:SetHandler("OnUpdate",function(...)
		handler(...)
		CheckTime()
	end)
	
	local _ZO_WorldMapCorner_OnUpdate = ZO_WorldMapCorner_OnUpdate
	
	ZO_WorldMapCorner_OnUpdate = function(self, time)
		_ZO_WorldMapCorner_OnUpdate(self,time)
		CheckTime()
	end

end

local function AlarmClock_Loaded(eventCode, addOnName)

	if(addOnName ~= "AlarmClock") then
        return
    end
	
	_settings = ZO_SavedVars:New("AlarmClock_SavedVariables", "1", "", _settings, nil)
	
	Initialise()
	
end

EVENT_MANAGER:RegisterForEvent("AlarmClock_Loaded", EVENT_ADD_ON_LOADED, AlarmClock_Loaded)