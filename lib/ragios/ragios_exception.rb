class RagiosException < StandardError
  def initialize(data)
    @data = data
  end
end


module Ragios
  class EventNotFound < StandardError; end
  class MonitorNotFound < StandardError; end
  class NotifierNotFound < StandardError; end
  class PluginNotFound < StandardError; end
  class PluginTestCommandNotImplemented < StandardError; end
  class PluginTestResultNotDefined < StandardError; end
  class PluginInitNotImplemented < StandardError; end
  class CannotEditSystemSettings < StandardError; end
end
