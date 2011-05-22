module Monitors

class TravelAlert 
   attr_reader :location
   attr_accessor :describe_test_result 
   attr_accessor :test_result

   def init(options)
        @location = options[:location] 
        @contact = options[:contact]
        raise "domain must be assigned a value" if @location.nil?
        @describe_test_result = "Severe weather alerts " 
   end 

    

   def travel_alert(location)
     source = "http://travel.state.gov/_res/rss/TWs.xml"

     content = "" # raw content of rss feed will be loaded here 
     open(source) do |s| content = s.read end               
     rss = RSS::Parser.parse(content, false) 

     count = 0

     x = 0
     problem_regions = []

    until count == rss.items.size
     if rss.items[count].description.index(location.titlecase) != nil 
      region = { :title =>  rss.items[count].title , :pubdate => rss.items[count].pubDate, :link => rss.items[count].link}   
      problem_regions[x] =  region
      x = x + 1
    end
      count = count + 1
    end

      return problem_regions
     end

    
  def test_command
      if travel_alert(@location).empty?  
         return TRUE
      else
          travel_alert(@location).each do |alert|
                @email_report = "#{alert[:title]} #{alert[:pubdate]} #{alert[:link]}" 
          end
           
          return FALSE
      end 
  end

   def notify 
      message = {:to => @contact,
                  :subject => "TRAVEL ALERTS For #{@location}" , 
                  :body => @email_report}
      Ragios::GmailNotifier.new.send(message)
      
   end

  
end

end

