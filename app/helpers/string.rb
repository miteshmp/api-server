# Helper class : String
class String
    # Module :- is_i
    # Description :- verify that string contains only digit or not.
    def is_i?
       !!(self =~ /^[-+]?[0-9]+$/)
    end
    # Complete:- "is_i"
    
    # Module :- format_mac
    # Description :- Validate MAC address format
    def format_mac
      self.gsub(/[-:]/, '').upcase
    end
    # Complete method :- format_mac

    # Method :- is_mac
    # Description :- validate MAC address length
    def is_mac?
      self.length == 12
    end
    # Complete method :- is_mac

    # Method :- is_empty
    # Description :- Validate that string is empty or not.
    def is_empty?      
      return true unless self      
      return true if self.empty?
      #return true if self.strip!.empty?   # todo   
      return false ;
    end
    # Complete method :- is_empty

end
# Complete :- "String" Class