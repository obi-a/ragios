 #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"

  require 'lib/ragios'

  class MonitorMySite < Ragios::Monitors::HTTP
    def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "Http connection to my blog"
      @domain = "obi-akubue.org"
      super
    end

    def notify
      email_notify
      #gmail_notify
      #tweet_notify
    end

  end

  class MonitorBlogURL <  Ragios::Monitors::URL
    def initialize
      @time_interval = '20m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "My Website Test"
      @url = "http://www.whisperservers.com/blog/"
      super
    end

   def notify
     email_notify
     #gmail_notify
     #tweet_notify
   end

  end

  monitoring = [MonitorMySite.new, MonitorBlogURL.new]
  
  ragios = Ragios::System.new 
  ragios.start monitoring



 
