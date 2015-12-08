class HashSerializer
  # Called to deserialize data to ruby object.
  def load(data)
    require 'json'
    JSON.parse(data) if data
  end

  # Called to convert from ruby object to serialized data.
  def dump(obj)
    obj.to_json if obj
  end
end