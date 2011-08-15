#prepare database for testing the server

begin
 Couchdb.create 'status_update_settings'
rescue CouchdbException => e
end

begin
 Couchdb.create 'monitors'
rescue CouchdbException => e
end

 #create sample config settings for testing
config = {   :every => '1m',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                  :tag => 'test' 
                  }
       doc = {:database => 'status_update_settings', :doc_id => 'test_config_settings', :data => config}
     begin
      Document.create doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end  


 #create sample monitor for testing
   data = { tag: 'trial_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h'
                  }

      doc = {:database => 'monitors', :doc_id => 'trial_monitor', :data => data}
     begin
      Document.create doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

 #create sample monitor for generating a test sample update 
   data = { tag: 'active_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h',
                   describe_test_result:  "sample monitor for specs",
        	   time_of_last_test: "2:30pm",
         	   num_tests_passed: "10",
         	   num_tests_failed: "20",
                   total_num_tests: "30",
                   last_test_result: "PASSED", 
                   status: "UP",
                   state: "stopped"
                  }

      doc = {:database => 'monitors', :doc_id => 'active_monitor', :data => data}
     begin
      Document.create doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

 #create sample monitor to be deleted
   data = { tag: 'to_be_deleted', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h'
                  }

      doc = {:database => 'monitors', :doc_id => 'to_be_deleted', :data => data}
     begin
      Document.create doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 
