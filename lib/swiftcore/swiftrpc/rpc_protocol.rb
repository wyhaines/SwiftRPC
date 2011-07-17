# This encapsulates the RPCserver protocol. It is a module that is intended
# to be used with EventMachine.

module Swiftcore
	module SwiftRPC
		module RPCProtocol

			def initialize(receiver)
				@receiver = receiver
				@__buffer = ''
				@transaction_log = {}
				super
			end

			# TODO: Insert an Ack into this protocol to make it more robust.
			def receive_data data
				@__buffer << data
				while @__buffer.length > 26
					if @__buffer =~ /^(\w{7}):([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/ && $2 == $3
						flavor = $1.intern
						len = $2.to_i(16)
						@__buffer.slice!(0,26)
						payload = @__buffer.slice!(0,len)

						case flavor
							when :msgpack
						    signature, meth, args = ::MessagePack.unpack(payload)
							else
						    signature, meth, args = Marshal.load(payload)
						end
						
						@transaction_log[signature] = [[EventMachine.current_time, :received]]
						begin
							response = @receiver.__send__(meth, *args)
						rescue Exception => e
							response = e
						end
						payload = [signature, response]
						if response.respond_to?(:to_msgpack)
							flavor = :msgpack
						else
						  flavor = :marshal
						end

						begin
							case flavor
								when :msgpack
							    payload = payload.to_msgpack
								else :marshal
							    payload = Marshal.dump(payload)
							end
						rescue NoMethodError
							flavor = :marshal
							payload = Marshal.dump(payload)
						end

						len = sprintf("%08x",payload.length)
						send_data("#{flavor}:#{len}:#{len}:#{payload}")

						@transaction_log.delete signature
						#@transaction_log[signature] << [EventMachine.current_time, :sent]
					else
						# The length and checksum isn't in the expected format, or do not match.
						# What should be done here?  Scan the whole buffer looking
						# for a match, or throw everything away? It may not be the prudent choice,
						# but for now going with the scan first approach.
						if (pos = @__buffer =~ /([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/) && $1 == $2
							@__buffer.slice!(0,pos)
							receive_data ''
						else
							# No matches in the whole thing. Throw it away!
							@__buffer = ''
						end
					end
				end
			end

		end
	end
end
