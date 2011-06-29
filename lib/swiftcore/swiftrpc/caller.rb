# Every object which will make RPC calls is a Caller.
require 'eventmachine'
require 'swiftcore/swiftrpc/util'

module Swiftcore
	module SwiftRPC
		module Caller

      include UtilityMixins

			attr_accessor :_receiver_address, :_rpc_uuid, :_receiver_em_signature
			attr_accessor :_receiver_bind_port, :_receiver_bind_server, :_connections

			def initialize(*args, &block)
				@_rpc_uuid ||= generate_uuid(*args)
        @_connections = {}
				super(*args, &block)
			end

			def connect_to(addr, label = nil, connected_callback = nil, disconnected_callback = nil, idle = 60,  &block)
        server, port = _parse_address(addr)
        label ||= addr
        conn = Proxy.new(server, port, idle)
        conn._connected_callback << connected_callback if connected_callback
        conn._disconnected_callback << block if block
        conn._disconnected_callback << disconnected_callback if disconnected_callback
        @_connections[label] = conn
			end

      def call_on(label, meth, *args)
        conn = @_connections[label]
        raise "A connection for '#{label}' could not be found." unless conn

        conn.__send__(meth, *args)
      end
      
		end
	end
end