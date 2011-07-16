require 'test/unit'
require 'swiftcore/swiftrpc/fauxmsgpack'

class TC_fauxmsgpack < Test::Unit::TestCase

	def test_to_msgpack
		thing = 'ABC'
		assert_respond_to(thing, :to_msgpack, "Expected to find a #to_msgpack method defined, but none was found.")
    assert_equal(thing.to_msgpack, "\004\b\"\bABC", "Packing \"ABC\" did not yield what was expected.")
    assert_equal(thing, MessagePack.unpack(thing.to_msgpack), "A round trip into and out of the faux msgpack didn't get the data back to where it started.")
	end
  
end
