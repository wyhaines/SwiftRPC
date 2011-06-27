require 'rubygems'
begin
  require 'msgpack'
rescue LoadError
  # If Msgpack isn't available, fall back to Marshal, but with a Msgpack-like API
  require 'swiftcore/swiftrpc/fauxmsgpack'
end
require 'swiftcore/swiftrpc/receiver'
