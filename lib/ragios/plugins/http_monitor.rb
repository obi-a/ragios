# Plugin: Monitors a domain to check if its online  
# It establishes a HTTP connection to the domain
# test PASSES if it establishes the HTTP connection successfully and FAILS if it throws an exception

module Ragios
	module Plugin

		class HttpMonitor 
   		attr_reader :domain 
   		attr_accessor :test_result

   		def init(options)
        @domain = options[:domain] 
        raise "domain must be assigned a value" if @domain.nil?
        @describe_test_result = "HTTP Connection to " + @domain     
   		end 

   		def test_command
     		begin  
          Net::HTTP.start(@domain) 
          @test_result = {"HTTP Connection to #{@domain}" => "Successful"}
          return true 
     		rescue Exception
          @test_result =  {"HTTP Connection to #{@domain}" => $!} # $! global variable reference to the Exception object
          return true  
     		end      
   		end   
		end

	end
end

