local skynet_account = require('skynet.account')

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
