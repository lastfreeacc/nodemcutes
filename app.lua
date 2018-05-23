-- app module
app = {}
sapi = require("sapi")
jrpc = require("jrpc")

local function isEmpty(s)
  return s == nil or s == ''
end

local function loadCfg() 
    print("[INFO] try load config")
    local cfg = require("config")
    if cfg == nil then
        print("[ERROR] cfg is nil")
        print("[ERROR] stop app")
        return nil
    end
    if cfg.wifi == nil then 
        print("[ERROR] cfg.wifi is nil")
        print("[ERROR] cfg.wifi is required")
        return nil
    end
    if isEmpty(cfg.wifi.ssid) or isEmpty(cfg.wifi.pwd) then
        print("[ERROR] cfg.wifi.ssid or cfg.wifi.pwd is empty")
        print("[ERROR] cfg.wifi.ssid or cfg.wifi.pwd required")
        return nil
    end
    print("[INFO] success to load cfg")
    return cfg
end

local function printDevice(cfg)
    if cfg.device == nil then
        print("[WARN] device not found in cfg")
        return
    end
    print("[INFO] device name is: " .. cfg.device.name)
    print("[INFO] device desc is: " .. cfg.device.desc)
    return
end

-- local function printReq(req)
--     print("[INFO] get req")
--     print(req.method())
--     print(req.url())
--     print(req.version())
--     for k, v in pairs(req.headers()) do
--         print(k, v)
--     end
--     print(req.body())
    
--     sapi.doUrl(req.url())
-- end

local function gotIpCb()
    print("[INFO] ip obtained")
    print(wifi.sta.getip())
    shttps = require("shttps")
    shttps.start(jrpc.serve, 80)
    print("[INFO] server starts")
end

local function connentWifi(cfg)
    wifi.setmode(wifi.STATION)
    c = {}
    c.ssid = cfg.wifi.ssid
    c.pwd = cfg.wifi.pwd
    c.save = false
    c.got_ip_cb = gotIpCb
    wifi.sta.config(c)
    wifi.sta.connect()
end

function app.start() 
    print("[INFO] app start")
    cfg = loadCfg()
    if cfg == nil then
        return -1
    end
    printDevice(cfg)
    ip = connentWifi(cfg)
    if ip == nil then
        return -1
    end
    return 0
end
return app
