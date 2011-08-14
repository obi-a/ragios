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
   data = { tag: 'test', 
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
