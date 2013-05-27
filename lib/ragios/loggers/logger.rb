module Ragios
#log activity of monitors

 class Logger

  def self.config(log_activity)
    @@log_activity = log_activity
  end

  def write(monitor)
    #update document with test information       
      data = {   
         :test => monitor.test,
         :timestamp => monitor.timestamp,
         :test_result => monitor.describe_test_result, 
         :time_of_test => monitor.time_of_last_test.to_s,
         :test_result => monitor.test_result.to_s, 
         :status => monitor.status,
         :tag => monitor.tag + Date.today.strftime("%B") + Date.today.strftime("%Y")
              }
       id = "_" + monitor.id
       doc = { :database => id, :doc_id => monitor.timestamp, :data => data}   
       Couchdb.update_doc doc,Ragios::DatabaseAdmin.session    
  end 

  def log(monitor)
   if @@log_activity == true
     write monitor
   end
  end

 end
end
