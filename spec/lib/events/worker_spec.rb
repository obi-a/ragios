require 'spec_base.rb'

describe Ragios::Events::Worker do
  describe "#perform" do
    context "when valid event details are sent" do
      it "logs the event to the database" do

        event_details = {
          monitor_id: "586ad8aa-bc29-41a1-935b-f48031c72d90",
          event: {},
          state: "triggered",
          time: "2017-09-02T00:40:18Z",
          type: "event",
          event_type: "monitor.triggered"
        }

        @worker = Ragios::Events::Worker.new
        model = @worker.send(:model)
        expect(model).to receive(:save).with(kind_of(String), event_details)
        @worker.perform(JSON.generate(event_details))
      end
    end
  end
end
