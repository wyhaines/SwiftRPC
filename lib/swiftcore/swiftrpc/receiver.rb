# Every valid target for RPC is a Receiver.
require 'eventmachine'
require 'digest/sha1'
require 'swiftcore/swiftrpc/util'

module Swiftcore
	module SwiftRPC
		module Receiver

      include UtilitMixins

			Epoch = 0x01B21DD213814000
			TimeFormat = "%08x-%04x-%04x"
			RandHigh = 1 << 128

			# The UUIDs need not be RFC uuids. For the purposes of a Pid, the UUID
			# will be generated based off a combination of the current time, a hash
			# of the initialization arguments, and a random element.
			def self.generate_uuid(*args)
				now = Time.now
				# Turn the time into a very large integer.
				time = (now.to_i * 10_000_000) + (now.tv_usec * 10) + Epoch

				# Now break that integer into three chunks.
				t1 = time & 0xFFFF_FFFF
				t2 = time >> 32
				t2 = t2 & 0xFFFF
				t3 = time >> 48
				t3 = t3 & 0b0000_1111_1111_1111
				t3 = t3 | 0b0001_0000_0000_0000

				time_string = TimeFormat % [t1,t2,t3]
				arg_string = Digest::SHA1.hexdigest(args.collect {|arg| arg.to_s}.sort.to_s)
				"#{time_string}-#{arg_string}-#{rand(RandHigh).to_s(16)}"
			end

			@invocation_callbacks = {}
			def self.invocation_callbacks
				@invocation_callbacks
			end

			attr_accessor :_receiver_address, :_rpc_uuid, :_receiver_em_signature
			attr_accessor :_receiver_bind_port, :_receiver_bind_server

			def initialize(*args, &block)
				@_rpc_uuid = Receiver::generate_uuid(*args)
				super(*args, &block)
			end

			def start_receiver(addr)
				raise "Already bound to #{_receiver_bind_address}." if _receiver_em_signature
				_receiver_bind_server, _receiver_bind_port = _parse_receiver_address(addr)
				_receiver_bind_address = _format_full_address(_receiver_bind_server, _receiver_bind_port)
				_receiver_em_signature = EventMachine.start_server(_receiver_bind_server, _receiver_bind_port, RPCProtocol, self)
			end

			def connect_to(addr, connected_callback = nil, disconnected_callback = nil, &block)
			end

		end
	end
end
