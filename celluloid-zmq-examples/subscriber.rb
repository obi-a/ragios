require "celluloid/zmq/current"

Celluloid::ZMQ.init

class Subscriber
  include Celluloid::ZMQ

  attr_reader :subscriber

  def initialize(topic)
    @link = "tcp://127.0.0.1:5555"
    @subscriber = Socket::Sub.new
    @topic = topic
    @subscriber.subscribe(@topic)
    @subscriber.bind(@link)
    @pool = MyWorker.pool(size: 20)
  end

  # def subscribe
  #   @subscriber.subscribe(@topic)
  # end

  # def connect
  #  @subscriber.connect(@link)
  # end

  # def read_multipart
  #   @subscriber.read_multipart
  # end

  # def read
  #   @subscriber.read(@topic)
  # end

  #def handle_message(multipart_message)
  #  puts "Received #{multipart_message.inspect}"
  #end

  def run
    loop do
      puts "Waiting for response..."
      #async.handle_message(@subscriber.read_multipart)
      #Handler.new.async.handle_message(@subscriber.read_multipart)
      @pool.async.perform(@subscriber.read_multipart)
    end
  end

  def close
    @subscriber.close
  end
end

class MyWorker
  include Celluloid

  def perform(multipart_message)
    puts "Received #{multipart_message.inspect}"
  end
end


s = Subscriber.new("monitor")
s.run

trap("INT") { puts "Shutting down.";  s.close; s.terminate; exit}

puts "Starting up"

loop do
end

