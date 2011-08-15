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
  
end
