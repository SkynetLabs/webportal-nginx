local utils = require("utils")
local skynet_access = require("skynet.access")
local skynet_utils = require("skynet.utils")

describe("match_allowed_internal_networks", function()
    it("should return true for addresses from 127.0.0.0/8 host network", function()
        -- start and end of the range
        assert.is_true(skynet_access.match_allowed_internal_networks("127.0.0.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("127.255.255.255"))
        -- random addresses from the network
        assert.is_true(skynet_access.match_allowed_internal_networks("127.0.0.1"))
        assert.is_true(skynet_access.match_allowed_internal_networks("127.10.0.100"))
        assert.is_true(skynet_access.match_allowed_internal_networks("127.99.210.3"))
        assert.is_true(skynet_access.match_allowed_internal_networks("127.210.20.99"))
    end)

    it("should return true for addresses from 10.0.0.0/8 private network", function()
        -- start and end of the range
        assert.is_true(skynet_access.match_allowed_internal_networks("10.0.0.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("10.255.255.255"))
        -- random addresses from the network
        assert.is_true(skynet_access.match_allowed_internal_networks("10.10.1.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("10.10.10.10"))
        assert.is_true(skynet_access.match_allowed_internal_networks("10.87.10.120"))
        assert.is_true(skynet_access.match_allowed_internal_networks("10.210.23.255"))
    end)

    it("should return true for addresses from 172.16.0.0/12 private network", function()
        -- start and end of the range
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.0.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.255.255"))
        -- random addresses from the network
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.1.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.10.10"))
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.10.120"))
        assert.is_true(skynet_access.match_allowed_internal_networks("172.16.230.55"))
    end)

    it("should return true for addresses from 192.168.0.0/16 private network", function()
        -- start and end of the range
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.0.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.255.255"))
        -- random addresses from the network
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.1.0"))
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.10.10"))
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.10.120"))
        assert.is_true(skynet_access.match_allowed_internal_networks("192.168.230.55"))
    end)

    it("should return false for addresses from outside of allowed networks", function()
        assert.is_false(skynet_access.match_allowed_internal_networks("8.8.8.8"))
        assert.is_false(skynet_access.match_allowed_internal_networks("16.12.0.1"))
        assert.is_false(skynet_access.match_allowed_internal_networks("115.23.44.17"))
        assert.is_false(skynet_access.match_allowed_internal_networks("198.19.0.20"))
        assert.is_false(skynet_access.match_allowed_internal_networks("169.254.1.1"))
        assert.is_false(skynet_access.match_allowed_internal_networks("212.32.41.12"))
    end)
end)

describe("should_block_access", function()
    local remote_addr = "127.0.0.1"

    before_each(function()
        stub(utils, "getenv")
        stub(skynet_access, "match_allowed_internal_networks")
    end)

    after_each(function()
        mock.revert(utils)
        mock.revert(skynet_access)
    end)

    it("should not block access if DENY_PUBLIC_ACCESS is not set", function()
        utils.getenv.on_call_with("DENY_PUBLIC_ACCESS").returns(nil)

        assert.is_false(skynet_access.should_block_access(remote_addr))
    end)

    it("should not block access if DENY_PUBLIC_ACCESS is set to false", function()
        utils.getenv.on_call_with("DENY_PUBLIC_ACCESS").returns(false)

        assert.is_false(skynet_access.should_block_access(remote_addr))
    end)

    it("should not block access if DENY_PUBLIC_ACCESS is set to true but request is from internal network", function()
        utils.getenv.on_call_with("DENY_PUBLIC_ACCESS").returns(true)
        skynet_access.match_allowed_internal_networks.on_call_with(remote_addr).returns(true)

        assert.is_false(skynet_access.should_block_access(remote_addr))
    end)

    it("should block access if DENY_PUBLIC_ACCESS is set to true and request is not from internal network", function()
        utils.getenv.on_call_with("DENY_PUBLIC_ACCESS", "boolean").returns(true)
        skynet_access.match_allowed_internal_networks.on_call_with(remote_addr).returns(false)

        assert.is_true(skynet_access.should_block_access(remote_addr))
    end)
end)

describe("exit_public_access_forbidden", function()
    before_each(function()
        stub(skynet_utils, "exit")
    end)

    after_each(function()
        mock.revert(skynet_utils)
    end)

    it("should call exit with status code 403 and proper message", function()
        skynet_access.exit_public_access_forbidden()

        assert.stub(skynet_utils.exit).was_called_with(403, "Server public access denied")
    end)
end)
