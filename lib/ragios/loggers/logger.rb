module Ragios
#log activity of monitors

 class Logger

  def self.config(log_activity)
    @@log_activity = log_activity
  end

  def write(monitor)
      data = {   
         :monitor_id => monitor.id,
         :test_description => monitor.test_description,
         :timestamp => monitor.timestamp.to_s,
         :describe_test_result => monitor.describe_test_result, 
         :time_of_test => monitor.time_of_last_test.to_s,
         :test_result => monitor.test_result.to_s, 
         :status => monitor.status,
         :tag => monitor.tag + Date.today.strftime("%B") + Date.today.strftime("%Y")
              }
       doc = { :database => data[:monitor_id], :doc_id => data[:timestamp], :data => data}   
       Couchdb.create_doc doc,Ragios::DatabaseAdmin.session    
  end 

  def log(monitor)
   if @@log_activity == true
     write monitor
   end
  end

 end
end
