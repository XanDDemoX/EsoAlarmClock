-----------------------------------
--    Alarm Clock Version 0.0.3  --
-----------------------------------

local _prefix ="[Alarm Clock]: "
local _settings = { enabled = true, alarms={} }
local _cmds = {}
local _defaultAlarm = {message="[No Message]", duration=-1, interval=-15, sound=-1, sid="-NONE"}

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

local function stringSplit(pattern,str)
	if str == nil then return {} end
	
	local split ={}
	
	for s in string.gmatch(str,pattern) do
		table.insert(split,s)
	end
	
	return split
end

local function GetSound(id)
	id = string.upper(id)
	if id == "NONE" then
		return id, math.abs(_defaultAlarm.sound)
	end
	return id,SOUNDS[id]
end

local function GetCurrentTime()
	local ticks = GetSecondsSinceMidnight()
	local secs = math.fmod(ticks,60)
	local mins = math.fmod(math.floor(ticks / 60),60)
	local hour = math.floor((ticks / 60) / 60)
	return hour,mins,secs,ticks
end

local function ParseCmd(str,callback)
	local split = stringSplit("%S+",str)
	if callback == nil then return unpack(split) end
	return callback(unpack(split))
end

local function TryParseTime(str)
	if str == nil then return false end
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

local function GetUpdateValue(newValue,current,default,newFormatted)
	return ((newValue == current or newValue == default) and current) or (newFormatted or newValue)
end

local function UpdateAlarm(alarm,arg,default)
	if alarm == nil or arg == nil then return end
	
	for k,v in pairs(alarm) do
		if k == "interval" or k == "duration" then
			alarm[k] = GetUpdateValue(arg[k],v,default[k],math.abs(arg[k]))
		elseif k == "sound" then
			alarm[k] = GetUpdateValue(arg[k],v,default[k],(arg[k] == default[k] and math.abs(arg[k])) )
		elseif k == "sid" then 
			alarm[k] = GetUpdateValue(arg[k],v,default[k],(arg[k] == default[k] and string.sub(arg[k],2,string.len(arg[k])-1) ))
		else
			alarm[k] = GetUpdateValue(arg[k],v,default[k])
		end
		
	end	
	
	alarm.sound = GetUpdateValue(arg.sound,alarm.sound,default[k])
	
	return alarm
end

local function FormatSoundId(id)
	if id ~= _defaultAlarm.sid then return id end
	return string.sub(id,2,string.len(id))
end

local function SetAlarm(strTime,...)
	-- start parse params
	local parsed,hour,mins = TryParseTime(strTime)
	
	if parsed == false then return end
	
	local arg,count = Pack(...)
	
	local defaultMessage,defaultInterval,defaultDurtaion,defaultSound = "[No Message]",15,1,0

	local intStr = arg[count]
	local iparsed,interval = TryParseNumber(intStr,5,60,defaultInterval)
	local dparsed,duration = TryParseNumber(arg[count-1],1,5,defaultDurtaion)
	local sound,sid
	
	if iparsed == true then 
		table.remove(arg) 
	else
		sid,sound = GetSound(arg[count])
		if sound ~= nil then
			table.remove(arg)
		end
	end
	
	if dparsed == true and iparsed == true then 
		table.remove(arg) 
	elseif dparsed == false and iparsed == true then
		duration = Clamp(tonumber(intStr),1,5)
		interval = _defaultAlarm.interval
	elseif sound == nil then
		sid,sound= GetSound(arg[count])
		if sound ~= nil then
			table.remove(arg)
		end
	end
	
	if dparsed == false and iparsed == false then
		duration = _defaultAlarm.duration
		interval = _defaultAlarm.interval
	end
	
	local message = table.concat(arg," ")

	local alarms = _settings.alarms
	local str = GetTimeString(hour,mins)

	if sound == nil then
		sid,sound = GetSound(message)
		if sound ~= nil then
			message = defaultMessage
		end
	end
	
	if stringNilOrEmpty(message) == true or message == sid then
		message = defaultMessage
	end

	if sound == nil then 
		sound,sid = _defaultAlarm.sound,_defaultAlarm.sid
	end
	-- end parse 
	
	--create or update alarm
	local alarm = alarms[str]
	if alarm == nil then 
		alarm = {message = message, duration=math.abs(duration), interval=math.abs(interval),sound=sound,sid=sid}
		alarm = UpdateAlarm(alarm,{message=message, duration=duration, interval=interval, sound=sound,sid=sid},_defaultAlarm)
		alarms[str] = alarm
		d(_prefix.."Alarm set ["..str.."] "..alarm.message.." ["..FormatSoundId(alarm.sid).."] for "..tostring(alarm.duration).." minute(s) every "..tostring(alarm.interval).." seconds")
	else
		alarms[str] = UpdateAlarm(alarm,{message=message, duration=duration, interval=interval, sound=sound,sid=sid},_defaultAlarm)
		d(_prefix.."Alarm updated ["..str.."] "..alarm.message.." ["..FormatSoundId(alarm.sid).."] for "..tostring(alarm.duration).." minute(s) every "..tostring(alarm.interval).." seconds")
	end

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

local function ShowAlert(sound,...)
	if sound == nil then return end
	
	local arg,count = Pack(...)
	
	if count < 1 then return end 
	
	local nsnd = tonumber(sound)
	
	if nsnd == nil then 
		local sid,snd = GetSound(sound)
		
		if snd == nil then 
			table.insert(arg,1,sound)
			snd = _defaultAlarm.sound
		end
	end
	
	if snd == _defaultAlarm.sound then
		snd = 0
	end
	
	local msg = table.concat(arg," ")
	
	CENTER_SCREEN_ANNOUNCE:AddMessage(999,CSA_EVENT_LARGE_TEXT,snd,msg)
	
	ZO_Alert(UI_ALERT_CATEGORY_ALERT,snd,msg)
	
	d(_prefix..msg)
end

local function SetTimeouts(func,interval,duration)
	local v = interval
	repeat 
		zo_callLater(func,v)
		v = v + interval
	until v > duration
end

local function TriggerAlarm(strTime,alarm)
	if alarm ~= nil then
		
		ClearAlarm(strTime,true)
		
		local msg ="["..strTime.."] "..alarm.message
		
		local func = function() ShowAlert(alarm.sid,msg) end

		SetTimeouts(func, alarm.interval * 1000, alarm.duration * 60000)
		
		func()
		
	end
end

local lastTicks = nil  
local function CheckTime()

	if _settings.enabled == false then return end
	
	local ticks = GetSecondsSinceMidnight()
	
	if lastTicks == ticks then return end
	
	local hour, mins, secs,ticks = GetCurrentTime()

	local alarm = TryGetAlarm(hour,mins)
	
	if alarm ~= nil then
		local strTime = GetTimeString(hour,mins)
		TriggerAlarm(strTime,alarm)
	end

end

local function HandleSound(strTime,id)

	local parsed,hour,mins = TryParseTime(strTime)
	
	if parsed == true then
		if id == nil then return end 
		
		local alarm = TryGetAlarm(hour,mins)
		if alarm == nil then return end
		local sid
		sid,id = GetSound(id)
		if id == nil then return end 
		alarm.sound = id
		d(_prefix.."Alarm sound set ["..strTime.."] "..alarm.message.." ["..sid.."]")
		return
	else
		id = strTime
	end

	if stringNilOrEmpty(id) == false then
		local strId = string.upper(id)
		id = SOUNDS[string.upper(strId)]
		if id == nil then return end
		PlaySound(id)
		d(_prefix.."Playing sound "..strId)
	else
		local keys = _soundKeys
		if keys == nil then 
			keys = {}
			for k,v in pairs(SOUNDS) do
				table.insert(keys,k)
			end
			table.sort(keys)
			_soundKeys = keys
		end
		d("[Sounds]")
		for i,v in ipairs(keys) do
			d(v)
		end
	end
end

local function Initialise()

	local _soundKeys

	_cmds["set"] = SetAlarm
	_cmds["clear"] = ClearAlarm
	_cmds["alert"] = ShowAlert
	_cmds["sound"] = HandleSound
	
	
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