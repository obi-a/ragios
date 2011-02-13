module Ragios 

#Translates the Ragios Domain Specific Language to the object oriented system

 class Monitor
   
    def initialize

    end

   def self.update_status config
      Ragios::System.update_status config 
   end

    def self.start monitoring
         monitor = []
         count = 0
    monitoring.each do|m|
       if m[:monitor] == 'http' 
          monitor[count] = MonitoringHTTP.new m
       elsif m[:monitor] == 'url'
         monitor[count] = MonitoringURL.new m
       elsif m[:monitor] == 'process'
         monitor[count] = MonitoringProcess.new m
       else
         raise '[:monitor] must be assigned a value'
       end
       count = count + 1
     end #end of each...do loop
    
    #also returns a list of active monitors     
    Ragios::System.start monitor
    end
 end

module Notifiers
  
   def notify
       if @notifier == 'email'
            email_notify
       elsif @notifier == 'gmail'
            gmail_notify
       elsif @notifier == 'twitter'
           tweet_notify
      else 
          raise 'Notifier is not set'
      end
   end

   def fixed 
     if @notifier == 'email'
            email_resolved
       elsif @notifier == 'gmail'
            gmail_resolved
       elsif @notifier == 'twitter'
            tweet_resolved
      else 
          raise 'Notifier is not set'
      end
   end

end


#Generic monitors
 class MonitoringHTTP < Ragios::Monitors::HTTP
         
   attr_reader :notifier 

   def initialize m  
          #translate values of the DSL to a Ragios::Monitors::HTTP object
          raise "[:monitor] != 'http'" if m[:monitor] != 'http'
          @time_interval = m[:every]
          @notification_interval = m[:notify_interval]
          @contact = m[:contact]
          @test_description = m[:test]
          @domain = m[:domain]
          @notifier = m[:via]
          super()
   end

  include Notifiers

 end

  
 class MonitoringURL < Ragios::Monitors::URL
   
   def initialize m
      #translate values of the DSL to a Ragios::Monitors::HTTP object
          raise "[:monitor] != 'url'" if m[:monitor] != 'url'
          @time_interval = m[:every]
          @notification_interval = m[:notify_interval]
          @contact = m[:contact]
          @test_description = m[:test]
          @url = m[:url]
          @notifier = m[:via]
          super()  
   end 
   
 include Notifiers
  
 end

 class MonitoringProcess < Ragios::Monitors::Process
   
   def initialize m
      #translate values of the DSL to a Ragios::Monitors::Process object
      raise "[:monitor] != 'process'" if m[:monitor] != 'process'
      @time_interval = m[:every]
      @notification_interval = m[:notify_interval]
      @contact = m[:contact]
      @test_description = m[:test]
      
      @process_name = m[:process_name]
      @start_command = m[:start_command]
      @restart_command = m[:restart_command]
      @stop_command = m[:stop_command]
      @pid_file = m[:pid_file]
     
      @server_alias = m[:server_alias]
      @hostname = m[:hostname]
      
      @notifier = m[:via]
      super()
    
   end
   
  include Notifiers
  
 end

end

