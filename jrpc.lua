local jrpc = {}

local ms = {}
ms["gpio.mode"] = gpio.mode
ms["gpio.read"] = gpio.read
ms["gpio.write"] = gpio.write
ms["node.info"] = node.info
-- TODO: add more methods

local JrpcReq = {}
function JrpcReq:new(version, method, params, id)
    local istance = {}
    local version = version
    local method = method
    local params = params
    local id = id

    function instance:print()
        print("version: " .. tostring(version))
        print("method: " .. tostring(method))
        if params == nil then
            print("params: nil")
        else
            print("params:")
            for k, v in pairs(params) do
                print(string.format("%s:%s", k, v))
            end
        end
        print("id: " .. tostring(id))
    end

    function instance:method()
        return method
    end
    
    function instance:params()
        return params
    end

    function instance:id()
        return id
    end

    return instance
end 

--[[ not needed? 
local JrpcResp = {}
function JrpcResp:new(result, id)]]--

local function getJrpcReq(req) -- returns rps struct, err (if err == nil -> ok)
    if req == nil then
        print("[WARNING] req is nil")
        return nil
    end

    local body = req.body
    local ok, dataOrErr = pcall(sjosn.decode, body)
    if not ok then
        local err = "can not parse body: " .. tostring(body) 
                    .. " nested error is: " .. tostring(dataOrErr)
        print("[WARNING] " .. err)
        return nil, err
    end
    local data = dataOrErr
    -- TODO: may be retrun just table...???
    return JrpcReq:new(data), nil
end

-- TODO: need to separate methods with array of params and object params
local function invoke(req)
    if req == nil then
        print("[WARNING] jrpc req is nil")
        return
    end
    print("[INFO] invoke jrpc req:")
    req:print()
    print("[INFO] ------ jrpc req")
    local method = req:method()
    if method == nil then
        print("[WARNING] method is nil")
        return
    end
    -- TODO: invoke with array of params< may be lua has ...(three dot) operator
    -- or another way to unwrap array
    local fn = ms[method]
    if fn == nil then 
        print("[WARNING] unknown method: " .. tostring(method))
        return
    end
    local ok, dataOrErr = pcall(fn, params)
    if not ok then
        print("[WARNING] error while invoke method: " .. tostring(method)
                .. " with params: " .. tostring(params))
        print("eror is: " .. tostring(dataOrErr))
        return
    end
    return dataOrErr, nil
end





return jrpc