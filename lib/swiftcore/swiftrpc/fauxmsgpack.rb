# This fakes a MessagePack-like API with Marshal, in case MessagePack is unavailable.
class Object
	def to_msgpack
		Marshal.dump(self)
	end
end

class MessagePack
	def self.unpack(msg)
		Marshal.load(msg)
	end
end