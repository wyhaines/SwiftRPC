# This fakes a MessagePack-like API with Marshal, in case MessagePack is unavailable.
class Object
  def to_msgpack
    Marshal.dump(self)
  end
end