module Ragios
#log activity of monitors

 class Logger

  def self.config(log_activity)
    @log_activity = log_activity
  end

  def self.write(monitor)
      data = {   
         :monitor_id => monitor.id,
         :timestamp => monitor.timestamp.to_s,
         :describe_test_result => monitor.describe_test_result, 
         :time_of_test => monitor.time_of_last_test.to_s,
         :test_result => monitor.test_result.to_s, 
         :status => monitor.status,
         :day => Date.today.strftime("%d"), 
         :month => Date.today.strftime("%B"), 
         :year => Date.today.strftime("%Y")
              }
      data.merge(:tag => monitor.tag) if defined? monitor.tag

       doc = { :database => Ragios::DatabaseAdmin.activity_log, :doc_id => UUIDTools::UUID.random_create.to_s, :data => data}   
       Couchdb.create_doc doc,Ragios::DatabaseAdmin.session    
  end 

  def self.activity_log
    @log_activity
  end

  def self.log(monitor)
   if @log_activity == true
     write monitor
   end
  end

 end
end
