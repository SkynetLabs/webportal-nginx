local _M = {}

function _M.authorization_header()
    local b64 = require("ngx.base64")
    -- open apipassword file for reading (b flag is required for some reason)
    -- (file /etc/.sia/apipassword has to be mounted from the host system)
    local apipassword_file = io.open("/data/sia/apipassword", "rb")
    -- read apipassword file contents and trim newline (important)
    local apipassword = apipassword_file:read("*all"):gsub("%s+", "")
    -- make sure to close file after reading the password
    apipassword_file.close()
    -- encode the user:password authorization string
    -- (in our case user is empty so it is just :password)
    local content = b64.encode_base64url(":" .. apipassword)
    -- set authorization header with proper base64 encoded string
    return "Basic " .. content
end

return _M
