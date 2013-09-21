module Ragios
  @server_method =  {:all => :get_all_monitors, 
                       :find => :find_monitors,
                       :delete => :delete_monitor,
                       :update => :update_monitor,
                       :stop => :stop_monitor,
                       :restart => :restart_monitor,
                       :get => :get_monitor,
                       :scheduler => :get_monitors_frm_scheduler,
                       :sch => :get_monitors_frm_scheduler,
                       :active => :get_active_monitors
                     } 
  def self.actions
    @server_method.merge({:start => :add_and_start_new_monitors, :start_all => :start_all_monitors})
  end

  def self.start_all
    Ragios::Controller.restart_monitors
  end

  def self.start(monitors)
    Ragios::Controller.add_monitors(monitors)
  end

  def self.method_missing(name, *args)
    super unless @server_method.has_key?(name.to_sym)
    return Ragios::Server.send(@server_method[name.to_sym],*args)
  end
end
