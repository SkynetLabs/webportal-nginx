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
        stub(skynet_modules, "is_enabled")
    end)

    after_each(function()
        mock.revert(skynet_modules)
    end)

    it("returns true when accounts are disabled", function()
        skynet_modules.is_enabled.on_call_with("a").returns(false)

        assert.is_true(skynet_account.accounts_disabled())
    end)

    it("returns false when accounts are enabled", function()
        skynet_modules.is_enabled.on_call_with("a").returns(true)

        assert.is_false(skynet_account.accounts_disabled())
    end)
end)

describe("should_redirect_accounts", function()
    before_each(function()
        stub(os, "getenv")
        stub(skynet_account, "accounts_enabled")
    end)

    after_each(function()
        os.getenv:revert()
        mock.revert(skynet_account)
    end)

    describe("when accounts are enabled", function ()
        before_each(function ()
            skynet_account.accounts_enabled.returns(true)
        end)

        it("should return false for non-existing env var", function()
            os.getenv.on_call_with("ACCOUNTS_REDIRECT_URL").returns(nil)

            assert.is_false(skynet_account.should_redirect_accounts())
        end)

        it("should return false for blank env var", function()
            os.getenv.on_call_with("ACCOUNTS_REDIRECT_URL").returns("")

            assert.is_false(skynet_account.should_redirect_accounts())
        end)

        it("should return true for configured env var", function()
            os.getenv.on_call_with("ACCOUNTS_REDIRECT_URL").returns("https://siasky.net/siasky-account-notice")

            assert.is_true(skynet_account.should_redirect_accounts())
        end)
    end)

    describe("when accounts are disabled", function ()
        before_each(function ()
            skynet_account.accounts_enabled.returns(false)
        end)

        it("should return true despite there not being a redirect URL configured", function()
            os.getenv.on_call_with("ACCOUNTS_REDIRECT_URL").returns(nil)

            assert.is_true(skynet_account.should_redirect_accounts())
        end)

        it("should return true when ACCOUNTS_REDIRECT_URL being configured", function()
            os.getenv.on_call_with("ACCOUNTS_REDIRECT_URL").returns("https://siasky.net/siasky-account-notice")

            assert.is_true(skynet_account.should_redirect_accounts())
        end)
    end)
end)
