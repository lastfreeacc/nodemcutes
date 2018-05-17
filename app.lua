-- app module
M = {}

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

--local function waitWifiOk()
--    for i = 0, 10 do
--        status = wifi.sta.status()
--        if status == wifi.STA_WRONGPWD then 
--            print("[ERROR] checkWifiStatus - STA_WRONGPWD")
--            return -1
--        elseif status == wifi.STA_APNOTFOUND then
--            print("[ERROR] checkWifiStatus - STA_APNOTFOUND")
--            return -1
--        elseif status == wifi.STA_FAIL then
--            print("[ERROR] checkWifiStatus - STA_FAIL")
--            return -1
--        elseif status == wifi.STA_CONNECTING then
--            print("[INFO] checkWifiStatus - STA_CONNECTING")
--        elseif status == wifi.STA_GOTIP then
--            print("[INFO] checkWifiStatus - STA_GOTIP")
--        elseif status == wifi.STA_IDLE then
--            print("[INFO] checkWifiStatus - STA_IDLE")
--            return 0
--        else
--            print("[ERROR] checkWifiStatus - uncknown(" .. status .. ")")
--            return -1
--        end
--        print(wifi.sta.getip())
--        tmr.delay(1000000)
--    end
--    print("[ERROR] too long wait wifi connection...")
--    return -1
--end
local function receiver(sck, data)
  print("[INFO] receive some data")
  state = gpio.read(0)
  if state == gpio.HIGH then
    gpio.write(0, gpio.LOW)
  else 
    gpio.write(0, gpio.HIGH)
  end
  sck:close()
end

local function listenCmd()
    sv = net.createServer(net.TCP, 30)
    if sv then
      sv:listen(80, function(conn)
        conn:on("receive", receiver)
      end)
    end
end

local function printReq(req)
    print("[INFO] get req")
    print(req.method)
    print(req.url)
    print(req.version)
    for k, v in pairs(req.headers) do
        print(k, v)
    end
    print(req.body)
    sapi = require("sapi")
    sapi.doUrl(req.url)
end

local function gotIpCb()
    print("[INFO] ip obtained")
    print(wifi.sta.getip())
    shttps = require("shttps")
    shttps.start(printReq, 80)
    print("[INFO] server starts")
end



local function connentWifi(cfg)
    c = {}
    c.ssid = cfg.wifi.ssid
    c.pwd = cfg.wifi.pwd
    c.save = false
    c.got_ip_cb = gotIpCb
    wifi.sta.config(c)
    wifi.sta.connect()
end

function M.start() 
    print("[INFO] app start")
    --
    LED_PIN = 0
    gpio.mode(LED_PIN, gpio.OUTPUT)
    --
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
return M
