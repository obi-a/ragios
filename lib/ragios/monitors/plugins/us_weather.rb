module Monitors

class UsWeather
   attr_reader :county
   attr_accessor :describe_test_result 
   attr_accessor :test_result

   def init(options)
        @county = options[:county] 
        @contact = options[:contact]
        raise "county must be assigned a value" if @county.nil?
        @describe_test_result = "Checking if county has a severe weather alert or prediction" 
   end 

  def weather_alerts(county)
    source = "http://alerts.weather.gov/cap/us.php?x=0"

    rss = SimpleRSS.parse open(source)

    count = 0
    alerts = []

    rss.items.each do|i|
     if i.summary.index(county.upcase) != nil 
      warning = "WARNING: #{i.summary}" + " Link: #{i.link}"
      alerts[count] = warning 
      count = count + 1 
     end
    end

   return alerts
  end
    
  def test_command
      if weather_alerts(@county).empty?  
         return TRUE
      else
          weather_alerts(@county).each do |data|
          @email_report = data + '\n' 
          end
          puts @email_report
          return FALSE
      end 
  end

   def notify 
      message = {:to => @contact,
                  :subject => "Earthquakes detected in #{@location}", 
                  :body => @email_report}
     Ragios::GmailNotifier.new.send(message)   
   end

  
end

end

