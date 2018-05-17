shttps = {}

local HTTP_BODY_SEP = "\r\n\r\n"
local HTTP_HEADER_SEP = "\r\n"

local function ltrim(s)
    if s == nil then
        return ""
    end
    return s:gsub("^%s+", "")
end

local function getHandB(req) -- returns (h string, b string)
    if req == nil then
        return "", ""
    end
    req = ltrim(req)
    local i, j = req:find(HTTP_BODY_SEP)
    if i == nil then
        return req, ""
    end
    local h = req:sub(0,i-1)
    local b = req:sub(j+1, req:len())
    return h, b
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

local function parseReq(req)
    local h, b = getHandB(req)
    local hs = getHeaders(h)
    return hs, b
end

shttps.start = function(processDataCb, port, connTimeOut) -- port(int), processDataCb(fn(hs, b))
    if port == nil then
        port = 8080
    end
    if connTimeOut == nil then
        connTimeOut = 30
    end
    local sv = assert(net.createServer(net.TCP, connTimeOut))
    sv:listen(port, function(conn)
        conn:on("receive", function(sck,data)
            local hs, b = parseReq(req)
            processDataCb(hs, b)
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
    local req = readAll("httpreq_ex.txt")
    local hs, b = parseReq(req)
    return "test", hs["Host"], b
end

return shttps
