require 'test/unit'
require 'swiftcore/swiftrpc/fauxmsgpack'

class TC_fauxmsgpack < Test::Unit::TestCase

	def test_to_msgpack
		thing = 'ABC'
		assert_respond_to(thing, :to_msgpack, "Expected to find a #to_msgpack method defined, but none was found.")
	end

end
