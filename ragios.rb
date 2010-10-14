#!/usr/bin/ruby
#Title   :Ragios (aka St. Ruby)
#Date    :10/13/2010
#Author  :Obi Akubue
#Version :0.3.3
#description: This is the framework for a Ruby Based System and Network Monitoring Tool
#this project is just an excuse to play with ruby and linux servers
 

require 'net/http'
require 'rubygems'
require 'pony'
require 'twitter'
require 'rufus/scheduler'

#
class Ragios
    
    attr :jobs

    def initialize(jobs)
         @jobs = jobs  
    end

   def init
       	puts "Welcome to Ragios"
       	puts "Initializing"

	count = 1
	puts @jobs.length.to_s + " jobs detected"
	puts "\n"

	@jobs.each do |job|
 		puts "Job " + count.to_s + ". "+  job.test_description 
 		puts "Scheduled to run every " + job.time_interval + "\n"
 		puts "Running First Test..."
	begin 
 	  if job.test_command
           puts  "  [PASSED]" + " Created on: "+ Time.now.to_s 
           puts job.describe_test_result + " = " + job.test_result 
  	  else
           puts "  [FAILED]" + " Created on: "+ Time.now.to_s 
           puts job.describe_test_result + " = " + job.test_result 
           job.failed
      
  	  end
   	   puts "\n"
	rescue Exception
   	   puts "ERROR: " +  $!  + " Created on: "+ Time.now.to_s 
           job.error_handler
        end
       count = count + 1
       end  
   end 
    
   
 def start
    
   #schedule all the jobs to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new
   @jobs.each do |job|
    scheduler.every job.time_interval do
     begin  
       if job.test_command
           puts job.test_description + "   [PASSED]" + " Created on: "+ Time.now.to_s
       else
           puts job.test_description +   "   [FAILED]" + " Created on: "+ Time.now.to_s
           job.failed
       end
       #catch all exceptions
      rescue Exception
          puts "ERROR: " +  $!  + " Created on: "+ Time.now.to_s 
          job.error_handler
      end
     end #end of scheduler
    end       
  end

end


#this class hides the messy details of tweeting from rest of the system
class Tweet

  def initialize 
      oauth = Twitter::OAuth.new('Consumer Key', 'Consumer secret')
      oauth.authorize_from_access('access token', 'access secret')     
          
       @client = Twitter::Base.new(oauth) 
  end
 
 def tweet message
      
      @client.update(message)    
 end

end

#base class that defines the behavior of all system monitors
class SystemMonitor

    # a short description of the test performed by this system monitor
   attr_reader :test_description  
   
   #hostname of the system being monitored
   attr_reader :hostname 

   #ip address of the system being monitored   
   attr_reader :address   
   
   #email address of admin to contact when a test fails
   attr_reader :contact   
   
   #results of a test
   attr_reader :test_result 
  
    #describes the test result, this gives technical details on the test_result
    #This gives the sysadmin info on the technical details of the test results
    attr_reader :describe_test_result
    
    #Time interval to run a test on the system, the test is defined on test_command()
    #Time interval can be expressed in minutes,seconds,hours or combinations of either
    #example 3m = 3 minutes, 10s = 10 seconds, 5h = 5 hours, 4h30m = 4 hours 30 minutes
    # @time_interval = 3m means that the SystemMonitor runs the test every 3minutes
    attr_reader :time_interval
  
   def initialize 
   end
  
   #defines the tests to run on a system
   def test_command
   end
   
   #defines the action to take when a test fails 
   #- May send email, SMS or tweet to the system admin
   #- May also take action to fix the issue like restart a process/service 
   def failed
       #tweet_alert 
       #email_alert
   end
   
  def tweet_alert
     
     message = @test_description + " FAILED!  " + @describe_test_result + " = " + @test_result + " Created on: "+ Time.now.to_s

     Tweet.new.tweet message.slice!(0..139) #maintaining the twitter 140 character limit with slice!
  end


   def email_alert
   
       puts 'sending mail alert...'
       Pony.mail :to => @contact, 
                 :subject => @test_description + " FAILED", 
                 :body => @test_description + " FAILED \n\n" + @describe_test_result + " = " + @test_result +  "\n\n Created on: " + Time.now.to_s
       
      
   end
   
   #this method is invoked when a test_command() or failed() method encounters an exception
   #The aim is to inform the system Admin about the exception while the system keeps on running
   def error_handler
       tweet_error
   end
   
   #informs a system admin via twitter when a test_command() or failed() method encounters an excepion
   def tweet_error
        message = @test_description + " ERROR: " + $!  + " Created on: "+ Time.now.to_s 
        Tweet.new.tweet message.slice!(0..139) #140 character limit on twitter
   end
   
   #informs a system admin via email when a test_command() or failed() method encounters an excepion
   def email_error
       #not yet implemented
   end
     
end

#defines how computers,servers,network devices will be monitored
class Host < SystemMonitor
    def initialize
     super
    end
    
end

#defines how services will be monitored
class Service < SystemMonitor
    def initialize
     super
    end
end


#monitors a webpage to check if the site is loading
#PASSED if it gets a HTTP 200 Response status code from the website
class TestHttp < Service
  
   attr_reader :test_url 
  
   def initialize
        @contact = "obi@mail.com"
        @describe_test_result = "HTTP Request to " + @test_url
        super
        @time_interval = '1h'
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

class TestMySite < TestHttp   
   def initialize
      @test_description  = "My Website Test"
      @test_url = "http://www.whisperservers.com"  
      super
   end
end

class TestMyBlog < TestHttp 
#tests my blog, to check if the blog is loading

   def initialize
      @test_description  = "My Blog Test"
      @test_url = "http://obi-akubue.homeunix.org/"
      super
   end
end

class TestFakeSite < TestHttp   
#tests a website that doesn't exist this test will always fail
   def initialize
      @test_description  = "Fake website"
      @test_url = "http://wenosee.org/"
      super
   end
end
  

tests = [ TestMySite.new, TestMyBlog.new, TestFakeSite.new]

ragios = Ragios.new tests 
ragios.init
ragios.start

#trap Ctrl-C to exit gracefully
puts "PRESS CTRL-C to QUIT"
  loop do
  trap("INT") { puts "\nExiting"; exit; }
    sleep(3)
  end
