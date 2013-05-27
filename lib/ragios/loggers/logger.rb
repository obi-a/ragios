module Ragios
#log activity of monitors

 class Logger

  def self.config(log_activity)
    @@log_activity = log_activity
  end

  def write(monitor)
    
  end 

  def log(monitor)
   if @@log_activity == true
     write monitor
   end
  end

 end

end
