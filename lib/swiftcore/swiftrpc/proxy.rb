# A Proxy object stands in for a remote receiver object, allowing one to make
# RPC calls to it as if it were local.
#
# A Proxy knows how to connect to it's object. It will idle time out
# connections -- if there is no activity between the proxy and its object for
# some period of time, it will close the connection.
#
# A proxy passes almost all method calls on it through to it's receiver.
#
# Any object which is a Receiver, if it would be returned as the result of an
# RPC call, will return a Proxy instead.

require 'swiftcore/swiftrpc/blankslate'
require 'swiftcore/swiftrpc/util'

module Swiftcore
	module SwiftRPC
		class Proxy < BlankSlate

      attr_reader :connected_callbacks, :disconnected_callbacks
      
      include UtilityMixins

			def initialize(address, port, idle = 60)
        @__address = address
        @__port = port
        @__idle = idle
        @__connected_callbacks = []
        @__disconnected_callbacks = []
        @__invocation_callbacks = {}
        @__invocation_timestamps = {}
        __p_make_connection
      end

      def __connection
        @__proxy_connection
      end

      def __p_make_connection
        @__proxy_connection = ProxyConnection.make_connection(@address, @port, @idle)
      end

      def _p_connected?
        @__proxy_connection && @__proxy_connection.connected?
      end

			def method_missing(meth, *args)
        if __p_connected?
          @__proxy_connection.__initiate_invocation(meth, *args)
        else
          __p_make_connection
          @__proxy_connection.callback do
            @__proxy_connection.__initiate_invocation(meth, *args)
          end
        end
      end

      def __initiate_invocation(meth, *args)
        signature = Swiftcore::Chord::UUID.generate(*([meth] + args))
        @__invocation_callbacks[signature] = Fiber.current
        @__invocation_timestamps[signature] = [EM.current_time, @__proxy_connection]
        @__proxy_connection.invoke_on(self, signature, meth, *args)
        Fiber.yield if SwiftRPC.fibers?
      end

      def __handle_response(signature, response)
        @__invocation_timestamps.delete(signature)
        @__invocation_callbacks.delete(signature).resume(response) if @__invocation_callbacks.has_key?(signature)
      end
		end
	end
end
