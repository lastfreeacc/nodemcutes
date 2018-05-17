local shttps = {}

local HTTP_BODY_SEP = "\r\n\r\n"
local HTTP_HEADER_SEP = "\r\n"

local function ltrim(s)
    if s == nil then
        return ""
    end
    return s:gsub("^%s+", "")
end

local function getHttpReqParts(req) -- returns (h string, b string)
    if req == nil then
        return "", ""
    end
    req = ltrim(req)
    local i, j = req:find(HTTP_HEADER_SEP)
    if i == nil then
        return "", "", ""
    end
    local rl = req:sub(0,i-1)
    req = req:sub(j+1,req:len())
    local k, l = req:find(HTTP_BODY_SEP)
    if k == nil then
        return rl, req, ""
    end
    local h = req:sub(0,k-1)
    local b = req:sub(l+1, req:len())
    return rl, h, b
end

local function getRequestLine(h)
    if h == nil then
        return ""
    end
    local i, j = h:find(HTTP_HEADER_SEP)
    if i == nil then
        return ""
    end
    return h:sub(0,i-1)
end

local function parseRequestLine(l)
    if l == nil then
        return "", "", ""
    end
    return l:match("^(%S+)%s+(%S+)%s+(%S+)")
end

local function parseHeader(l)
    if l == nil then
        return "", ""
    end
    local i, j = l:find(":")
    if i == nil then
        return "", ""
    end
    local n = l:sub(0,i-1)
    local v = l:sub(j+1, l:len())
    return n, ltrim(v)
end

local function getHeaders(h)
    local hs = {}
    if h == nil then
        return hs
    end
    for line in h:gmatch("([^\r\n]*)\r\n?") do
        local n, v = parseHeader(line)
        if (n ~= nil) and (n:len() > 0) then
            hs[n] = v
        end
    end
    return hs
end

function buidReqObj(req)
    local reqObj = {}
    req = req or ""
    local rl, h, b = getHttpReqParts(req)
    local m, url, v = parseRequestLine(rl)
    local hs = getHeaders(h)
    reqObj.method = m
    reqObj.url = url
    reqObj.version = v
    reqObj.headers = hs
    reqObj.body = b
    return reqObj
end

shttps.start = function(processDataCb, port, connTimeOut) -- port(int), processDataCb(fn(reqObj))
    port = port or 80
    connTimeOut = connTimeOut or 30
    print("[INFO] https starts...")
    print(string.format( "[INFO] port = %s, connTimeOut = %s" , port, connTimeOut ))
    local sv = assert(net.createServer(net.TCP, connTimeOut))
    print("[INFO] tcp listener crated")
    sv:listen(port, function(conn)
        print("[INFO] listen...")
        conn:on("receive", function(sck,data)
            print("[INFO] tcp listener receive data")
            print("[INFO] receive data is:")
            print(data)
            print('[INFO] --- data ends')
            local reqObj = buidReqObj(data)
            processDataCb(reqObj)
            print("[INFO] tcp listener process data")
            sck:close()
        end)
    end)
end

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end


shttps.test = function()
    print("test")
end
return shttps
