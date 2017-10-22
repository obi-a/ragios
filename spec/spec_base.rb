$TESTING = true
require 'rubygems'
Bundler.require(:test, :web)

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
require_all '/ragios/web'

require 'celluloid/test'

RSpec.configure do |config|

  config.after(:suite) do
    Ragios.database.delete
  end
end
