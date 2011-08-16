require 'spec_base.rb'
require 'set_server_test_values.rb'

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

   it "should delete a monitor" do

     Ragios::Server.delete_monitor("to_be_deleted")
     Ragios::Server.find_monitors(:tag => 'to_be_deleted').should == []

   end
 
 it "should update a running monitor" do
     Ragios::Server.restart_monitor("active_monitor")
     
     options  = {
                   every: '40m',
                   contact: 'clark@mail.com',
                   via: 'gmail'
                  }

     Ragios::Server.update_monitor("active_monitor", options)
     monitors = Ragios::Server.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash["state"].should == "active"
      sch = Ragios::Server.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "40m"
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

  
end
