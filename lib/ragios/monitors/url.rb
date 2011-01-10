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

   #returns true when http/https request to url returns a 200 OK Response
   def test_command
     begin 
           
           uri = URI.parse(url)
	   http = Net::HTTP.new(uri.host, uri.port)
           http.use_ssl = true if uri.scheme == 'https'

          http.open_timeout = 20 # in seconds
          http.read_timeout = 20 # in seconds

          request = Net::HTTP::Get.new(uri.request_uri)
          request["User-Agent"] = "Ragios (Saint-Ruby)"
          request["Accept"] = "*/*"
          
          response = http.request(request)
           
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
