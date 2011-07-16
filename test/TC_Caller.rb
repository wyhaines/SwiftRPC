require 'test/unit'
require 'swiftcore/swiftrpc'

class TestCaller
	include Swiftcore::SwiftRPC::Caller
end

class TC_Caller < Test::Unit::TestCase

	def test_call
		connected = false
		EventMachine.run {
			tx = TestCaller.new
			tx.connect_to('127.0.0.1:5555','test') { connected = true }
			EM::add_timer(1) { tx.call_on('test',:seven) {|num| assert_equal(7,num, "The response received was not what was expected.")}}
			EM::add_timer(2) { EM.stop_event_loop }
		}
		assert connected, "Did not receive affirmation that the client connected to the server."
	end

end
