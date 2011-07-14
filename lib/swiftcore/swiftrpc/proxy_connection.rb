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
      end

      def initialize(conn, *args)
        hash_args = Hash === args.first ? args.shift : {}
        @connected = false
        @address = hash_args[:address] || args[0]
        @port = hash_args[:port] || args[1]
        @idle = hash_args[:idle] || args[2] || 60
      end

      def post_init
        # Yay. A connection was established!
        succeed
      end

      def unbind
        case @deferred_status
          when :succeed
            # The connection was established successfully before disconnecting, so we can set the status to :disconnected now.
            disconnect
          when :unknown
            # The connection was never established. This is a failure state.
            failed
          else
            # How could unbind be called if the state is already :failed or :disconnected? Something bad....
        end
      end

      def connected_callbacks
        @callbacks ||= []
      end

      def disconnected_callbacks
        @disconnected_callbacks ||= []
      end

      def failed_callbacks
        @errbacks ||= []
      end

      def disconnectback &block
        return unless block
        @deferred_status ||= :unknown
        if @deferred_status == :disconnected
          block.call(*@deferred_args)
        elsif @deferred_status != :failed
          @disconnected_callbacks ||= []
          @disconnected_callbacks.unshift block # << block
        end
      end

      def set_deferred_status status, *args
        cancel_timeout
        @errbacks ||= nil
        @callbacks ||= nil
        @disconnected_callbacks ||= nil
        @deferred_status = status
        @deferred_args = args
        case @deferred_status
        when :succeeded
          if @callbacks
            while cb = @callbacks.pop
              cb.call(*@deferred_args)
            end
          end
          @errbacks.clear if @errbacks
        when :failed
          if @errbacks
            while eb = @errbacks.pop
              eb.call(*@deferred_args)
            end
          end
         @callbacks.clear if @callbacks
        when :disconnected
          if @disconnected_callbacks
            while dcb = @disconnected_callbacks.pop
              dcb.call(*@deferred_args)
            end
          end
        end
      end

      def disconnect *args
        set_deferred_status :succeeded, *args
      end
      alias set_deferred_disconnect disconnect

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
        # Create the data package and send it.
        signature = Swiftcore::Chord::UUID.generate(*([meth] + args))
        @invocation_callbacks[signature] = Fiber.current
        node.on_invocation(self, signature, meth, *args)
        Fiber.yield
      end
    end
  end
end
