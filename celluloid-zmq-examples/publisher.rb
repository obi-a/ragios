require "celluloid/zmq/current"

Celluloid::ZMQ.init

class Publisher
  include Celluloid::ZMQ

  def initialize
    @link = "tcp://127.0.0.1:5555"
    @publisher = Socket::Pub.new
    @publisher.linger = 100
    @publisher.connect(@link)
  end

  def publish(topic)
    @publisher.write(topic, "Animal crackers!", "publisher-A")
    sleep 10
  end

  def close
    @publisher.close
  end

  def run
    count = 0
    10000.times do
      topic = "animals.#{count}"
      publish(topic)
      count += 1
    end
  end
end

p = Publisher.new
p.run

trap("INT") { puts "Shutting down."; p.close; p.terminate; exit}

puts "Starting up"

loop do
end

