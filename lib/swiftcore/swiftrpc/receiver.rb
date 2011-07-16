# Every valid target for RPC is a Receiver.
require 'eventmachine'
require 'swiftcore/swiftrpc/util'
require 'swiftcore/swiftrpc/rpc_protocol'

module Swiftcore
	module SwiftRPC
		module Receiver

			include UtilityMixins

			@invocation_callbacks = {}
			def self.invocation_callbacks
				@invocation_callbacks
			end

			attr_accessor :_receiver_bind_address, :_rpc_uuid, :_receiver_em_signature
			attr_accessor :_receiver_bind_port, :_receiver_bind_server

			def initialize(*args, &block)
				@_rpc_uuid ||= generate_uuid(*args)
				super(*args, &block)
			end

			def start_receiver(addr)
				raise "Already bound to #{_receiver_bind_address}." if _receiver_em_signature
				_receiver_bind_server, _receiver_bind_port = _parse_address(addr)
				self._receiver_bind_address = _format_full_address(_receiver_bind_server, _receiver_bind_port)
				self._receiver_em_signature = EventMachine.start_server(_receiver_bind_server, _receiver_bind_port, RPCProtocol, self)
			end

		end
	end
end
