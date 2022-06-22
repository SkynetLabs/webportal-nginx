-- luacheck: ignore os
local skynet_account = require('skynet.account')
local skynet_modules = require('skynet.modules')

describe("exit_access_unauthorized", function()
    before_each(function()
        stub(ngx, "exit")
    end)

    after_each(function()
        mock.revert(ngx)
    end)

    it("should call ngx.exit with status code 401", function()
        skynet_account.exit_access_unauthorized()

        -- expect exit called with ngx.HTTP_UNAUTHORIZED code 401
        assert.stub(ngx.exit).was_called_with(401)
    end)
end)

describe("accounts_enabled", function()
    before_each(function()
        stub(skynet_modules, "is_enabled")
    end)

    after_each(function()
        mock.revert(skynet_modules)
    end)

    it("returns false when accounts are disabled", function()
        skynet_modules.is_enabled.on_call_with("a").returns(false)

        assert.is_false(skynet_account.accounts_enabled())
    end)

    it("returns true when accounts are enabled", function()
        skynet_modules.is_enabled.on_call_with("a").returns(true)

        assert.is_true(skynet_account.accounts_enabled())
    end)
end)

describe("accounts_disabled", function()
    before_each(function()
        stub(skynet_account, "accounts_enabled")
    end)

    after_each(function()
        mock.revert(skynet_account)
    end)

    it("negates accounts_enabled method", function()
        skynet_account.accounts_enabled.returns(true)
        assert.is_false(skynet_account.accounts_disabled())

        skynet_account.accounts_enabled.returns(false)
        assert.is_true(skynet_account.accounts_disabled())
    end)
end)

describe("should_redirect_for_disabled_accounts", function()
    before_each(function()
        stub(os, "getenv")
    end)

    after_each(function()
        os.getenv:revert()
    end)

    it("should return false for not existing env var", function()
        os.getenv.on_call_with("DISABLED_ACCOUNTS_REDIRECT_URL").returns(nil)

        assert.is_false(skynet_account.should_redirect_for_disabled_accounts())
    end)

    it("should return false for blank env var", function()
        os.getenv.on_call_with("DISABLED_ACCOUNTS_REDIRECT_URL").returns("")

        assert.is_false(skynet_account.should_redirect_for_disabled_accounts())
    end)

    it("should return true for blank env var", function()
        os.getenv.on_call_with("DISABLED_ACCOUNTS_REDIRECT_URL").returns("https://siasky.net/siasky-account-notice")

        assert.is_true(skynet_account.should_redirect_for_disabled_accounts())
    end)
end)
