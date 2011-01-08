module Ragios
 module Monitors

#monitors a URL by sending a http request to it
#PASSED if it gets a HTTP 200,301 or 302 Response status code from the http request
class URL < Ragios::Monitors::Service
  
   attr_reader :url 
  
   def initialize
        
        raise "A url to test must be specified, @url must be assigned a value" if @url.nil?    
        @describe_test_result = "HTTP Request to " + @url
        super
   end 

   #returns true when http request to url returns a 200 OK Response
   def test_command
     begin 
           response = Net::HTTP.get_response(URI.parse(url))
           @test_result = response.code
     
          if (response.code == "200") || (response.code == "301") || (response.code == "302")
               return TRUE
         else 
	          return FALSE
         end 
     
     rescue Exception
            @test_result =  $! # $! global variable reference to the Exception object
            return FALSE  
     end  
      
  end
   
end

 end
end
