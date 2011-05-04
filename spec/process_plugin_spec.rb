require 'spec_base.rb'

      options = {  :monitor => 'process',
                   :every => '10m',
                   :test => 'Apache Test',
                   :process_name => 'apache2',
                   :start_command => '/etc/init.d/apache2 start',
                   :stop_command => '/etc/init.d/apache2 stop',
                   :restart_command => '/etc/init.d/apache2 restart',
                   :pid_file => '/var/run/apache2.pid',
                   :server_alias => 'my home server',
                   :hostname => '192.168.2.9',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',
                   :notify_interval => '1h'
                  }

describe Monitors::Process do 

 it "should PASS the test when apache process is running" do 
     #commented out, only works on a system that has apache installed and running
     #p = Monitors::Process.new
     #p.init(options)
     #p.test_command.should == TRUE
 end 

end



