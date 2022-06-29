local skynet_skylink = require("skynet.skylink")

local skylink_base64 = "EADi4QZWt87sSDCSjVTcmyI5tE_YAsuC90BcCi_jEmG5NA"
local resolver_skylink_base32 = "0404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r30"
local resolver_skylink_base64 = "AQBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNjA"

describe("parse", function()
   it("should return unchanged base64 skylink", function()
      assert.is.same(resolver_skylink_base64, skynet_skylink.parse(resolver_skylink_base64))
   end)

   it("should transform base32 skylink into base64", function()
      assert.is.same(resolver_skylink_base64, skynet_skylink.parse(resolver_skylink_base32))
   end)
end)

describe("validate", function()
   it("should return nil for valid base32 skylink", function()
      assert.is_nil(skynet_skylink.validate(resolver_skylink_base32))
   end)

   it("should return nil for valid base64 skylink", function()
      assert.is_nil(skynet_skylink.validate(resolver_skylink_base64))
   end)

   it("should return size error when skylink is empty", function()
      assert.is_equal("Skylink has incorrect size", skynet_skylink.validate(""))
   end)

   it("should return size error when skylink does not match neither base32 nor base64 size", function()
      assert.is_equal("Skylink has incorrect size", skynet_skylink.validate(resolver_skylink_base32 .. "a"))
      assert.is_equal("Skylink has incorrect size", skynet_skylink.validate(resolver_skylink_base64 .. "a"))
   end)

   describe("with a bad character in base32 encoded skylink", function()
      it("should return position when first character is bad", function()
         local error = "Base32 encoded skylink contains invalid char at position 1"

         -- invalid first char * (asterisk) at position 1
         assert.is_equal(error, skynet_skylink.validate("*404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r30"))
      end)

      it("should return position when last character is bad", function()
         local error = "Base32 encoded skylink contains invalid char at position 55"

         -- invalid last char x at position 55
         assert.is_equal(error, skynet_skylink.validate("0404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r3x"))
      end)

      it("should return position when middle character is bad", function()
         local error = "Base32 encoded skylink contains invalid char at position 26"

         -- invalid char . (dot) at position 26
         assert.is_equal(error, skynet_skylink.validate("0404dsjvti046fsua4ktor9gr.pe76erq9jot9cvopbhsvsu76r4r30"))
      end)
   end)

   describe("with a bad character in base64 encoded skylink", function()
      it("should return position when first character is bad", function()
         local error = "Base64 encoded skylink contains invalid char at position 1"

         -- invalid first char * (asterisk) at position 1
         assert.is_equal(error, skynet_skylink.validate("*QBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNjA"))
      end)

      it("should return position when last character is bad", function()
         local error = "Base64 encoded skylink contains invalid char at position 46"

         -- invalid last char / (forward slash) at position 46
         assert.is_equal(error, skynet_skylink.validate("AQBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNj/"))
      end)

      it("should return position when middle character is bad", function()
         local error = "Base64 encoded skylink contains invalid char at position 26"

         -- invalid char . (dot) at position 26
         assert.is_equal(error, skynet_skylink.validate("AQBG8n_sgEM_nlEp3G0w3vLjm.vSZ46ln8ZXHn-eObZNjA"))
      end)
   end)
end)

describe("hash", function()
   it("should hash skylink", function()
      local hash = "6cfb9996ad74e5614bbb8e7228e72f1c1bc14dd9ce8a83b3ccabdb6d8d70f330"

      assert.is.same(hash, skynet_skylink.hash(skylink_base64))
   end)
end)
