local _M = {}

local basexx = require("basexx")
local hasher = require("hasher")

local base32Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
local base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

-- parse any skylink and return base64 version
function _M.parse(skylink)
    if string.len(skylink) == 55 then
        local decoded = basexx.from_basexx(string.upper(skylink), base32Alphabet, 5)

        return basexx.to_url64(decoded)
    end

    return skylink
end

-- simple skylink validation that checks size and alphabet
-- it is not fully accurate but good enough for most cases
function _M.validate(skylink)
    -- when skylink is 46 chars long we assume it is base64 encoded
    if string.len(skylink) == 46 then
        -- check if there are any characters in skylink outside of the base64 alphabet
        local invalid_char_pos = string.find(skylink, "[^" .. base64Alphabet .. "]")

        if invalid_char_pos == nil then
            return nil
        end

        return "Base64 encoded skylink contains invalid char at position " .. invalid_char_pos
    end

    -- when skylink is 46 chars long we assume it is base32 encoded
    if string.len(skylink) == 55 then
        -- check if there are any characters in skylink outside of the base32 alphabet
        -- base32 skylink is case insensitive so it is safe to convert to uppercase before comparing
        local invalid_char_pos = string.find(string.upper(skylink), "[^" .. base32Alphabet .. "]")

        if invalid_char_pos == nil then
            return nil
        end

        return "Base32 encoded skylink contains invalid char at position " .. invalid_char_pos
    end

    return "Skylink has incorrect size"
end

-- hash skylink into 32 bytes hash used in blocklist
function _M.hash(skylink)
    -- ensure that the skylink is base64 encoded
    local base64Skylink = _M.parse(skylink)

    -- decode skylink from base64 encoding
    local rawSkylink = basexx.from_url64(base64Skylink)

    -- drop first two bytes and leave just merkle root
    local rawMerkleRoot = string.sub(rawSkylink, 3)

    -- parse with blake2b with key length of 32
    local blake2bHashed = hasher.blake2b(rawMerkleRoot, 32)

    -- hex encode the blake hash
    local hexHashed = basexx.to_hex(blake2bHashed)

    -- lowercase the hex encoded hash
    local lowerHexHashed = string.lower(hexHashed)

    return lowerHexHashed
end

return _M
