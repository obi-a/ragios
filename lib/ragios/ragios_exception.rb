class RagiosException < StandardError
  def initialize(data)
    @data = data
  end
end


module Ragios
  class MonitorNotFoundException < StandardError
  end
end
