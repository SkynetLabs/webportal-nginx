local _M = {}

function _M.pin_skylink_timer(premature, skylink)
    if premature then return end

    local httpc = require("resty.http").new()
    local cjson = require('cjson')

    -- 10.10.10.130 points to pinner service (alias not available when using resty-http)
    local res, err = httpc:request_uri("http://10.10.10.130:4000/pin", {
        method = "POST",
        body = cjson.encode({ ["Skylink"] = skylink }),
    })

    if err or (res and res.status ~= ngx.HTTP_NO_CONTENT) then
        local error_response = err or ("[HTTP " .. res.status .. "] " .. res.body)
        ngx.log(ngx.ERR, "Failed pinner request /pin with skylink " .. skylink .. ": ", error_response)
    end
end

function _M.pin_skylink(skylink)
    if not skylink then return end

    local ok, err = ngx.timer.at(0, _M.pin_skylink_timer, skylink)
    if not ok then ngx.log(ngx.ERR, "Failed to create timer: ", err) end
end

return _M
