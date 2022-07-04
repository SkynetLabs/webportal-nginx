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

function _M.should_block_public_access()
    local is_public_access_denied = utils.getenv("DENY_PUBLIC_ACCESS", "boolean") == true
    local is_external_request = _M.is_internal_request() == false

    return is_public_access_denied and is_external_request
end

-- utility that returns information whether the request originates from
-- the host machine (internal) or is it an external request
function _M.is_internal_request()
    local ipmatcher = require("resty.ipmatcher")
    local ipmatcher_private_network = ipmatcher.new({
        "127.0.0.0/8", -- host network
        "10.0.0.0/8", -- private network
        "172.16.0.0/12", -- private network
        "192.168.0.0/16", -- private network
    })

    -- if the request comes from private network then it is considered internal
    if ipmatcher_private_network:match(ngx.var.remote_addr) then
        return true
    end

    -- if there is no cached public addr, fetch it to speed up subsequent comparisons
    if ngx.shared.config.get("public_addr") == nil then
        local httpc = require("resty.http").new()
        local res, err = httpc:request_uri("http://whatismyip.akamai.com")

        -- report error in case whatismyip.akamai.com failed
        if err or (res and res.status ~= ngx.HTTP_OK) then
            local error_response = err or ("[HTTP " .. res.status .. "] " .. res.body)
            ngx.log(ngx.ERR, "Failed request to whatismyip.akamai.com: ", error_response)
        elseif res and res.status == ngx.HTTP_OK then
            ngx.shared.config.set("public_addr", res.body)
        end
    end

    -- if the request comes from the server own ip then it is considered internal
    return ngx.var.remote_addr == ngx.shared.config.get("public_addr")
end

return _M
