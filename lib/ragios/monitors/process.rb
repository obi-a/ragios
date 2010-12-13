module Ragios
 module Monitors

class Process < Ragios::Monitors::Service

  attr_reader :process_name
  attr_reader :start_command
  attr_reader :restart_command
  attr_reader :stop_command
  attr_reader :pid_file
  attr_reader :hostname

   def initialize
        
        raise "@process_name" if @process_name.nil?  
        raise "@start_command" if @start_command.nil? 
        raise "@restart_command" if @restart_command.nil? 
        raise "@stop_command" if @stop_command.nil? 
        raise "@pid_file" if @pid_file.nil?   
        raise "@hostname" if @hostname.nil? 
        @describe_test_result =  "The Service " + @process_name + " on host " 
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
       
      #delete pid files
       

   end

end


 end
end
