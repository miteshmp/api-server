# Class Name :- ThreadUtility
# Description :- According to Rails Doc 'with_connection' method will Check-In 
# the connection back to connection pool once after executing the Block given. 
# But in the above example, it's not  releasing the connection rather 
# it holds as active connection. So further requests to server keep creating new 
# connections, this strange behaviour is the root cause of connection leak issue.

class ThreadUtility

  # Module :- with_connection
  def self.with_connection(&block)

    begin
      # take explictit connection from connection pool
      ActiveRecord::Base.connection_pool.with_connection do
      
        yield block
      
      end
      # active_connection

      rescue Exception => exception
        Rails.logger.error("ThreadUtility :-  #{exception.message}");
    
      ensure
        # Check the connection back in to the connection pool
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
        ActiveRecord::Base.clear_active_connections! ;
    end
    # end of "begin"

  end
  # completed :- "with_connection"

end