require 'spec_base.rb'
require 'set_server_test_values.rb'

describe Ragios::Server do
       
  it "should find monitors" do
     monitors = Ragios::Server.find_monitors(:tag => 'test')
     hash = monitors[0]
     hash["_id"].should == "trial_monitor"
  end

 it "should find status update by tag" do  
     monitors = Ragios::Server.find_status_update(:tag => 'test')
     hash = monitors[0]
     hash["_id"].should == "test_config_settings"
 end

 
  
end
