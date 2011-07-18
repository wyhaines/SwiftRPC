require 'digest/sha1'

module Swiftcore
	module SwiftRPC
		module UtilityMixins
			# These are methods that may be mixed into more than once class.

			Epoch = 0x01B21DD213814000
			TimeFormat = "%08x-%04x-%04x"
			RandHigh = 1 << 128

			# The UUIDs need not be RFC uuids. For the purposes of a Pid, the UUID
			# will be generated based off a combination of the current time, a hash
			# of the initialization arguments, and a random element.
			def generate_uuid(*args)
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
				arg_string = Digest::SHA1.hexdigest(args.collect {|arg| Proxy === arg ? arg.object_id.to_s : arg.to_s}.sort.to_s)
				"#{time_string}-#{arg_string}-#{rand(RandHigh).to_s(16)}"
			end

			def _parse_address(addr)
				server, port = addr.split(/:/,2)
				server = '127.0.0.1' if server.empty?
				port = port.to_i
				[server, port]
			end

			def _format_full_address(server, port)
				"#{server}:#{port}"
			end

		end
	end
end
