module Ragios 

#Translates the Ragios Domain Specific Language to the object oriented system

 class Monitor
   
    def initialize

    end

    def self.start (monitoring, trap_exit = TRUE)
         monitoring_objects = []
         count = 0
    monitoring.each do|m|
       if m[:monitor] == 'http' 
          monitoring_objects[count] = MonitoringHTTP.new m
       elsif m[:monitor] == 'url'
         monitoring_objects[count] = MonitoringURL.new m
       elsif m[:monitor] == 'process'
         monitoring_objects[count] = MonitoringProcess.new m
       else
         raise '[:monitor] must be assigned a value'
       end
       count = count + 1
     end #end of each...do loop
         
    Ragios::System.start monitoring_objects,trap_exit  
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


#Generic monitoring objects 
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

