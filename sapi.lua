local sapi = {}

local CDM_MODE = "mode"
local CMD_GET = "get"
local CMD_SET = "set"
-- local ON_VAL = "on"
-- local OFF_VAL = "off"
-- local OUT_VAL = "out"

local function parseUrl(url)
    if url == nil then
        return {}
    end
    parts = {}
    for p in url:gmatch("([^/]+)/?") do
        table.insert(parts, p)
    end
    local cmd = parts[1] or ""
    local pin = parts[2]
    local val = parts[3]
    return cmd, pin, val
end

local function modeCmd(pin, val)
    pin = tonumber(pin)
    val = tonumber(val)
    if (pin == nil) or (val == nil) then
        print(string.format("[WARNING] nil data: pin = %s; val = %s", pin, val))
        return -1
    end
    local ok, e = pcall(gpio.mode, pin, val)
    if not ok then 
        print(string.format("[WARNING] can not set gpio.mode: pin = %s, mode = %s", pin, val))
        print(e)
        return -1
    end
    print(string.format("[INFO] successfully set gpio.mode: pin = %s, mode = %s", pin, val))
    return nil
end

local function setCmd(pin, val)
    pin = tonumber(pin)
    val = tonumber(val)
    if (pin == nil) or (val == nil) then
        print(string.format("[WARNING] nil data: pin = %s; val = %s", pin, val))
        return -1
    end
    local ok, e = pcall(gpio.write, pin, val)
    if not ok then 
        print(string.format("[WARNING] can not set gpio: pin = %s, level = %s", pin, val))
        print(e)
        return -1
    end
    print(string.format("[INFO] successfully set gpio: pin = %s, level = %s", pin, val))
    return nil
end

local function getCmd(pin)
    pin = tonumber(pin)
    if pin == nil then
        print(string.format("[WARNING] nil data: pin = %s", pin, val))
        return -1
    end
    local ok, data = pcall(gpio.read, pin)
    if not ok then 
        print(string.format("[WARNING] can not get gpio: pin = %s", pin))
        print(data)
        return -1
    end
    print(string.format("[INFO] successfully read gpio: pin = %s, val = %s", pin, data))
    return data
end
    
sapi.doUrl = function(url)
    cmd, pin, val = parseUrl(url)
    local res = -1
    if cmd == CDM_MODE then
        res = modeCmd(pin, val)
    elseif cmd == CMD_SET then
        res = setCmd(pin, val)
    elseif cmd == getCmd then
        res = getCmd(pin)
    end
    print(res)
end

return sapi