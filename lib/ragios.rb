require 'pony'
require 'rufus/scheduler'
require 'twitter'
require 'net/http'
require 'net/https'
require 'gmail'
require 'leanback'
require 'uuidtools'
require 'aws/ses'


dir = Pathname(__FILE__).dirname.expand_path

def require_all(path)
 Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file| 
   require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
 end
end


#notifiers
require dir + 'ragios/notifiers/email/email_notifier'
require_all '/ragios/notifiers'



#monitors and plugins 
require dir + 'ragios/monitors/system'
require_all '/ragios/monitors/plugins'

#schedulers
require dir + 'ragios/schedulers/ragios_scheduler'
require dir + 'ragios/schedulers/notification_scheduler'
require dir + 'ragios/schedulers/server'

#system
require dir + 'ragios/system'
require dir + 'ragios/monitor'
require dir + 'ragios/server'
require dir + 'ragios/database_admin'
require dir + 'ragios/admin'
require dir + 'ragios/monitors_api'
require dir + 'ragios/status_updates_api'
require dir + 'ragios/ragios_exception'


#loggers
require dir + 'ragios/loggers/logger'

#global variable path to the folder with erb message files
$path_to_messages =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/messages/')) 
$path_to_json =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/json/')) 
