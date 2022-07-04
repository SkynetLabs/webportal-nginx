local _M = {}

local ngx_base64 = require("ngx.base64")
local utils = require("utils")

function _M.authorization_header()
    -- read api password from env variable
    local apipassword = utils.getenv("SIA_API_PASSWORD")
    -- if api password is not available as env variable, read it from disk
    if not apipassword then
        -- open apipassword file for reading (b flag is required for some reason)
        -- (file /etc/.sia/apipassword has to be mounted from the host system)
        local apipassword_file = io.open("/data/sia/apipassword", "rb")
        -- make sure to throw a meaningful error if apipassword file does not exist
        if not apipassword_file then
            error("Error reading /data/sia/apipassword file")
        end
        -- read apipassword file contents and trim newline (important)
        apipassword = apipassword_file:read("*all"):gsub("%s+", "")
        -- make sure to close file after reading the password
        apipassword_file.close()
    end
    -- encode the user:password authorization string
    -- (in our case user is empty so it is just :password)
    local content = ngx_base64.encode_base64url(":" .. apipassword)
    -- set authorization header with proper base64 encoded string
    return "Basic " .. content
end

function _M.get_public_addr()
    local public_addr = ngx.shared.config.get("public_addr")

    -- return public addr if it exists in cache
    if public_addr then
        return public_addr
    end

    -- fetch public address if it is not cached yet
    local httpc = require("resty.http").new()
    local res, err = httpc:request_uri("http://whatismyip.akamai.com")

    -- report error in case whatismyip.akamai.com failed
    if err or (res and res.status ~= ngx.HTTP_OK) then
        local error_response = err or ("[HTTP " .. res.status .. "] " .. res.body)
        ngx.log(ngx.ERR, "Failed request to whatismyip.akamai.com: ", error_response)
    elseif res and res.status == ngx.HTTP_OK then
        -- whatismyip.akamai.com responds with the ip address as plain text body
        ngx.shared.config.set("public_addr", res.body)
        return res.body
    end

    return nil
end

return _M
