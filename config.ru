#config.ru
begin
  require 'rubygems'
  require "bundler/setup"
  Bundler.require(:web)
  dir = Pathname(__FILE__).dirname.expand_path
  require "#{dir}/lib/ragios"
  require_all '/ragios/web'

  run Ragios::Web::Application
  Ragios::Logging.setup(program_name: "Web Service")
  Ragios::Logging.logger.info("starting out")

  def require_all(path)
    Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file|
      require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
    end
  end

rescue => e
  $stderr.puts '-' * 80
  $stderr.puts "Application Error: #{e.class}: '#{e.message}'"
  $stderr.puts e.backtrace.join("\n")
  $stderr.puts '-' * 80
  raise e
end
