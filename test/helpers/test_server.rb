require "swiftcore/swiftrpc"

class TestRPC
	include Swiftcore::SwiftRPC::Receiver

	def seven
		7
	end
end

EventMachine.run {
	test_rpc = TestRPC.new
	test_rpc.start_receiver('127.0.0.1:5555')
}
