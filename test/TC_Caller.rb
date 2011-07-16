require 'test/unit'
require 'swiftcore/swiftrpc/caller'

class TestCaller
	include Swiftcore::SwiftRPC::Caller
end

class TC_Caller < Test::Unit::TestCase

	def test_call
		tx = TestCaller.new
		tx.connect_to('127.0.0.1:5555','test') { puts "CONNECTED!" }
		puts tc.call_on('test',:seven)
	end

end
