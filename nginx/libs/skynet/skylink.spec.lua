local skynet_skylink = require("skynet.skylink")

local base32 = "0404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r30"
local base64 = "AQBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNjA"

describe("parse", function()
   it("should return unchanged base64 skylink", function()
      assert.is.same(skynet_skylink.parse(base64), base64)
   end)

   it("should transform base32 skylink into base64", function()
      assert.is.same(skynet_skylink.parse(base32), base64)
   end)
end)

describe("validate", function()
   it("should return nil for valid base32 skylink", function()
      assert.is_nil(skynet_skylink.validate(base32))
   end)

   it("should return nil for valid base64 skylink", function()
      assert.is_nil(skynet_skylink.validate(base64))
   end)

   it("should return size error when skylink does not match neither base32 nor base64 size", function()
      assert.is_equal(skynet_skylink.validate(""), "Skylink has incorrect size")
      assert.is_equal(skynet_skylink.validate(base32 .. "a"), "Skylink has incorrect size")
      assert.is_equal(skynet_skylink.validate(base64 .. "a"), "Skylink has incorrect size")
   end)

   it("should return position of a bad character in base32 encoded skylink", function()
      -- invalid first char * (asterisk)
      assert.is_equal(skynet_skylink.validate("*404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r30"), "Base32 encoded skylink contains invalid char at position 1")

      -- invalid last char x
      assert.is_equal(skynet_skylink.validate("0404dsjvti046fsua4ktor9grrpe76erq9jot9cvopbhsvsu76r4r3x"), "Base32 encoded skylink contains invalid char at position 55")

      -- invalid char . (dot)
      assert.is_equal(skynet_skylink.validate("0404dsjvti046fsua4ktor9gr.pe76erq9jot9cvopbhsvsu76r4r30"), "Base32 encoded skylink contains invalid char at position 26")
   end)

   it("should return position of a bad character in base64 encoded skylink", function()
      -- invalid first char * (asterisk)
      assert.is_equal(skynet_skylink.validate("*QBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNjA"), "Base64 encoded skylink contains invalid char at position 1")

      -- invalid last char / (forward slash)
      assert.is_equal(skynet_skylink.validate("AQBG8n_sgEM_nlEp3G0w3vLjmdvSZ46ln8ZXHn-eObZNj/"), "Base64 encoded skylink contains invalid char at position 46")

      -- invalid char . (dot)
      assert.is_equal(skynet_skylink.validate("AQBG8n_sgEM_nlEp3G0w3vLjm.vSZ46ln8ZXHn-eObZNjA"), "Base64 encoded skylink contains invalid char at position 26")
   end)
end)

describe("hash", function()
   local base64 = "EADi4QZWt87sSDCSjVTcmyI5tE_YAsuC90BcCi_jEmG5NA"
   local hash = "6cfb9996ad74e5614bbb8e7228e72f1c1bc14dd9ce8a83b3ccabdb6d8d70f330"

   it("should hash skylink", function()
      assert.is.same(hash, skynet_skylink.hash(base64))
   end)
end)
