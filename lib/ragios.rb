require 'pony'
require 'rufus/scheduler'
require 'twitter'
require 'net/http'
require 'net/https'
require 'gmail'
require 'leanback'
require 'uuidtools'
require 'aws/ses'
require 'state_machine'
require 'sucker_punch'


dir = Pathname(__FILE__).dirname.expand_path

def require_all(path)
 Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file| 
   require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
 end
end


#notifiers
require dir + 'ragios/notifiers/email/email_notifier'
require_all '/ragios/notifiers'

require_all '/ragios/plugins'

#system
require_all '/ragios'

#global variable path to the folder with erb message files
$path_to_messages =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/messages/')) 
$path_to_json =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/json/')) 
