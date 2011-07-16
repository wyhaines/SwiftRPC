require 'em/deferrable'

# This encapsulates the actual proxy connection. It is a module that is intended
# to be used with EventMachine.

module Swiftcore
	module SwiftRPC
		module ProxyConnection
			include EventMachine::Deferrable

			def self.make_connection(*args, &block)
				hash_args = Hash === args.first ? args.shift : {}
				address = hash_args[:address] || args[0]
				port = hash_args[:port] || args[1]
				idle = hash_args[:idle] || args[2] || 60
				conn = EventMachine.connect(address, port, ProxyConnection)
			  conn.set_comm_inactivity_timeout(idle)
			  conn
			end

			def initialize(*args)
				@return_map = {}
				@buffer = ''
			  super
			end

			def cb
				@callbacks
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

			def connected_callbacks block
        return unless block
        @deferred_status ||= :unknown
        if @deferred_status == :succeeded
          block.call(*@deferred_args)
        elsif @deferred_status != :failed
          @callbacks ||= []
          @callbacks.unshift block # << block
        end
			end

			def disconnected_callbacks block
				return unless block
				@deferred_status ||= :unknown
				if @deferred_status == :disconnected
					block.call(*@deferred_args)
				elsif @deferred_status != :failed
					@disconnected_callbacks ||= []
					@disconnected_callbacks.unshift block # << block
				end
			end

			def failed_callbacks block
        return unless block
        @deferred_status ||= :unknown
        if @deferred_status == :failed
          block.call(*@deferred_args)
        elsif @deferred_status != :succeeded
          @errbacks ||= []
          @errbacks.unshift block # << block
        end
			end

			def callback &block
				connected_callbacks block
			end

			def errback &block
				failed_callbacks block
			end
			
			def disconnectback &block
				disconnected_callbacks block
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

			def invoke_on(proxy, signature, meth, *args)
				@return_map[signature] = proxy
				payload = [signature, meth, args].to_msgpack
				len = sprintf("%08x",payload.length)
				send_data("#{len}:#{len}:#{payload}")
			end

			def receive_data data
				@buffer << data
				if @buffer.length > 18
					if @buffer =~ /^([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/ && $1 == $2
						len = $1.to_i(16)
						@buffer.slice!(0,18)
						signature, response = ::MessagePack.unpack(@buffer.slice!(0,len))
						proxy = @return_map.delete(signature)
						proxy.__handle_response(signature, response)
					else
						# The length and checksum isn't in the expected format, or do not match.
						# What should be done here?  Scan the whole buffer looking
						# for a match, or throw everything away? It may not be the prudent choice,
						# but for now going with the scan first approach.
						if (pos = @buffer =~ /([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/) && $1 == $2
							@buffer.slice!(0,pos)
							receive_data ''
						else
							# No matches in the whole thing. Throw it away!
							@buffer = ''
						end
					end
				end
			rescue Exception =>e
				puts e, e.backtrace.inspect
				# Stuff blew up! Dang!
			end
		end
	end
end
