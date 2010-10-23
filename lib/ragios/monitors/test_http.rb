
module Ragios
 module Monitors

# Tests a domain to check if its online  
# It establishes a HTTP connection to the domain
# PASSED if it establishes the HTTP connection successfully and FAILED if it throws an exception
class TestHTTP < Ragios::Monitors::ServiceMonitor
  
   attr_reader :test_domain 
  
   def initialize
        @describe_test_result = "HTTP Connection to " + @test_domain
        super
   end 

   #connects to the test_domain via HTTP
   #PASSED when it establishes a successful HTTP connection with the test_domain
   def test_command
     begin 
           
          Net::HTTP.start(@test_domain) 
          @test_result = 'PASSED'
          return TRUE 

     rescue Exception
            @test_result =  $! # $! global variable reference to the Exception object
            return FALSE  
     end  
      
  end
   
end

 end
end
