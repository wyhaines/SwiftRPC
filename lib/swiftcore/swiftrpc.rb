require 'rubygems'
begin
  require 'msgpack'
rescue LoadError
  # If Msgpack isn't available, fall back to Marshal, but with a Msgpack-like API
  require 'swiftcore/swiftrpc/fauxmsgpack'
end
require 'swiftcore/swiftrpc/receiver'

module Swiftcore
	module SwiftRPC
    def self.fibers?
      @fibers || false
    end

    def self.fibers=(val)
      @fibers = val ? true : false
      require 'fiber' if @fibers
    end
  end
end
