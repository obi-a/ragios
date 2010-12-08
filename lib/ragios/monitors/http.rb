
module Ragios
 module Monitors

# Monitors a domain to check if its online  
# It establishes a HTTP connection to the domain
# PASSED if it establishes the HTTP connection successfully and FAILED if it throws an exception
class HTTP < Ragios::Monitors::Service
  
   attr_reader :domain 
  
   def initialize
        raise "@domain must be assigned a value" if @domain.nil?
        @describe_test_result = "HTTP Connection to " + @domain
        super
   end 

   #connects to the domain via HTTP
   #PASSED when it establishes a successful HTTP connection with the domain
   def test_command
     begin 
           
          Net::HTTP.start(@domain) 
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
