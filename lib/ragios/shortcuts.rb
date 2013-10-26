module Ragios
  def self.method_missing(name, *args)
    return Ragios::Controller.send(name,*args) if name == :run
  end
end
