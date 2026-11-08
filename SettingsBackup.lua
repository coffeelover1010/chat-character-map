-- Independently implemented Forever settings backup. Normal SavedVariables remain enabled.
local addonName = ...
local database, selected = "ChatCharacterMapDB", nil
local _, _, _, interface = GetBuildInfo()
if type(interface) ~= "number" or interface < 16000 or interface >= 17000 then return end
if not C_CVar or not C_CVar.GetCVar or not C_CVar.SetCVar or not C_CVar.RegisterCVar then return end
local prefix = "VCSettings1_" .. addonName .. "_"
local ready, previous, warned = false, nil, false
local function warn()
    if warned then return end
    warned = true
    print(addonName .. ": Settings backup unavailable. Normal saved variables are still enabled.")
end
local function read(key)
    local ok, value = pcall(C_CVar.GetCVar, prefix .. key)
    if ok then return value end
end
local function write(key, value)
    if read(key) == nil then pcall(C_CVar.RegisterCVar, prefix .. key, "") end
    local ok = pcall(C_CVar.SetCVar, prefix .. key, value)
    return ok and read(key) == value
end
-- Length-prefixed data, never executable Lua. Strings preserve punctuation and UTF-8.
local function encode(value, depth)
    assert(depth < 12, "settings too deep")
    local kind = type(value)
    if kind == "boolean" then return value and "b1" or "b0" end
    if kind == "string" or kind == "number" then
        local raw = tostring(value)
        assert(#raw <= 24000, "setting too long")
        return (kind == "string" and "s" or "n") .. #raw .. ":" .. raw
    end
    assert(kind == "table", "unsupported setting")
    local keys, parts = {}, {}
    for key in pairs(value) do
        assert(type(key) == "string" or type(key) == "number", "unsupported key")
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b) return type(a) .. tostring(a) < type(b) .. tostring(b) end)
    assert(#keys <= 4000, "too many settings")
    for _, key in ipairs(keys) do
        parts[#parts + 1] = encode(key, depth + 1)
        parts[#parts + 1] = encode(value[key], depth + 1)
    end
    local result = "t" .. #keys .. ":" .. table.concat(parts)
    assert(#result <= 24000, "settings backup full")
    return result
end
local function decode(raw)
    local offset = 1
    local function item(depth)
        assert(depth < 12, "invalid depth")
        local kind = raw:sub(offset, offset)
        offset = offset + 1
        if kind == "b" then
            local bit = raw:sub(offset, offset)
            offset = offset + 1
            assert(bit == "0" or bit == "1", "invalid boolean")
            return bit == "1"
        end
        assert(kind == "s" or kind == "n" or kind == "t", "invalid type")
        local finish = raw:find(":", offset, true)
        assert(finish and raw:sub(offset, finish - 1):match("^%d+$"), "invalid length")
        local count = tonumber(raw:sub(offset, finish - 1))
        assert(count and count <= 24000, "invalid size")
        offset = finish + 1
        if kind == "t" then
            assert(count <= 4000, "invalid table")
            local result = {}
            for _ = 1, count do
                local key = item(depth + 1)
                assert(type(key) == "string" or type(key) == "number", "invalid key")
                result[key] = item(depth + 1)
            end
            return result
        end
        assert(offset + count - 1 <= #raw, "truncated setting")
        local result = raw:sub(offset, offset + count - 1)
        offset = offset + count
        if kind == "n" then
            result = tonumber(result)
            assert(result and result == result and math.abs(result) < math.huge, "invalid number")
        end
        return result
    end
    local result = item(0)
    assert(offset == #raw + 1 and type(result) == "table", "invalid backup")
    return result
end
local function checksum(raw)
    local total = 0
    for index = 1, #raw do total = (total * 33 + raw:byte(index)) % 2147483647 end
    return tostring(total)
end
local function snapshot()
    local source = _G[database]
    if type(source) ~= "table" then return end
    if not selected then return source end
    local result = {}
    for _, key in ipairs(selected) do result[key] = source[key] end
    return result
end
local function save()
    if not ready or (InCombatLockdown and InCombatLockdown()) then return end
    local data = snapshot()
    if not data then return end
    local ok, raw = pcall(encode, data, 0)
    if not ok then warn(); return end
    if raw == previous then return end
    -- Two banks: an incomplete write never replaces the last committed backup.
    local head = read("Head") or ""
    local bank = head:sub(1, 1) == "A" and "B" or "A"
    local hex = raw:gsub(".", function(c) return string.format("%02x", c:byte()) end)
    local count = math.ceil(#hex / 500)
    for index = 1, count do
        if not write(bank .. index, hex:sub((index - 1) * 500 + 1, index * 500)) then warn(); return end
    end
    if not write("Head", bank .. ":" .. count .. ":" .. #raw .. ":" .. checksum(raw)) then warn(); return end
    previous = raw
end
local function restore()
    local head = read("Head")
    if not head or head == "" then return end
    local bank, count, length, sum = head:match("^([AB]):(%d+):(%d+):(%d+)$")
    count, length = tonumber(count), tonumber(length)
    if not count or count < 1 or count > 96 or not length or length > 24000 then warn(); return end
    local pieces = {}
    for index = 1, count do pieces[index] = read(bank .. index) or "" end
    local hex = table.concat(pieces)
    if #hex ~= length * 2 or hex:find("[^0-9a-f]") then warn(); return end
    local raw = hex:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end)
    if checksum(raw) ~= sum then warn(); return end
    local ok, recovered = pcall(decode, raw)
    if not ok or type(recovered) ~= "table" then warn(); return end
    if type(_G[database]) ~= "table" then _G[database] = {} end
    local destination = _G[database]
    if selected then
        for _, key in ipairs(selected) do destination[key] = recovered[key] end
    else
        for key in pairs(destination) do destination[key] = nil end
        for key, value in pairs(recovered) do destination[key] = value end
    end
    previous = raw
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        restore()
        ready = true
        C_Timer.NewTicker(2, save)
    elseif event == "PLAYER_LOGOUT" then save() end
end)
