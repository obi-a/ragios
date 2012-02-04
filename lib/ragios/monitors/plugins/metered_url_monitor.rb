require 'chronic'

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
    charge_per_check = 0.0001
    id = @user + this_month + this_year

    begin
    doc = {:database => 'invoice', :doc_id => id.to_s}
    current_invoice = Couchdb.view doc,Ragios::DatabaseAdmin.session
    num_of_checks = current_invoice['url_monitoring'] + 1
    balance = current_invoice['balance'] + charge_per_check
    balance.round_to(4)    

    data = { :url_monitoring => num_of_checks, 
             :balance => balance }
 
    doc = { :database => 'invoice', :doc_id => id, :data => data}   
    Couchdb.update_doc doc,Ragios::DatabaseAdmin.session
    rescue CouchdbException => e
       billing_period = this_month + ', ' + this_year 
       data = {:username => @user, 
               :billing_period => billing_period, 
               :date_due => Chronic.parse('1st day next month'),
               :balance => charge_per_check,
               :url_monitoring => 1,
               :status => 'not_due',
             }
 
     doc = {:database => 'invoice', :doc_id => id, :data => data}
     Couchdb.create_doc doc,Ragios::DatabaseAdmin.session 
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


