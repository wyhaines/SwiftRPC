require "swiftcore/swiftrpc"

class Node
	include Swiftcore::SwiftRPC::Receiver
	include Swiftcore::SwiftRPC::Caller

	attr_accessor :next, :prior, :name, :value

	def ref
		self
	end
end

EventMachine.run {
	node = Node.new
	node.name = ARGV[0]
	node.value = ARGV[1]
	node.start_receiver("127.0.0.1:#{ARGV[2]}")
}
