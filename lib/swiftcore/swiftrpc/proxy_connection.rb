# This encapsulates the actual proxy connection. It is a module that is intended
# to be used with EventMachine.

module Swiftcore
	module SwiftRPC
    module ProxyConnection

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

    end
  end
end
