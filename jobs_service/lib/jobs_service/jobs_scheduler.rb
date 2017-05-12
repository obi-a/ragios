Celluloid::ZMQ.init

#TODO: clean up later
module Ragios
  class JobsScheduler

    include Celluloid::ZMQ
    attr_reader :job_id, :interval, :socket

    def initialize(options = {})
      @job_id = options[:job_id]
      @interval = options[:interval]

      #move settings to config file later
      @link = "tcp://127.0.0.1:5544"
      @socket = Socket::Req.new
      @socket.linger = 100

      begin
        @socket.connect(@link)
      rescue IOError
        @socket.close
        raise
      end

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

    def close
      @socket.close
    end

    def terminate
      close
      super
    end
  end
end
