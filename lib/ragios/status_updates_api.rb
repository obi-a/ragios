module Ragios
  module StatusUpdates
    @server_method =  {:all => :get_all_status_updates, 
                       :find => :find_status_update,
                       :delete => :delete_status_update,
                       :update => :edit_status_update,
                       :stop => :stop_status_update,
                       :restart => :restart_status_updates,
                       :get => :get_status_update,
                       :scheduler => :get_status_update_frm_scheduler,
                       :start => :start_status_update
                     } 

    def self.actions
      @server_method
    end

    def self.method_missing(name, *args)
      super unless @server_method.has_key?(name.to_sym)
      return Ragios::Server.send(@server_method[name.to_sym],*args)
    end
  end
end
