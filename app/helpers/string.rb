
  class String
    def is_i?
       !!(self =~ /^[-+]?[0-9]+$/)
    end
    
    def format_mac
      self.gsub(/[-:]/, '').upcase
    end
    
    def is_mac?
      self.length == 12
    end

    def is_empty?      
      return true unless self      
      return true if self.empty?
      #return true if self.strip!.empty?   # todo   
      return false       
    end 
end
