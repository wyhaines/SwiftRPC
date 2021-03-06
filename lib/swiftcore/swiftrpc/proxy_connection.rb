require 'em/deferrable'
require 'swiftcore/swiftrpc/do_proxy'
require 'socket'

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
				conn.comm_inactivity_timeout = idle
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

			def notify_of_finalization(finalization_signature, uuid)
				invoke_on(nil, finalization_signature, :__proxy_is_finalized, uuid)
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

			def invoke_on(proxy, signature, meth, *args)
				@return_map[signature] = proxy
				payload = [signature, meth, args]
				flavor = args.all? { |a| a.respond_to?(:to_msgpack) } ? :msgpack : :marshal
				begin
					case flavor
						when :msgpack
					    payload = payload.to_msgpack
						else
					    payload = Marshal.dump(payload)
					end
				rescue NoMethodError
					flavor = :marshal
					payload = Marshal.dump(payload)
				end

				len = sprintf("%08x",payload.length)
				send_data("#{flavor}:#{len}:#{len}:#{payload}")
			end

			def receive_data data
				@buffer << data
				while @buffer.length > 26
					if @buffer =~ /^(\w{7}):([0-9a-fA-F]{8}):([0-9a-fA-F]{8}):/ && $2 == $3
						flavor = $1.intern
						len = $2.to_i(16)
						@buffer.slice!(0,26)
						data = @buffer.slice!(0,len)

						case flavor
							when :msgpack
						    signature, response = ::MessagePack.unpack(data)
							else
						    signature, response = Marshal.load(data)
						end

						if DoProxy === response
							port, addr = Socket::unpack_sockaddr_in(self.get_peername)
							uuid = response.uuid
							response = Proxy.new(addr, port, self.comm_inactivity_timeout, uuid)
						end

						proxy = @return_map.delete(signature)
						proxy.__handle_response(signature, response) if proxy
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
