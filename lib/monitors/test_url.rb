require 'net/http'
require 'lib/monitors/service_monitor'

#monitors a webpage to check if the site is loading
#PASSED if it gets a HTTP 200,301 or 302 Response status code from the http request
class TestURL < ServiceMonitor
  
   attr_reader :test_url 
  
   def initialize
        @describe_test_result = "HTTP Request to " + @test_url
        super
   end 

   #returns true when http request to test_url returns a 200 OK Response
   def test_command
     begin 
           response = Net::HTTP.get_response(URI.parse(test_url))
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
