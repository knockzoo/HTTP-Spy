local uilib = loadstring(game:HttpGet("https://raw.githubusercontent.com/realstufflol/HTTP-Spy/main/ui.lua"))()

local executor, version = identifyexecutor()
local functions = { request, http_request, (http and http.request) or nil }

local band
local bxor
local bnot
local lshift
local rshift1
local rshift
local random = {}

local sub = string.sub
local floor = math.floor

do -- https://gist.github.com/lukespragg/d3d939ec534db920eab8
    local MOD = 2 ^ 32
    local MODM = MOD - 1
    local function memoize(f)
        local mt = {}
        local t = setmetatable({}, mt)
        function mt:__index(k)
            local v = f(k)
            t[k] = v
            return v
        end

        return t
    end
    local function make_bitop_uncached(t, m)
        local function bitop(a, b)
            local res, p = 0, 1
            while a ~= 0 and b ~= 0 do
                local am, bm = a % m, b % m
                res = res + t[am][bm] * p
                a = (a - am) / m
                b = (b - bm) / m
                p = p * m
            end
            res = res + (a + b) * p
            return res
        end
        return bitop
    end
    local function make_bitop(t)
        local op1 = make_bitop_uncached(t, 2 ^ 1)
        local op2 =
            memoize(
                function(a)
                    return memoize(
                        function(b)
                            return op1(a, b)
                        end
                    )
                end
            )
        return make_bitop_uncached(op2, 2 ^ (t.n or 1))
    end

    local bxor1 = make_bitop({ [0] = { [0] = 0, [1] = 1 }, [1] = { [0] = 1, [1] = 0 }, n = 4 })
    bxor = function(a, b, c, ...)
        local z = nil
        if b then
            a = a % MOD
            b = b % MOD
            z = bxor1(a, b)
            if c then
                z = bxor(z, c, ...)
            end
            return z
        elseif a then
            return a % MOD
        else
            return 0
        end
    end

    band = function(a, b, c, ...)
        local z
        if b then
            a = a % MOD
            b = b % MOD
            z = ((a + b) - bxor1(a, b)) / 2
            return z
        elseif a then
            return a % MOD
        else
            return MODM
        end
    end

    bnot = function(x)
        return (-1 - x) % MOD
    end

    rshift1 = function(a, disp)
        if disp < 0 then
            return lshift(a, -disp)
        end
        return floor(a % 2 ^ 32 / 2 ^ disp)
    end

    rshift = function(x, disp)
        if disp > 31 or disp < -31 then
            return 0
        end
        return rshift1(x % MOD, disp)
    end

    lshift = function(a, disp)
        if disp < 0 then
            return rshift(a, -disp)
        end
        return (a * 2 ^ disp) % 2 ^ 32
    end

    local function seedgen()
        return os.clock() + tick() ^ 2
    end

    local original = seedgen

    local rng = function(seed)
        local a = 1103515245
        local c = 12345
        seed = (a * seed + c) % (2 ^ 31)
        local d = seed / (2 ^ 31)

        return function(min, max)
            min = min or 0
            max = max or 1
            if min > max then
                min, max = max, min
            end
            return d * (max - min) + min
        end
    end

    local calls = 0
    local gen = rng(seedgen())
    function random.int(min, max)
        gen = rng(seedgen())
        return floor(gen(min, max))
    end

    function random.string(len)
        local chars = "abcdefghijklmnopqrstuvxwyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local r = ''
        for i = 1, len do
            local n = random.int(1, #chars)
            r = r .. sub(chars, n, n)
        end
        return r
    end

    function random.setseed(seed)
        if seed then
            seedgen = function() return seed end
        else
            seedgen = original
        end
    end
end

local function generatehwid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random.int(0, 15) or random.int(8, 11)
        return string.format('%x', v)
    end):upper()
end

local function generateip() -- couldnt be bothered, thanks chatgpt
    local startipdec = 0
    local endipdec = 4294967295

    local randomipdec = random.int(startipdec, endipdec)

    local a = rshift(band(randomipdec, 0xFF000000), 24)
    local b = rshift(band(randomipdec, 0x00FF0000), 16)
    local c = rshift(band(randomipdec, 0x0000FF00), 8)
    local d = band(randomipdec, 0x000000FF)

    return string.format("%d.%d.%d.%d", a, b, c, d)
end

local fakehwid, fakeip = generatehwid(), generateip()
local actualhwid, actualip = game:GetService("RbxAnalyticsService"):GetClientId(), game:HttpGet("https://api.ipify.org/")

local function sanitize(s)
    s = s:gsub(actualhwid, fakehwid, 1000)
    s = s:gsub(actualip, fakeip, 1000)

    return s
end

local function search(s)
    local news = s
    local lowered = news:lower()
    local flagged = false
    if lowered:match(actualip) or lowered:match(fakeip) then -- ip info
        flagged = true
    end

    if lowered:match(actualhwid) or lowered:match(fakehwid) then -- hwid info
        flagged = true
    end

    if lowered:match("webhook") or lowered:match("ip") or lowered:match("httpbin") then -- logging / extra info
        flagged = true
    end

    return flagged
end

local serializer
do
    local sub = string.sub
    local find = string.find
    local format = string.format
    local gsub = string.gsub
    local dump = string.dump
    local byte = string.byte
    local rep = string.rep
    local concat = table.concat
    local insert = table.insert
    local type = type
    local tostring = tostring
    local pairs = pairs
    local huge = math.huge
    local nhuge = -huge
    
    local newline = '\n'
    local newline2 = '\\n'
    
    local tab = '\t'
    local tab2 = '\\t'
    
    local function mutate(str, q)
        local mutated = {}
        local length = #str
        local i = 0
        while i < length do
            i = i + 1
    
            local c = sub(str, i, i)
            if c == newline then
                c = newline2
            elseif c == tab then
                c = tab2
            else
                if (q == 1 or q == 3) and c == "'" then
                    c = "\\'"
                end
    
                if (q == 2 or q == 3) and c == '"' then
                    c = '\\"'
                end
            end
    
            insert(mutated, c)
        end
    
        return concat(mutated)
    end
    
    local function quotes(str)
        local dq = find(str, '"')
        local sq = find(str, "'")
    
        local c = 0
        if dq then c = c + 2 end
        if sq then c = c + 1 end
    
        return format('"%s"', mutate(str, c))
    end
    
    local function serializedata(data)
        if not data then
            return 'nil'
        end
    
        local typeof = type(data)
    
        if typeof == 'string' then
            return quotes(data)
        elseif typeof == 'boolean' then
            return (data and 'true' or 'false')
        end
    
        local ts = tostring(data)
    
        if typeof == 'number' then
            if data == huge then
                return 'math.huge'
            elseif data == nhuge then
                return '-math.huge'
            end
    
            if settings.PrioritizeCompression then
                local h = format('0x%x', data)
                if #h < #ts then
                    return (h)
                end
            end
        elseif typeof == 'function' then
            if settings.PrioritizeCompression then
                return format('--[[%s]]', ts)
            else
                return format("function(...) return loadstring(\"%s\")(...); end", gsub(dump(data), ".", function(k) return "\\" .. byte(k); end)) -- thanks leopard, very neat
            end
        elseif typeof == 'table' then
            return nil
        end
    
        return (ts)
    end
    
    serializer = function(tbl, level, checked)
        checked = checked or {}
        level = level or 1
    
        if checked[tbl] then
            return 'tbl'
        end
    
        checked[tbl] = true
    
        local result = { '{\n' }
        for i, v in pairs(tbl) do
            local sd = serializedata(v)
            if sd ~= nil then
                insert(result, format('%s[%s] = %s,\n', rep("\t", level), serializedata(i) or '', sd))
            else
                insert(result, format('%s[%s] = %s,\n', rep("\t", level), serializedata(i), serializer(v, level + 1, checked)))
            end
        end
    
        result = concat(result)
        result = format("%s\n%s}", sub(result, 0, #result - 2), rep('\t', level - 1))
        return result
    end
end

local hook = function(args, old)
    local newargs = args

    if getmetatable(newargs) then
        if not pcall(setmetatable(newargs, { __pairs = function(self) return next, self, nil end })) then
            uilib.notif("Error", "The anti HTTP spy used has anti-dump methods preventing secure logging from being possible.")
            return old(newargs)
        end
    end

    newargs.Method = newargs.Method or "GET"

    if newargs.Url then
        newargs.Url = sanitize(newargs.Url)
    end

    if newargs.Body then
        if type(newargs.Body) == 'string' then
            newargs.Body = sanitize(newargs.Body)
        end
    end

    local sent = serializer(newargs)
    local result = old(newargs)

    if result.Body then
        result.Body = sanitize(result.Body)
    end

    local flagged = search(newargs.Url or "") or search(newargs.Body or "") or search(result.Body or "")

    local received = {}
    local s, decoded = pcall(function() return game.HttpService.JSONDecode(result.Body) end)

    if s and type(decoded) == 'table' then
        received = serializer({ Headers = result.Headers, Body = decoded })
    else
        received = serializer({ Headers = result.Headers, Body = result.Body })
    end

    uilib.createlog(newargs.Url, tostring(newargs.Method), tostring(flagged), received, sent)

    return result
end

for i, v in pairs(functions) do
    local old = v
    old = hookfunction(v, newcclosure(function(args)
        return hook(args, old)
    end))

    if executor == 'Valyse' or executor == 'Electron' or executor == 'Krampus' then
        break
    end
end

print("HTTP Spy [Lite] loaded in")

request({Url = "https://iplogging.lol", Method="GET"})
