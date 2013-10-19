#Plugin: Monitors a URL by sending a http GET request to it
#the test PASSES if it gets a HTTP 200,301 or 302 Response status code from the http request
module Ragios
	module Plugin
	
		class UrlMonitor
  		attr_accessor :test_result
  		attr_reader :url 
  
  		def init(options)
      	@url = options[:url] 
      	raise "A url to test must be specified, url must be assigned a value" if @url.nil?    
  		end
  
  		def test_command
    		begin
     			response = RestClient.get @url, {"User-Agent" => "Ragios (Saint-Ruby)"}
     			@test_result = {"HTTP GET Request to #{@url}" => response.code}
     			return true
   			rescue => e
     			@test_result = {"HTTP GET Request to #{@url}" => e.message }
     			return false
   			end
  		end
		end

	end
end


