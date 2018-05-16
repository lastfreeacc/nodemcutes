shttps = {}

local HTTP_SEP = "\r\n\r\n"
---local HTTP_SEP = "qwe"

local function ltrim(s)
    return s:gsub("^%s+", "")
end



local function getHandB(req) -- returns (h string, b string)
    if req == nil then
        return nil, nil
    end
    req = ltrim(req)
    i, j = req:find(HTTP_SEP)
    if i == nil then
        return req, nil
    end
    h = req:sub(0,i-1)
    b = req:sub(j+1, req:len())
    return h, b
end





shttps.test = function()
    
    return "test", getHandB()
end

return shttps
