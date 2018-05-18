local sapi = {}

local CDM_MODE = "mode"
local CMD_READ = "read"
local CMD_WRITE = "write"
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
        print(string.format("[WARNING] nil data: pin = %s; val = %s", tostring(pin), tostring(val)))
        return -1
    end
    local ok, e = pcall(gpio.mode, pin, val)
    if not ok then 
        print(string.format("[WARNING] can not set gpio.mode: pin = %s, mode = %s", tostring(pin), tostring(val)))
        print(e)
        return -1
    end
    print(string.format("[INFO] successfully set gpio.mode: pin = %s, mode = %s", tostring(pin), tostring(val)))
    return nil
end

local function writeCmd(pin, val)
    pin = tonumber(pin)
    val = tonumber(val)
    if (pin == nil) or (val == nil) then
        print(string.format("[WARNING] nil data: pin = %s; val = %s", tostring(pin), tostring(val)))
        return -1
    end
    local ok, e = pcall(gpio.write, pin, val)
    if not ok then 
        print(string.format("[WARNING] can not set gpio: pin = %s, level = %s", tostring(pin), tostring(val)))
        print(e)
        return -1
    end
    print(string.format("[INFO] successfully set gpio: pin = %s, level = %s", tostring(pin), tostring(val)))
    return nil
end

local function readCmd(pin)
    pin = tonumber(pin)
    if pin == nil then
        print(string.format("[WARNING] nil data: pin = %s", tostring(pin)))
        return -1
    end
    local ok, data = pcall(gpio.read, pin)
    if not ok then 
        print(string.format("[WARNING] can not get gpio: pin = %s", tostring(pin)))
        print(data)
        return -1
    end
    print(string.format("[INFO] successfully read gpio: pin = %s, val = %s", tostring(pin)))
    return data
end
    
sapi.doUrl = function(url)
    cmd, pin, val = parseUrl(url)
    local res = -1
    if cmd == CDM_MODE then
        res = modeCmd(pin, val)
    elseif cmd == CMD_WRITE then
        res = writeCmd(pin, val)
    elseif cmd == CMD_READ then
        res = readCmd(pin)
    else
        print(string.format("[WARNING] unexpected cmd: %s", tostring(cmd)))
    end
end

return sapi
