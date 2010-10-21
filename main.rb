require 'rubygems'
require "bundler/setup"

require 'lib/monitors/test_http'
require 'lib/monitors/test_url'
require 'lib/schedulers/ragios'

class TestMySite < TestURL    
   def initialize
      @time_interval = '1h'
      @notification_interval = '6h'
      @contact = "obi@mail.com"	
      @test_description  = "My Website Test"
      @test_url = "http://www.whisperservers.com"  
      super
   end
end

class TestFakeSite < TestURL   
#tests a website that doesn't exist this test will always fail
   def initialize
      @time_interval = '1h'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "Fake website"
      @test_url = "http://wenosee.org/"
      super
   end
end
  
class TestMyBlog < TestHTTP
   def initialize
      @time_interval = '15s'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "Http connection to my blog"
      @test_domain = "obi-akubue.homeunix.org"
      super
   end
end


tests = [ TestMySite.new, TestMyBlog.new, TestFakeSite.new]

ragios = Ragios.new tests 
ragios.init
ragios.start
