module Ragios
 module Monitors
#monitors processes on Linux/Unix systems, restarts the process if it fails
#Note: this code serves as proof of concept to show easy it is to extend the Ragios system to monitor any kind of system
class Process < Ragios::Monitors::Service

  attr_reader :process_name
  attr_reader :start_command
  attr_reader :restart_command
  attr_reader :stop_command
  attr_reader :pid_file
  attr_reader :hostname
  attr_reader :server_alias

   def initialize
        
        raise "@process_name must be assigned a value" if @process_name.nil?  
        raise "@start_command must be assigned a value" if @start_command.nil? 
        raise "@restart_command must be assigned a value" if @restart_command.nil? 
        raise "@stop_command must be assigned a value" if @stop_command.nil? 
        raise "@pid_file must be assigned a value" if @pid_file.nil?   
        raise "@hostname must be assigned a value" if @hostname.nil? 
        raise "@server_alias must be assigned a value" if @server_alias.nil? 
        @describe_test_result =  "The process " + @process_name + " on host: " + @hostname 
        super
    end 

   #runs 'pidof @process_name' to check if the process is running
   #fails when it returns false or throws an exception
   def test_command
    begin 
     s = system "pidof " + @process_name
     if  s 
       @test_result = 'PASSED'
       return TRUE 

     else 
      @test_result = 'FAILED'
      return FALSE
     end
    rescue Exception
        @test_result =  $! # $! global variable reference to the Exception object
        return FALSE  
    end   
   
   end  #end of test_command

   
   def failed
       
      
      puts "starting service again"

      #delete pid files if they exist
      FileUtils::rm(@pid_file,:force => true) 
      #rm = system "rm " + @pid_file 
      s = system  @restart_command
      
   end

end


 end
end
