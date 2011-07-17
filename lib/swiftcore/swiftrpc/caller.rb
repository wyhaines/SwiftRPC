# Every object which will make RPC calls is a Caller.
require 'eventmachine'
require 'swiftcore/swiftrpc/util'
require 'swiftcore/swiftrpc/proxy'

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
				conn.__proxy_connection.connected_callbacks block if block
				conn.__proxy_connection.connected_callbacks connected_callback if connected_callback
				conn.__proxy_connection.errback do
					# The connection failed before being established. Something should be done here.
					# A exception inside a callback has limited utility. There should probably be some
					# sort of limited retry logic, and some sort of indicator mechanism to show that
					# this connection failed.
				end

				conn._connecton.disconnected_callbacks disconnected_callback if disconnected_callback
				@_connections[label] = conn
			end

			def call_on(label, meth, *args, &block)
				conn = @_connections[label]
				raise "A connection for '#{label}' could not be found." unless conn

				conn.__send__(meth, *args, &block)
			end

		end
	end
end
