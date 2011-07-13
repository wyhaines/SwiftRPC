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

      include UtilityMixins

			def initialize(address, port, idle = 60)
        @address = address
        @port = port
        @idle = idle
        _p_make_connection
      end

      def _p_make_connection
        @proxy_connection = ProxyConnection.make_connection(@address, @port, @idle) do |conn|
          @proxy_connection = conn
          yield conn if block_given?
        end
      end

      def _p_connected?
        @proxy_connection && @proxy_connection.connected?
      end

			def method_missing(meth, *args)
        _p_make_connection unless _p_connected?
        @proxy_connection.invoke(meth, *args)
			end
		end
	end
end
