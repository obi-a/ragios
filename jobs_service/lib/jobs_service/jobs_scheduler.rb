Celluloid::ZMQ.init

#TODO: clean up later
module Ragios
  class JobsScheduler

    include Celluloid::ZMQ
    attr_reader :job_id, :interval, :socket

    def initialize(options = {})
      @job_id = options[:job_id]
      @interval = options[:interval]
    end

    def schedule
    end

    def write(message)
      @socket << message
      nil
    end


    def read
      message = @socket.read_multipart
      puts "just received: #{message}"
    end

    def unschedule
    end
  end
end
