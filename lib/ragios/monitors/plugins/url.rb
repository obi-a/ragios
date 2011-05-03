module Monitors

#code gets rid of SSL warning
#warning: peer certificate won't be verified in this SSL session
class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

#monitors a URL by sending a http request to it
#PASSED if it gets a HTTP 200,301 or 302 Response status code from the http request
class Url

  attr_accessor :describe_test_result 
  attr_accessor :test_result
  attr_reader :url 
  
  
  def init(options)
      @url = options[:url] 
      raise "A url to test must be specified, @url must be assigned a value" if @url.nil?    
      @describe_test_result = "HTTP Request to " + @url
  end
  
  def test_command
     begin 
           uri = URI.parse(@url)
	   http = Net::HTTP.new(uri.host, uri.port)
           http.use_ssl = true if uri.scheme == 'https'

          http.open_timeout = 45 # in seconds
          http.read_timeout = 45 # in seconds
                   
          #we choose to skip cert verification since we are simply checking if the URL is up or down
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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


