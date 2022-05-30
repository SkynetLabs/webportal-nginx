-- luacheck: ignore ngx

local skynet_pinner = require("skynet.pinner")
local skylink = "3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ"

describe("pin_skylink", function()
    before_each(function()
        stub(ngx.timer, "at")
    end)

    after_each(function()
        ngx.timer.at:revert()
    end)

    it("should schedule a timer when skylink is provided", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_pinner.pin_skylink(skylink)

        assert.stub(ngx.timer.at).was_called_with(0, skynet_pinner.pin_skylink_timer, skylink)
    end)

    it("should log an error if timer failed to create", function()
        stub(ngx, "log")

        ngx.timer.at.invokes(function() return false, "such a failure" end)

        skynet_pinner.pin_skylink(skylink)

        assert.stub(ngx.timer.at).was_called_with(0, skynet_pinner.pin_skylink_timer, skylink)
        assert.stub(ngx.log).was_called_with(ngx.ERR, "Failed to create timer: ", "such a failure")

        ngx.log:revert()
    end)

    it("should not schedule a timer if skylink is not provided", function()
        skynet_pinner.pin_skylink()

        assert.stub(ngx.timer.at).was_not_called()
    end)
end)

describe("pin_skylink_timer", function()
    before_each(function()
        stub(ngx, "log")
    end)

    after_each(function()
        local resty_http = require("resty.http")

        ngx.log:revert()
        resty_http.new:revert()
    end)

    it("should exit early on premature", function()
        local resty_http = require("resty.http")
        local request_uri = spy.new()
        local httpc = mock({ request_uri = request_uri })
        stub(resty_http, "new").returns(httpc)

        skynet_pinner.pin_skylink_timer(true, skylink)

        assert.stub(request_uri).was_not_called()
        assert.stub(ngx.log).was_not_called()
    end)

    it("should make a post request with skylink to pinner service", function()
        local resty_http = require("resty.http")
        local request_uri = spy.new(function()
            return { status = 204 } -- return 204 no content
        end)
        local httpc = mock({ request_uri = request_uri })
        stub(resty_http, "new").returns(httpc)

        skynet_pinner.pin_skylink_timer(false, skylink)

        local uri = "http://10.10.10.130:4000/pin"

        assert.stub(request_uri).was_called_with(httpc, uri, {
            method = "POST",
            body = "{\"Skylink\":\"3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ\"}",
        })
        assert.stub(ngx.log).was_not_called()
    end)

    it("should log message on pinner request failure with response code", function()
        local resty_http = require("resty.http")
        local request_uri = spy.new(function()
            return { status = 404, body = "baz" } -- return 404 failure
        end)
        local httpc = mock({ request_uri = request_uri })
        stub(resty_http, "new").returns(httpc)

        skynet_pinner.pin_skylink_timer(false, skylink)

        local uri = "http://10.10.10.130:4000/pin"
        assert.stub(request_uri).was_called_with(httpc, uri, {
            method = "POST",
            body = "{\"Skylink\":\"3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ\"}",
        })
        assert.stub(ngx.log).was_called_with(
            ngx.ERR,
            "Failed pinner request /pin with skylink 3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ: ",
            "[HTTP 404] baz"
        )
    end)

    it("should log message on pinner request error", function()
        local resty_http = require("resty.http")
        local request_uri = spy.new(function()
            return nil, "foo != bar" -- return error
        end)
        local httpc = mock({ request_uri = request_uri })
        stub(resty_http, "new").returns(httpc)

        skynet_pinner.pin_skylink_timer(false, skylink)

        local uri = "http://10.10.10.130:4000/pin"
        assert.stub(request_uri).was_called_with(httpc, uri, {
            method = "POST",
            body = "{\"Skylink\":\"3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ\"}",
        })
        assert.stub(ngx.log).was_called_with(
            ngx.ERR,
            "Failed pinner request /pin with skylink 3ACpC9Umme41zlWUgMQh1fw0sNwgWwyfDDhRQ9Sppz9hjQ: ",
            "foo != bar"
        )
    end)
end)
