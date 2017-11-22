task :console do
  ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'ragios'))
  ragios_lib = "#{ragios_dir}/lib/ragios"
  irb = "foreman run bundle exec pry -r #{ragios_lib}"
  sh irb
end

task :notifiers do
  sh 'rspec -fs spec/notifiers'
end

task :plugins do
  sh 'rspec -fs spec/plugins'
end

task :core_tests do
  sh 'foreman run -e test.env rspec spec/lib/ --format documentation'
end

task :webapp_tests do
  sh 'foreman run -e test.env  rspec spec/web/ --format documentation'
end

