module Swiftcore
	module SwiftRPC
    module UtilityMixins
      # These are methods that may be mixed into more than once class.

      def _parse_receiver_address(addr)
				server, port = addr.split(/:/,2)
				port = port.to_i
				[server, port]
			end

			def _format_full_address(server, port)
				"#{server}:#{port}"
			end

    end
  end
end
