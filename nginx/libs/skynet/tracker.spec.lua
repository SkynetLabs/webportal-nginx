-- luacheck: ignore ngx

local skynet_tracker = require("skynet.tracker")

local valid_skylink = "AQBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNjA"
local valid_status_code = 200
local valid_auth_headers = { ["Skynet-Api-Key"] = "foo" }
local valid_ip = "12.34.56.78"

describe("track_download", function()
    local valid_body_bytes_sent = 12345

    before_each(function()
        stub(ngx.timer, "at")
    end)

    after_each(function()
        ngx.timer.at:revert()
    end)

    it("should schedule a timer when conditions are met", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_download(valid_skylink, valid_status_code, valid_auth_headers, valid_body_bytes_sent)

        assert.stub(ngx.timer.at).was_called_with(
            0,
            skynet_tracker.track_download_timer,
            valid_skylink,
            valid_status_code,
            valid_auth_headers,
            valid_body_bytes_sent
        )
    end)

    it("should not schedule a timer if skylink is empty", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_download(nil, valid_status_code, valid_auth_headers, valid_body_bytes_sent)

        assert.stub(ngx.timer.at).was_not_called()
    end)

    it("should not schedule a timer if status code is not in 2XX range", function()
        ngx.timer.at.invokes(function() return true, nil end)

        -- couple of example of 4XX and 5XX codes
        skynet_tracker.track_download(valid_skylink, 401, valid_auth_headers, valid_body_bytes_sent)
        skynet_tracker.track_download(valid_skylink, 403, valid_auth_headers, valid_body_bytes_sent)
        skynet_tracker.track_download(valid_skylink, 490, valid_auth_headers, valid_body_bytes_sent)
        skynet_tracker.track_download(valid_skylink, 500, valid_auth_headers, valid_body_bytes_sent)
        skynet_tracker.track_download(valid_skylink, 502, valid_auth_headers, valid_body_bytes_sent)

        assert.stub(ngx.timer.at).was_not_called()
    end)

    it("should not schedule a timer if auth headers are empty", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_download(valid_skylink, valid_status_code, {}, valid_body_bytes_sent)

        assert.stub(ngx.timer.at).was_not_called()
    end)

    it("should log an error if timer failed to create", function()
        stub(ngx, "log")
        ngx.timer.at.invokes(function() return false, "such a failure" end)

        skynet_tracker.track_download(valid_skylink, valid_status_code, valid_auth_headers, valid_body_bytes_sent)

        assert.stub(ngx.timer.at).was_called_with(
            0,
            skynet_tracker.track_download_timer,
            valid_skylink,
            valid_status_code,
            valid_auth_headers,
            valid_body_bytes_sent
        )
        assert.stub(ngx.log).was_called_with(ngx.ERR, "Failed to create timer: ", "such a failure")

        ngx.log:revert()
    end)

    describe("track_download_timer", function()
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
            local request_uri = spy.new(function()
                return { status = 200 } -- return 200 success
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_download_timer(
                true,
                valid_skylink,
                valid_status_code,
                valid_auth_headers,
                valid_body_bytes_sent
            )

            assert.stub(request_uri).was_not_called()
            assert.stub(ngx.log).was_not_called()
        end)

        it("should make a post request to tracker service", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return { status = 204 } -- return 204 success
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_download_timer(
                false,
                valid_skylink,
                valid_status_code,
                valid_auth_headers,
                valid_body_bytes_sent
            )

            local uri_params = "status=" .. valid_status_code .. "&bytes=" .. valid_body_bytes_sent
            local uri = "http://10.10.10.70:3000/track/download/" .. valid_skylink .. "?" .. uri_params
            assert.stub(request_uri).was_called_with(httpc, uri, { method = "POST", headers = valid_auth_headers })
            assert.stub(ngx.log).was_not_called()
        end)

        it("should log message on tracker request failure with response code", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return { status = 404, body = "baz" } -- return 404 failure
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_download_timer(
                false,
                valid_skylink,
                valid_status_code,
                valid_auth_headers,
                valid_body_bytes_sent
            )

            local uri_params = "status=" .. valid_status_code .. "&bytes=" .. valid_body_bytes_sent
            local uri = "http://10.10.10.70:3000/track/download/" .. valid_skylink .. "?" .. uri_params
            assert.stub(request_uri).was_called_with(httpc, uri, { method = "POST", headers = valid_auth_headers })
            assert.stub(ngx.log).was_called_with(
                ngx.ERR,
                "Failed accounts service request /track/download/" .. valid_skylink .. ": ",
                "[HTTP 404] baz"
            )
        end)

        it("should log message on tracker request error", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return nil, "foo != bar" -- return error
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_download_timer(
                false,
                valid_skylink,
                valid_status_code,
                valid_auth_headers,
                valid_body_bytes_sent
            )

            local uri_params = "status=" .. valid_status_code .. "&bytes=" .. valid_body_bytes_sent
            local uri = "http://10.10.10.70:3000/track/download/" .. valid_skylink .. "?" .. uri_params
            assert.stub(request_uri).was_called_with(httpc, uri, { method = "POST", headers = valid_auth_headers })
            assert.stub(ngx.log).was_called_with(
                ngx.ERR,
                "Failed accounts service request /track/download/" .. valid_skylink .. ": ",
                "foo != bar"
            )
        end)
    end)
end)

describe("track_upload", function()
    before_each(function()
        stub(ngx.timer, "at")
    end)

    after_each(function()
        ngx.timer.at:revert()
    end)

    it("should schedule a timer when conditions are met", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_upload(valid_skylink, valid_status_code, valid_auth_headers, valid_ip)

        assert.stub(ngx.timer.at).was_called_with(
            0,
            skynet_tracker.track_upload_timer,
            valid_skylink,
            valid_auth_headers,
            valid_ip
        )
    end)

    it("should not schedule a timer if skylink is empty", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_upload(nil, valid_status_code, valid_auth_headers, valid_ip)

        assert.stub(ngx.timer.at).was_not_called()
    end)

    it("should not schedule a timer if status code is not in 2XX range", function()
        ngx.timer.at.invokes(function() return true, nil end)

        -- couple of example of 4XX and 5XX codes
        skynet_tracker.track_upload(valid_skylink, 401, valid_auth_headers, valid_ip)
        skynet_tracker.track_upload(valid_skylink, 403, valid_auth_headers, valid_ip)
        skynet_tracker.track_upload(valid_skylink, 490, valid_auth_headers, valid_ip)
        skynet_tracker.track_upload(valid_skylink, 500, valid_auth_headers, valid_ip)
        skynet_tracker.track_upload(valid_skylink, 502, valid_auth_headers, valid_ip)

        assert.stub(ngx.timer.at).was_not_called()
    end)

    it("should schedule a timer if auth headers are empty", function()
        ngx.timer.at.invokes(function() return true, nil end)

        skynet_tracker.track_upload(valid_skylink, valid_status_code, {}, valid_ip)

        assert.stub(ngx.timer.at).was_called_with(
            0,
            skynet_tracker.track_upload_timer,
            valid_skylink,
            {},
            valid_ip
        )
    end)

    it("should log an error if timer failed to create", function()
        stub(ngx, "log")
        ngx.timer.at.invokes(function() return false, "such a failure" end)

        skynet_tracker.track_upload(valid_skylink, valid_status_code, valid_auth_headers, valid_ip)

        assert.stub(ngx.timer.at).was_called_with(
            0,
            skynet_tracker.track_upload_timer,
            valid_skylink,
            valid_auth_headers,
            valid_ip
        )
        assert.stub(ngx.log).was_called_with(ngx.ERR, "Failed to create timer: ", "such a failure")

        ngx.log:revert()
    end)

    describe("track_upload_timer", function()
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
            local request_uri = spy.new(function()
                return { status = 200 } -- return 200 success
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_upload_timer(
                true,
                valid_skylink,
                valid_auth_headers,
                valid_ip
            )

            assert.stub(request_uri).was_not_called()
            assert.stub(ngx.log).was_not_called()
        end)

        it("should make a post request to tracker service", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return { status = 204 } -- return 204 success
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_upload_timer(
                false,
                valid_skylink,
                valid_auth_headers,
                valid_ip
            )

            local uri = "http://10.10.10.70:3000/track/upload/" .. valid_skylink
            assert.stub(request_uri).was_called_with(httpc, uri, {
                method = "POST",
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                    ["Skynet-Api-Key"] = "foo",
                },
                body = "ip=" .. valid_ip
            })
            assert.stub(ngx.log).was_not_called()
        end)

        it("should log message on tracker request failure with response code", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return { status = 404, body = "baz" } -- return 404 failure
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_upload_timer(
                false,
                valid_skylink,
                valid_auth_headers,
                valid_ip
            )

            local uri = "http://10.10.10.70:3000/track/upload/" .. valid_skylink
            assert.stub(request_uri).was_called_with(httpc, uri, {
                method = "POST",
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                    ["Skynet-Api-Key"] = "foo",
                },
                body = "ip=" .. valid_ip
            })
            assert.stub(ngx.log).was_called_with(
                ngx.ERR,
                "Failed accounts service request /track/upload/" .. valid_skylink .. ": ",
                "[HTTP 404] baz"
            )
        end)

        it("should log message on tracker request error", function()
            local resty_http = require("resty.http")
            local request_uri = spy.new(function()
                return nil, "foo != bar" -- return error
            end)
            local httpc = mock({ request_uri = request_uri })
            stub(resty_http, "new").returns(httpc)

            skynet_tracker.track_upload_timer(
                false,
                valid_skylink,
                valid_auth_headers,
                valid_ip
            )

            local uri = "http://10.10.10.70:3000/track/upload/" .. valid_skylink
            assert.stub(request_uri).was_called_with(httpc, uri, {
                method = "POST",
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                    ["Skynet-Api-Key"] = "foo",
                },
                body = "ip=" .. valid_ip
            })
            assert.stub(ngx.log).was_called_with(
                ngx.ERR,
                "Failed accounts service request /track/upload/" .. valid_skylink .. ": ",
                "foo != bar"
            )
        end)
    end)
end)
