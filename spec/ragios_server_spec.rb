require 'spec_base.rb'
require 'set_server_test_values.rb'

Ragios::Server.init

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
    #validate that the monitor is running
     sch = Ragios::Server.get_monitors_frm_scheduler("to_be_deleted")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["to_be_deleted"]     
    #delete the monitor
     Ragios::Server.delete_monitor("to_be_deleted")
    #validate that the monitor was stopped
     Ragios::Server.find_monitors(:tag => 'to_be_deleted').should == []
     sch = Ragios::Server.get_monitors_frm_scheduler("to_be_deleted")
     sch.should ==  []
   end
 
 it "should update a running monitor" do
     Ragios::Server.restart_monitor("active_monitor")
     
     options  = {
                   every: '2d',
                   contact: 'admin@mail.com',
                   via: 'gmail'
                  }

     Ragios::Server.update_monitor("active_monitor", options)
     monitors = Ragios::Server.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash ["contact"].should == "admin@mail.com"
      hash ["every"].should == "2d"
      hash["state"].should == "active"
      sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "2d"
      sch[0].params[:tags].should == ["active_monitor"]
 end

 it "should save and schedule status updates" do
   config = {   :every => '1m',
                   :contact => 'test@mail.com',
                   :via => 'gmail',
                  :tag => 'save_test' 
                  }
  Ragios::Server.start_status_update(config)
  updates = Ragios::Server.find_status_update(:tag => 'save_test')
  hash = updates[0]
  hash["tag"].should == "save_test"
  hash["contact"].should == "test@mail.com"
  hash["every"].should == "1m"
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
     #restart status update
      Ragios::Server.restart_status_updates('to_be_deleted')
      sch = Ragios::Server.get_status_update_frm_scheduler(tag = "to_be_deleted")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob 
      sch[0].params[:tags].should == ["to_be_deleted"]
      updates = Ragios::Server.find_status_update(:tag => 'to_be_deleted')
      hash = updates[0]
      hash["tag"].should == "to_be_deleted"
      hash["state"].should == "active"
  end
   
  it "should delete an active status update" do 
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
                   every: '5d',
                   contact: 'clark@mail.com',
                   via: 'gmail'
                  }

      Ragios::Server.edit_status_update("sample_status_update",data)
      #verify that the database was updated
      updates = Ragios::Server.find_status_update(:tag => 'sample_status_update')
      hash = updates[0]
      hash["_id"].should == "sample_status_update"
      hash["contact"].should == "clark@mail.com"
      hash["every"].should == "5d"
      hash["state"].should == "active"
      #verify that the time interval for the active scheduler was also updated
      sch = Ragios::Server.get_status_update_frm_scheduler("sample_status_update")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "5d"
      sch[0].params[:tags].should == ["sample_status_update"]  
   end
end
