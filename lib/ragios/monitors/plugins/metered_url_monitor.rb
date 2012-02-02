module Monitors

#Plugin: Monitors a URL by sending a http GET request to it
#PASSED if it gets a HTTP 200,301 or 302 Response status code from the http request
class MeteredUrlMonitor

  attr_accessor :describe_test_result 
  attr_accessor :test_result
  attr_reader :url 
  
  def init(options)
      @url = options[:url] 
      raise "A url to test must be specified, url must be assigned a value" if @url.nil?    
      @describe_test_result = "HTTP GET Request to " + @url
  end
  
  def test_command
    begin
     response = RestClient.get @url, {"User-Agent" => "Ragios (Saint-Ruby)"}
     @test_result = response.code
     return TRUE
   rescue => e
     @test_result = e.message
     return FALSE
   end
  end
end

end


