require 'test/unit'
require 'swiftcore/swiftrpc/util'

class MixinTestcase
	include Swiftcore::SwiftRPC::UtilityMixins
end

class TC_UtilityMixins < Test::Unit::TestCase

	def test__parse_receiver_address
		tc = MixinTestcase.new
		result = tc._parse_address("localhost:1234")
		assert_kind_of(Array, result, "#_parse_address should return an instance of Array.")

		assert_equal("localhost", result.first)
		assert_equal(1234, result.last)

    result = tc._parse_address(':5678')
    assert_equal("127.0.0.1", result.first)
    assert_equal(5678, result.last)
	end

	def test__format_full_address
		tc = MixinTestcase.new
		assert_equal(tc._format_full_address("localhost",1234), "localhost:1234")
	end

end
