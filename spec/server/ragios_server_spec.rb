require 'spec_base.rb'
require 'set_server_test_values.rb'

Ragios::Server.init


describe "monitors" do
 it "should return security object of monitors database" do
    database_admin = Ragios::DatabaseAdmin.admin
    hash = Couchdb.get_security(Ragios::DatabaseAdmin.monitors,Ragios::DatabaseAdmin.session)
    admins = hash["admins"]
    readers = hash["readers"]
    admins["names"].should == [database_admin[:username]]
    admins["roles"].should == ["admin"]
    readers["names"].should == [database_admin[:username]]
    readers["roles"].should == ["admin"]
 end
end
 
describe "status updates" do
 it "should return security object of status updates database" do
    database_admin = Ragios::DatabaseAdmin.admin
    hash = Couchdb.get_security(Ragios::DatabaseAdmin.monitors,Ragios::DatabaseAdmin.session)
    admins = hash["admins"]
    readers = hash["readers"]
    admins["names"].should == [database_admin[:username]]
    admins["roles"].should == ["admin"]
    readers["names"].should == [database_admin[:username]]
    readers["roles"].should == ["admin"]
 end
end


describe Ragios::Server do

       
  it "should find monitors by tag" do
     monitors = Ragios::Server.find_monitors(:tag => 'trial_monitor')
     hash = monitors[0]
     hash["_id"].should == "trial_monitor"
  end

 it "should find status update by tag" do  
     monitors = Ragios::Server.find_status_update(:tag => 'test')
     hash = monitors[0]
     hash["_id"].should == "test_config_settings"
 end

 it "should get status update by id" do
  hash  = Ragios::Server.get_status_update("test_config_settings")
  hash["_id"].should == "test_config_settings"
  hash["contact"].should == "admin@mail.com"
  hash["tag"].should == "test"
  hash["every"].should == "1m"
 end

 it "should display status update" do
   puts Ragios::Server.status_report
 end

  it "should display status update by tag" do
    puts Ragios::Server.status_report(tag = 'active_monitor')
 end

  it "should restart a monitor" do 
      Ragios::Server.restart_monitor("active_monitor")
      monitors = Ragios::Server.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash["state"].should == "active"
      sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].params[:tags].should == ["active_monitor"]
  end

  it "should stop a monitor" do 
      Ragios::Server.stop_monitor("active_monitor")
      monitors = Ragios::Server.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash["state"].should == "stopped"
      sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
      sch.should ==  []
  end

   it "should delete a running monitor" do
     #restart the monitor
     Ragios::Server.restart_monitor("to_be_deleted")
     #verify that the monitor is running
     sch = Ragios::Server.get_monitors_frm_scheduler("to_be_deleted")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["to_be_deleted"]     
     #delete the monitor
     Ragios::Server.delete_monitor("to_be_deleted")
     #verify that the monitor was deleted and stopped
     Ragios::Server.find_monitors(:tag => 'to_be_deleted').should == []
     sch = Ragios::Server.get_monitors_frm_scheduler("to_be_deleted")
     sch.should ==  []
   end
 
 it "should update a running monitor" do
     Ragios::Server.restart_monitor("active_monitor")
     #verify that the monitor is running
     sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["active_monitor"]   
     #update the monitor
     options  = {
                   every: '3m',
                   contact: 'kent@mail.com',
                   via: 'gmail'
                  }

     Ragios::Server.update_monitor("active_monitor", options)
     #verify that the monitor was updated
     monitors = Ragios::Server.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash ["contact"].should == "kent@mail.com"
      hash ["every"].should == "3m"
      hash["state"].should == "active"
     #verify that the monitor is still on schedule and running on new time_interval
      sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "3m"
      sch[0].params[:tags].should == ["active_monitor"]
 end

 it "should save and schedule status updates" do
   config = {   :every => '1m',
                   :contact => 'test@mail.com',
                   :via => 'gmail',
                  :tag => 'save_test' 
                  }
  Ragios::Server.start_status_update(config)
  #verify that the status update exists in the database
  updates = Ragios::Server.find_status_update(:tag => 'save_test')
  hash = updates[0]
  hash["tag"].should == "save_test"
  hash["contact"].should == "test@mail.com"
  hash["every"].should == "1m"
  #verify scheduler is running the status update
  sch = Ragios::Server.get_status_update_frm_scheduler(tag = "save_test")
  sch[0].class.should ==  Rufus::Scheduler::EveryJob
  sch[0].t.should == "1m" 
  sch[0].params[:tags].should == ["save_test"]
 
 end

 it "should stop a status update by tag" do
     #verify that the status update is running
     sch = Ragios::Server.get_status_update_frm_scheduler(tag = "save_test")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["save_test"]
     #stop the status update
      Ragios::Server.stop_status_update('save_test')
     #verify that the status update has been stopped
      updates = Ragios::Server.find_status_update(:tag => 'save_test')
      hash = updates[0]
      hash["tag"].should == "save_test"
      hash["state"].should == "stopped"
      sch = Ragios::Server.get_status_update_frm_scheduler(tag = "save_test")
      sch.should ==  []
 end

 it "should restart active status updates (used when server starts up)" do
    Ragios::Server.restart_status_updates
    #verify that the status update is running
     sch = Ragios::Server.get_status_update_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash
 end

it "should not restart a status update for a tag that doesnt exist" do
    #restart the status update
    Ragios::Server.restart_status_updates('can_not_be_found').should == nil
end

  it "should restart a stopped status update" do
    #stop the status update
      Ragios::Server.stop_status_update('to_be_deleted')
     #verify that the status update has been stopped
      updates = Ragios::Server.find_status_update(:tag => 'to_be_deleted')
      hash = updates[0]
      hash["tag"].should == "to_be_deleted"
      hash["state"].should == "stopped"
      sch = Ragios::Server.get_status_update_frm_scheduler(tag = "to_be_deleted")
      sch.should ==  []
     #restart the status update
      hash  = Ragios::Server.restart_status_updates('to_be_deleted')
      hash.should_not == nil
     #verify that the status update was restarted by scheduler
      sch = Ragios::Server.get_status_update_frm_scheduler(tag = "to_be_deleted")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob 
      sch[0].params[:tags].should == ["to_be_deleted"]
     #verify that the database was updated
      updates = Ragios::Server.find_status_update(:tag => 'to_be_deleted')
      hash = updates[0]
      hash["tag"].should == "to_be_deleted"
      hash["state"].should == "active"
  end
   
  it "should delete an active status update" do 
    #verify that the status update is running
     sch = Ragios::Server.get_status_update_frm_scheduler(tag = "to_be_deleted")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["to_be_deleted"]
    #delete status update
    Ragios::Server.delete_status_update('to_be_deleted')
    #verify that the status update was removed from the scheduler
    sch = Ragios::Server.get_status_update_frm_scheduler(tag = "to_be_deleted")
    sch.should ==  []
    #verify that the status update was removed from the database 
    Ragios::Server.find_status_update(:tag => 'to_be_deleted').should == []
  end

   it "should edit a running status update" do
     #verify that the status update is running
     sch = Ragios::Server.get_status_update_frm_scheduler(tag = "sample_status_update")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["sample_status_update"]

     #edit the running status update
     data  = {
                   every: '7d',
                   contact: 'clark@mail.com',
                   via: 'gmail'
                  }

      Ragios::Server.edit_status_update("sample_status_update",data)
      #verify that the database was updated
      updates = Ragios::Server.find_status_update(:tag => 'sample_status_update')
      hash = updates[0]
      hash["_id"].should == "sample_status_update"
      hash["contact"].should == "clark@mail.com"
      hash["every"].should == "7d"
      hash["state"].should == "active"
      #verify that the time interval for the active scheduler was also updated
      sch = Ragios::Server.get_status_update_frm_scheduler("sample_status_update")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "7d"
      sch[0].params[:tags].should == ["sample_status_update"]  
   end


   it "should return a list of all active monitors" do
      monitors = Ragios::Server.get_active_monitors
      hash = monitors[0]
      hash["state"].should == "active"
   end
   
   it "should return a list of all stopped status updates by tag" do
      updates = Ragios::Server.get_stopped_status_updates("save_test")
      hash = updates[0]
      hash["state"].should == "stopped"
      hash["tag"].should == "save_test"
   end

  it "should return a list of all active status updates" do
    updates = Ragios::Server.get_active_status_updates
    hash = updates[0]
    hash["state"].should == "active"
  end

  it "should get all status updates" do
    updates  = Ragios::Server.get_all_status_updates
    hash = updates[0]
    hash["via"].should == "gmail"
  end
  
  it "should return a monitor by id" do
     hash = Ragios::Server.get_monitor("trial_monitor")
     hash["tag"].should == "trial_monitor"
     hash["monitor"].should == "url"
     hash["via"].should == "gmail"
     hash["url"].should == "https://github.com/obi-a/Ragios"
     hash["every"].should == "1m"
  end

 it "should return all monitors (active & stopped)" do
      monitors = Ragios::Server.get_all_monitors
      hash = monitors[0]
      hash["monitor"].should == "url"
 end

 it "should return stats of monitors with the specified tag " do
   #(only returns monitors that have been executed at least once)
      monitors = Ragios::Server.get_stats("active_monitor")
      hash = monitors[0]
      hash.has_key?("num_tests_passed").should == true
 end

 it "should return stats of monitors " do
    #(only returns monitors that have been executed at least once)
      monitors = Ragios::Server.get_stats
      hash = monitors[0]
      hash.has_key?("num_tests_passed").should == true
 end

 it "should return status updates currently running on the scheduler" do
     sch = Ragios::Server.get_status_update_frm_scheduler
     sch.should_not be_nil
     sch.class.should ==  Hash
 end

 it "should return status updates by specified tag currently running on the scheduler" do
     sch = Ragios::Server.get_status_update_frm_scheduler("sample_status_update")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["sample_status_update"]  
 end

 it "should return monitors by specified tag currently running on the scheduler" do
    sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
    sch[0].should be_a_kind_of(Rufus::Scheduler::EveryJob)
    sch[0].class.should ==  Rufus::Scheduler::EveryJob
    sch[0].params[:tags].should == ["active_monitor"]
   #delete the sample monitor used in this test from database to provide an accurate test on each run
   Ragios::Server.delete_monitor(id ='active_monitor')
 end

  it "should return all monitors currently running on the scheduler" do
    sch = Ragios::Server.get_monitors_frm_scheduler
    sch.should_not be_nil
    sch.class.should == Hash
 end

  it "should restart monitoring objects" do
    Ragios::Server.restart [Monitor1.new, Monitor2.new]
    sch = Ragios::Server.get_monitors('runtime_id')
    sch[0].class.should ==  Rufus::Scheduler::EveryJob
    sch[0].t.should == "87m"
    sch[1].class.should ==  Rufus::Scheduler::EveryJob
    sch[1].t.should == "88m"

    sch = Ragios::Server.get_monitors
    sch.should_not be_nil
    sch.class.should == Hash
 end
end 

