class RagiosException < StandardError
  def initialize(data)
    @data = data
  end
end


module Ragios
  class MonitorNotFound < StandardError; end
  class NotifierNotFound < StandardError; end
  class PluginNotFound < StandardError; end
  class PluginTestCommandNotFound < StandardError; end
  class PluginTestResultNotFound < StandardError; end
  class CannotEditSystemSettings < StandardError; end
end
