local jrpc = {}
if sjson == nil then
    local msg = "sjson module required"
    print("[WARNING] " .. msg)
    error(msg,2) 
end

local JRPC_VERSION = "2.0"

-- TODO: move to conf file
local ms = {}
ms["gpio.mode"] = gpio.mode
ms["gpio.read"] = gpio.read
ms["gpio.write"] = gpio.write
ms["node.info"] = node.info
ms["node.input"] = node.input
-- TODO: add more methods
local function buildRpcErr(code, msg, data)
    local code = code or -32603
    local msg = msg or "Internal error"
    local err = {}
    err.code = code
    err.message = msg
    err.data = data
    return err
end
-- local parseError = buildRpcErr(-32700, "Parse error")
-- local invalidRequest = buildRpcErr(-32600, "Invalid Request")
-- local methodNotFound = buildRpcErr(-32601, "Method not found")
-- local invalidParams = buildRpcErr(-32602, "Invalid params")
-- local internalError = buildRpcErr(-32603, "Internal error")

local function isNull(obj)
    return obj == nil or obj == sjson.NULL
end

local function toTable(jsonStr) -- returns lua table which represents incoming json, or nil if parse error
    if jsonStr == nil then
        print("[WARNING] json is nil")
        return nil
    end
    local ok, dataOrErr = pcall(sjson.decode, jsonStr)
    if not ok then
        print("[WARNING] can not parse jsonStr: " .. tostring(jsonStr))
        print("[WARNING] nested error is: " .. tostring(dataOrErr))
        return nil
    end
    return dataOrErr
end

local function toJson(resp) 
    if resp == nil then
        print("[WARNING] resp is nil")
        return ""
    end
    local ok, dataOrErr = pcall(sjson.encode, resp)
    if not ok then
        print("[WARNING] can not encode table to json")
        print("[WARNING] nested error is: " .. tostring(dataOrErr))
        return ""
    end
    return dataOrErr
end

local function checkReq(req)
    if req == nil then
        return false, buildRpcErr(-32603, "Internal error")
    end
    if req.jsonrpc == nil then
        return false, buildRpcErr(-32600, "Invalid Request", "Omited jsonrpc field")
    end
    if req.jsonrpc ~= JRPC_VERSION then
        return false, buildRpcErr(-32600, "Invalid Request", "Not supported version(have:" .. tostring(req.jsonrpc) .. ", want:" .. JRPC_VERSION .. ")")
    end
    if req.method == nil then
        return false, buildRpcErr(-32600, "Invalid Request", "Omited method field")
    end
    if type(req.method) ~= "string" then
        return false, buildRpcErr(-32600, "Invalid Request", "Method must be string")
    end
    if (not isNull(req.params)) and (type(req.params) ~= "table") then
        return false, buildRpcErr(-32602, "Invalid params", "Params must be Array or Object")
    end
    return true
end
-- {"jsonrpc": "2.0", "result": 19, "id": 3}
local function buildOkResp(req, data)
    res = {}
    local id
    if req == nil then
        print("[WARNING] req is nil")
        id = sjson.NULL
    elseif req.id == nil then
        print("[WARNING] req.id is nil")
        id = sjson.NULL
    else 
        id = req.id
    end
    res.id = id
    res.jsonrpc = JRPC_VERSION
    res.result = data
    return res
end

-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
local function buildErrResp(req, err)
    res = {}
    local id
    if req == nil then
        print("[WARNING] req is nil")
        id = sjson.NULL
    elseif req.id == nil then
        print("[WARNING] req.id is nil")
        id = sjson.NULL
    else 
        id = req.id
    end
    res.id = id
    res.jsonrpc = JRPC_VERSION
    res.error = err
    return res
end

-- TODO: need to separate methods with array of params and object params
local function callFn(req)
    ok, err = checkReq(req)
    if not ok then
        return false, err
    end
    -- TODO get methods from config
    local fn = ms[req.method]
    if fn == nil then 
        msg = "unknown method: " .. tostring(req.method)
        print("[WARNING] " .. msg)
        return false, buildRpcErr(-32601, "Method not found" , msg )
    end
    local w
    if isNull(req.params) then
        w = {pcall(fn)}
    elseif req.params[1] ~= nil then
        w = {pcall(fn, unpack(req.params))}
    elseif type(req.params) == "table" then
        w = {pcall(fn, req.params)}
    else
        return false, buildRpcErr(-32602, "Invalid params", "Unexcepted params")
    end
    if not w[1] then
        print("[WARNING] rpc call failed: " .. tostring(w[2]))
        return false, buildRpcErr(-32603, "Internal error", tostring(w[2]))
    end
    table.remove(w, 1)
    return true, w
end

local function invoke(json)
    local req = toTable(json)
    ok, data = callFn(req)
    local res
    if ok then
        res = buildOkResp(req, data)
    else 
        res = buildErrResp(req, data)
    end
    return toJson(res)
end

jrpc.serve = function(req, resp)
    local json = req:body()
    local res = invoke(json)
    resp:setHeader("Content-Type", "application/json")
    resp:setStatus(200)
    resp:setBody(res)
end

return jrpc
