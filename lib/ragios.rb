require 'pony'
require 'rufus/scheduler'
require 'twitter'
require 'net/http'
require 'net/https'
require 'gmail'
require 'leanback'
require 'uuidtools'


dir = Pathname(__FILE__).dirname.expand_path

def require_all(path)
 Dir.glob(File.dirname(__FILE__) + path + '/*') do |file| 
 require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
 end
end


#notifiers
require dir + 'ragios/notifiers/twitter_notifier'
require dir + 'ragios/notifiers/email_notifier'
require dir + 'ragios/notifiers/gmail_notifier'

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

#global variable path to the folder with erb message files
$path_to_messages =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/messages/')) 
$path_to_json =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/json/')) 




