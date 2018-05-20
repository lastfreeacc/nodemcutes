local shttps = {}

local HTTP_BODY_SEP = "\r\n\r\n"
local HTTP_HEADER_SEP = "\r\n"
local HTTP_VERSION = "HTTP/1.1"

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

local HttpRequest = {}
function HttpRequest:new(req) 
    local instance = {}
    req = req or ""
    local rl, h, body = getHttpReqParts(req)
    local method, url, version = parseRequestLine(rl)
    local headers = getHeaders(h)
    
    function instance:method()
        return method
    end

    function instance:url()
        return url
    end

    function instance:version()
        return version
    end

    function instance:headers()
        return headers
    end

    function instance:body()
        return body
    end
    
    return instance
end

local httpStatuses = {
    [200] = "OK",
    [400] = "Bad Request",
    [500] = "Internal Server Error"
}

local function buildResponseStatusLine(status)
    status = status or 200
    local statusText = httpStatuses[status] or "Not Implemented"
    return HTTP_VERSION .. " " .. status .. " " .. statusText .. HTTP_HEADER_SEP
end

local function buildHeaderline(k,v)
    k = k or "Nil Header"
    v = v or ""
    return k .. ": " .. v
end

local function buildResponseHeaders(hs)
    if hs == nil then
        return ""
    end
    local h = ""
    for k,v in pairs(hs) do
        if k ~= nil then
            hl = buildHeaderline(k, v)
            h = h .. hl .. HTTP_HEADER_SEP
        end
    end
    return h
end

local function buildResponse(resp)
    resp = resp or {}
    if resp.body ~= nil then
        body = tostring(body)
        resp.headers["Content-Length"] = string.len(body)
    end
    resp.headers["Server"] = "Simple http server for nodemcu (LUA)"
    resp.headers["Connection"] = "Closed"
    local r = ""
    r = r .. buildResponseStatusLine(resp.status)
    r = r .. buildResponseHeaders(resp.headers)
    r = r .. HTTP_HEADER_SEP
    if resp.body ~= nil then
        r = r .. resp.body
    end
    return r
end

local HttpResponse = {}
function HttpResponse:new() 
    local instance = {}
    local status = 200
    local headers = {}
    local body = ""
    
    function instance:status()
        return status
    end
    function setStatus(code)
        code = tonumber(code) or 200
        status = code
    end

    function instance:headers()
        return headers
    end
    function instance:setHeader(n, v)
        if n == nil then
            return
        end
        v = v or ""
        headers[n] = v
    end

    function instance:body()
        return body
    end
    function instance:setBody(b)
        body = b or ""
    end

    function instance:build()
        headers["Server"] = "Simple http server for nodemcu (LUA)"
        if body ~= nil then
            headers["Content-Length"] = string.len(body)
        end
        headers["Connection"] = "Closed"
        local r = ""
        r = r .. buildResponseStatusLine(status)
        r = r .. buildResponseHeaders(headers)
        r = r .. HTTP_HEADER_SEP
        if body ~= nil then
            r = r .. body
        end
        return r
    end

    return instance
end 

local function send(resp)
    local respText = buildResponse(resp)
end

local function onSent(sck, data)
    print("[INFO] onSent start")
    sck:close()
    print("[INFO] onSent finish")
end

shttps.start = function(processDataCb, port, connTimeOut) --  processDataCb(fn(req, resp)), port(int),connTimeOut(int)
    port = port or 80
    connTimeOut = connTimeOut or 30
    print("[INFO] https starts...")
    print(string.format( "[INFO] port = %s, connTimeOut = %s" , tostring(port), tostring(connTimeOut)))
    local sv = assert(net.createServer(net.TCP, connTimeOut))
    print("[INFO] tcp listener crated")
    sv:listen(port, function(conn)
        print("[INFO] start listening...")
        conn:on("receive", function(sck, data)
            print("[INFO] onReceive start")
            print("[INFO] receive data is:")
            print(data)
            print('[INFO] --- data ends')
            local req = HttpRequest:new(data)
            local resp = HttpResponse:new()
            processDataCb(req, resp)
            local respData = resp:build()
            print("[INFO] sent data is:")
            print(respData)
            print("[INFO] --- respData ends")
            sck:send(respData)
            print("[INFO] onReceive finish")
        end)
        conn:on("sent", onSent)
        print("[INFO] finish listening...")
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
    local data = "POST /cgi-bin/process.cgi HTTP/1.1\r\n"
    print(data)
    local r = HttpRequest:new(data)
    print(r.url(), r.method(), r.version(), r.headers(), r.body())
end

return shttps
