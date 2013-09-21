#prepare database for testing the server
database_admin = Ragios::DatabaseAdmin.admin

hash = Couchdb.login(username = database_admin[:username], password = database_admin[:password]) 
auth_session =  hash["AuthSession"]

begin
 Couchdb.create Ragios::DatabaseAdmin.monitors,auth_session
rescue CouchdbException => e
end

 #create sample monitor for testing
   data = { tag: 'trial_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h'
                  }

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'trial_monitor', :data => data}
     begin
      Couchdb.create_doc doc,auth_session
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
                   via: 'gmail_notifier',  
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

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'active_monitor', :data => data}
     begin
      Couchdb.create_doc doc,auth_session
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
                   via: 'gmail_notifier',  
                   notify_interval:'3h'
                  }

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'to_be_deleted', :data => data}
     begin
      Couchdb.create_doc doc,auth_session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 


class Monitor1 < Ragios::Monitors::System
  attr_accessor :id
  attr_reader :options

   def initialize

      @options = { tag: 'test',
                 monitor: 'url',
                   every: '87m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h',
                   _id: 'runtime_id'
                    }
         @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]
   end 
end


class Monitor2 < Ragios::Monitors::System
 attr_accessor :id
 attr_reader :options
   def initialize
      @options = { tag: 'test', 
                   monitor: 'url',
                   every: '88m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h',
                   _id: 'runtime_id'
                  }
        @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]
        
      
   end 
end
