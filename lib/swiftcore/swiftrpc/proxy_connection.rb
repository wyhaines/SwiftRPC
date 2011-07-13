require 'em/deferrable
'
# This encapsulates the actual proxy connection. It is a module that is intended
# to be used with EventMachine.

module Swiftcore
	module SwiftRPC
    module ProxyConnection
      include EventMachine::Deferrable

      def self.make_connection(*args, &block)
        conn = EventMachine.connect(@address, @port, ProxyConnection, @idle)
        conn.connected_callback
      end

      def initialize(conn, *args)
        hash_args = Hash === args.first ? args.shift : {}
        @connected = false
        @address = hash_args[:address] || args[0]
        @port = hash_args[:port] || args[1]
        @idle = hash_args[:idle] || args[2] || 60
      end

      def connection_completed
        comm_inactivity_timeout = @idle
        @connected = true
      end

      def unbind
        @connected = false
      end

      def connected?
        @connected
      end

      def invoke(meth, *args)
        
      end
    end
  end
end
