require 'rack/test'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Ragios::Web::Application
  end
end

RSpec.configure { |c| c.include RSpecMixin }
