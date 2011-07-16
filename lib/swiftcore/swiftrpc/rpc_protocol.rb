# This encapsulates the RPCserver protocol. It is a module that is intended
# to be used with EventMachine.

module Swiftcore
	module SwiftRPC
		module RPCProtocol

			def initialize(*args)
				@__buffer = ''
				@transaction_log = {}
				super
			end

			# TODO: Insert an Ack into this protocol to make it more robust.
			def receive_data data
				@__buffer << data
				if @__buffer.length > 18
					if @__buffer =~ /^([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/ && $1 == $2
						len = $1.to_i(16)
						@__buffer.slice!(0,18)
						signature, meth, args = MessagePack.unpack(@__buffer.slice!(0,len))
						@transaction_log[signature] = [[EventMachine.current_time, :received]]
						response = __send__(meth, *args)
						payload = [signature, response].to_msgpack
						len = payload.length
						send_data("#{len}:#{len}:#{payload}")

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
			rescue Exception
				# Stuff blew up! Dang!
			end

		end
	end
end
