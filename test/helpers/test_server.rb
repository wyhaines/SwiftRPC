require "swiftcore/swiftrpc"

class TestRPC
	include Swiftcore::SwiftRPC::Receiver

	def seven
		7
	end

	def square(n)
		n*2
	end

	def squareroot(n)
		Math.sqrt(n)
	end

  def not_packable_array
	  [1, 2, Exception.new, 4]
  end
end

EventMachine.run {
	test_rpc = TestRPC.new
	test_rpc.start_receiver('127.0.0.1:5555')
}
