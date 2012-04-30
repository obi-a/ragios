require 'chronic'
require 'sqlite3'

module Monitors

#Plugin: Monitors a URL by sending a http GET request to it
#PASSED if it gets a HTTP 200,301 or 302 Response status code from the http request
class MeteredUrlMonitor

  attr_accessor :describe_test_result 
  attr_accessor :test_result
  attr_reader :url 
  attr_reader :tag
  
  def init(options)
      @user = options[:tag]
      @url = options[:url] 
      raise "A url to test must be specified, url must be assigned a value" if @url.nil?    
      @describe_test_result = "HTTP GET Request to " + @url
  end

  def this_month
    time = Time.now
    time.strftime("%B")
  end
  
  def this_year
   time = Time.now
   time.year.to_s
  end


  def log
    charge_per_check = '0.0001' 
    id = @user + this_month + this_year
    db = SQLite3::Database.new( '/home/obi/bin/invoice.db' )    
    
   #check if an invoice has  been created <--clean up later
   rows = db.execute( "select * from invoice where id = ?",id)

   if (rows != []) 
    #invoice has been created
    	rows = db.execute( "UPDATE invoice
		SET balance = (balance + 0.0001),
		 url_monitoring = (url_monitoring + 1) 
				WHERE id = ?",id )
     puts 'another I was called'
  else
       billing_period = this_month + ', ' + this_year 
       username = @user
       date_due = (Chronic.parse('1st day next month')).to_s
       balance = charge_per_check
       url_monitoring = '1'
       status = 'not_due'
             puts 'I was called'
     rows = db.execute( "INSERT OR IGNORE INTO invoice (id,balance, billing_period,date_due,status,url_monitoring,username)
VALUES('"+id +"','"+balance+"','"+billing_period+"','"+ date_due +"','"+status+"','"+url_monitoring+"','"+username+"');" )
 end
end
  
  def test_command
    begin
     log
     response = RestClient.get @url, {"User-Agent" => "Ragios (Saint-Ruby)"}
     @test_result = response.code
     return TRUE
   rescue => e
     @test_result = e.message
     return FALSE
   end
  end
end

end


