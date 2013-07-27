module Ragios
#log activity of monitors

 class Logger

  def self.config(log_activity)
    @@log_activity = log_activity
  end

  def write(monitor)
      data = {   
         :monitor_id => monitor.id,
         :timestamp => monitor.timestamp.to_s,
         :describe_test_result => monitor.describe_test_result, 
         :time_of_test => monitor.time_of_last_test.to_s,
         :test_result => monitor.test_result.to_s, 
         :status => monitor.status,
         :tag => monitor.tag,
         :day => Date.today.strftime("%d"), 
         :month => Date.today.strftime("%B"), 
         :year => Date.today.strftime("%Y")
              }
       doc = { :database => 'ragios_activity_log', :doc_id => UUIDTools::UUID.random_create.to_s, :data => data}   
       Couchdb.create_doc doc,Ragios::DatabaseAdmin.session    
  end 

  def log(monitor)
   if @@log_activity == true
     write monitor
   end
  end

 end
end
