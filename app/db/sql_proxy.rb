

class SqlProxy < ::Makara::Proxy
  hijack_method :select, :ping
  send_to_all :connect, :reconnect, :disconnect, :clear_cache
  def connection_for(config)
    ::Sql::Client.new(config)
  end
end