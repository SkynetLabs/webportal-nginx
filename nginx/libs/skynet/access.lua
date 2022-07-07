local _M = {}

-- imports
local utils = require("utils")
local skynet_utils = require("skynet.utils")

function _M.match_allowed_internal_networks(ip_addr)
    local ipmatcher = require("resty.ipmatcher")
    local ipmatcher_private_network = ipmatcher.new({
        "127.0.0.0/8", -- host network
        "10.0.0.0/8", -- private network
        "172.16.0.0/12", -- private network
        "192.168.0.0/16", -- private network
    })

    return ipmatcher_private_network:match(ip_addr)
end

-- function that decides whether the request should be blocked or not
-- based on portal settings and request properties
function _M.should_block_public_access()
    -- if portal should deny public access and the request is not internal then block it
    return utils.getenv("DENY_PUBLIC_ACCESS", "boolean") and not _M.match_allowed_internal_networks(ngx.var.remote_addr)
end

-- handle request exit when access to portal should deny public access
function _M.exit_public_access_forbidden()
    return skynet_utils.exit(ngx.HTTP_FORBIDDEN, "Server public access denied")
end

return _M
