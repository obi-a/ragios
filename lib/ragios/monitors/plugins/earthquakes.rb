module Monitors

class Earthquakes
   attr_reader :location
   attr_accessor :describe_test_result 
   attr_accessor :test_result

   def init(options)
        @location = options[:location] 
        @contact = options[:contact]
        raise "location must be assigned a value" if @location.nil?
        @describe_test_result = "Checking if location had an earthquake in the last 7 days" 
   end 

  def earthquake(location)
   source = "http://earthquake.usgs.gov/earthquakes/catalogs/eqs7day-M1.txt"
   problem_regions = []
   count = 0

   FasterCSV.foreach(open(source)) do |row|
    if row[9].index(location.titlecase) != nil 
     #CSV format: Src 0 ,Eqid 1,Version 2,Datetime 3,Lat 4,Lon 5,Magnitude 6,Depth 7,NST 8,Region 9
     region =  {:datetime => row[3], :latitude => row[4], :longitude =>  row[5], :magnitude => row[6],
                 :depth => row[7], :region => row[9]}
     problem_regions[count] =  region
     count = count + 1    
    end   
   end # end of CSV parser
    return problem_regions #returns [] when location has no earthquakes  
  end
    
  def test_command
      if earthquake(@location).empty?  
         return TRUE
      else
          earthquake(@location).each do |data|
     @email_report = "datetime: #{data[:datetime]}  latitude: #{data[:latitude]}  longitude: #{data[:longitude]} magnitude: #{data[:magnitude]} depth: #{data[:depth]}  region: #{data[:region]} \n" 
          end
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

