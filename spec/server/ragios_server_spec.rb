require 'spec_base.rb'
require 'set_server_test_values.rb'

Ragios::Controller.scheduler(Ragios::Schedulers::Server.new)


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

describe "activity log" do
  it "should return security object of activity log database" do
    database_admin = Ragios::DatabaseAdmin.admin
    hash = Couchdb.get_security(Ragios::DatabaseAdmin.activity_log,Ragios::DatabaseAdmin.session)
    admins = hash["admins"]
    readers = hash["readers"]
    admins["names"].should == [database_admin[:username]]
    admins["roles"].should == ["admin"]
    readers["names"].should == [database_admin[:username]]
    readers["roles"].should == ["admin"]     
  end
end

describe "authsession" do
  it "should return security object of authsession database" do
    database_admin = Ragios::DatabaseAdmin.admin
    hash = Couchdb.get_security(Ragios::DatabaseAdmin.auth_session,Ragios::DatabaseAdmin.session)
    admins = hash["admins"]
    readers = hash["readers"]
    admins["names"].should == [database_admin[:username]]
    admins["roles"].should == ["admin"]
    readers["names"].should == [database_admin[:username]]
    readers["roles"].should == ["admin"]   
  end
end

describe Ragios::Controller do

       
  it "should find monitors by tag" do
     monitors = Ragios::Controller.find_monitors(:tag => 'trial_monitor')
     hash = monitors[0]
     hash["_id"].should == "trial_monitor"
  end



  it "should restart a monitor" do 
      Ragios::Controller.restart_monitor("active_monitor")
      monitors = Ragios::Controller.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash["state"].should == "active"
      sch = Ragios::Controller.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].params[:tags].should == ["active_monitor"]
  end

  it "should stop a monitor" do 
      Ragios::Controller.stop_monitor("active_monitor")
      monitors = Ragios::Controller.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash["state"].should == "stopped"
      sch = Ragios::Controller.get_monitors_frm_scheduler("active_monitor")
      sch.should ==  []
  end

   it "should delete a running monitor" do
     #restart the monitor
     Ragios::Controller.restart_monitor("to_be_deleted")
     #verify that the monitor is running
     sch = Ragios::Controller.get_monitors_frm_scheduler("to_be_deleted")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["to_be_deleted"]     
     #delete the monitor
     Ragios::Controller.delete_monitor("to_be_deleted")
     #verify that the monitor was deleted and stopped
     Ragios::Controller.find_monitors(:tag => 'to_be_deleted').should == []
     sch = Ragios::Controller.get_monitors_frm_scheduler("to_be_deleted")
     sch.should ==  []
   end
 
 it "should update a running monitor" do
     Ragios::Controller.restart_monitor("active_monitor")
     #verify that the monitor is running
     sch = Ragios::Controller.get_monitors_frm_scheduler("active_monitor")
     sch[0].class.should ==  Rufus::Scheduler::EveryJob
     sch[0].params[:tags].should == ["active_monitor"]   
     #update the monitor
     options  = {
                   every: '3m',
                   contact: 'kent@mail.com',
                   via: 'gmail_notifier'
                  }

     Ragios::Controller.update_monitor("active_monitor", options)
     #verify that the monitor was updated
     monitors = Ragios::Controller.find_monitors(:tag => 'active_monitor')
      hash = monitors[0]
      hash["_id"].should == "active_monitor"
      hash ["contact"].should == "kent@mail.com"
      hash ["every"].should == "3m"
      hash["state"].should == "active"
     #verify that the monitor is still on schedule and running on new time_interval
      sch = Ragios::Controller.get_monitors_frm_scheduler("active_monitor")
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "3m"
      sch[0].params[:tags].should == ["active_monitor"]
 end




   it "should return a list of all active monitors" do
      monitors = Ragios::Controller.get_active_monitors
      hash = monitors[0]
      hash["state"].should == "active"
   end
   
  
  it "should return a monitor by id" do
     hash = Ragios::Controller.get_monitor("trial_monitor")
     hash["tag"].should == "trial_monitor"
     hash["monitor"].should == "url"
     hash["via"].should == 'gmail_notifier'
     hash["url"].should == "https://github.com/obi-a/Ragios"
     hash["every"].should == "1m"
  end

 it "should return all monitors (active & stopped)" do
      monitors = Ragios::Controller.get_all_monitors
      hash = monitors[0]
      hash["monitor"].should == "url"
 end

 it "should return stats of monitors with the specified tag " do
   #(only returns monitors that have been executed at least once)
      monitors = Ragios::Controller.get_stats("active_monitor")
      hash = monitors[0]
      hash.has_key?("num_tests_passed").should == true
 end

 it "should return stats of monitors " do
    #(only returns monitors that have been executed at least once)
      monitors = Ragios::Controller.get_stats
      hash = monitors[0]
      hash.has_key?("num_tests_passed").should == true
 end


 it "should return monitors by specified tag currently running on the scheduler" do
    sch = Ragios::Controller.get_monitors_frm_scheduler("active_monitor")
    sch[0].should be_a_kind_of(Rufus::Scheduler::EveryJob)
    sch[0].class.should ==  Rufus::Scheduler::EveryJob
    sch[0].params[:tags].should == ["active_monitor"]
   #delete the sample monitor used in this test from database to provide an accurate test on each run
   Ragios::Controller.delete_monitor(id ='active_monitor')
 end

  it "should return all monitors currently running on the scheduler" do
    sch = Ragios::Controller.get_monitors_frm_scheduler
    sch.should_not be_nil
    sch.class.should == Hash
 end

  it "should restart monitoring objects" do
    Ragios::Controller.add_monitors([Monitor1.new, Monitor2.new])
    sch = Ragios::Controller.get_monitors('runtime_id')
    sch[0].class.should ==  Rufus::Scheduler::EveryJob
    sch[0].t.should == "87m"
    sch[1].class.should ==  Rufus::Scheduler::EveryJob
    sch[1].t.should == "88m"

    sch = Ragios::Controller.get_monitors
    sch.should_not be_nil
    sch.class.should == Hash
 end
end 

