module Ragios
  @server_method =  {:all => :get_all_monitors, 
                       :find => :find_monitors,
                       :delete => :delete_monitor,
                       :update => :update_monitor,
                       :stop => :stop_monitor,
                       :restart => :restart_monitor,
                       :get => :get_monitor,
                       :scheduler => :get_monitors_frm_scheduler
                     } 
  def self.actions
    @server_method
  end

  def self.start(monitors)
    return Ragios::Monitor.start monitors, server=TRUE
  end

  def self.method_missing(name, *args)
    super unless @server_method.has_key?(name.to_sym)
    return Ragios::Server.send(@server_method[name.to_sym],*args)
  end
end
