require 'spec_base.rb'

describe Ragios::RecurringJobs::Scheduler do
  before(:each) do
    @scheduler = Ragios::RecurringJobs::Scheduler.new(skip_actor_creation = true)
  end

  describe "#perform" do
    context "when scheduler responds to action" do
      it "sends message to action" do
        %w(run_now_and_schedule schedule_and_run_later trigger_work unschedule).each do |action|
          options = {
            monitor_id: SecureRandom.uuid,
            perform: action
          }
          options_array = [JSON.generate(options)]
          expect(@scheduler).to receive(action).with(options)
          @scheduler.perform(options_array)
        end
      end
    end
    context "when scheduler does not respond to action" do
      it "stays silent, does not send message" do
        action = "unknown"
        options = {
          monitor_id: SecureRandom.uuid,
          perform: action
        }
        options_array = [JSON.generate(options)]
        expect(@scheduler).not_to receive(action)
        expect(@scheduler.perform(options_array)).to be_nil
      end
    end
  end

  describe "#trigger_work" do
    pending "pushes work to the worker and logs event"
  end
  describe "#unschedule" do
    context "when monitor_id is provided" do
      context "when monitor's recurring job is found" do
        it "unschedules the job" do
          options = {interval: "5d", monitor_id: SecureRandom.uuid}
          @scheduler.schedule(:interval, options)
          expect(@scheduler.internal_scheduler.jobs.count).to eq(1)
          @scheduler.unschedule(options)
          expect(@scheduler.internal_scheduler.jobs.count).to eq(0)
        end
        context "when job is already unscheduled" do
          it "stays silent" do
            options = {interval: "5d", monitor_id: SecureRandom.uuid}
            @scheduler.schedule(:interval, options)
            job = @scheduler.internal_scheduler.jobs.first
            job.unschedule
            expect(@scheduler.internal_scheduler.jobs.count).to eq(0)
            @scheduler.unschedule(options)
            expect(@scheduler.internal_scheduler.jobs.count).to eq(0)
          end
        end
      end
      context "when monitor's recurring job is not found" do
        it "does not unschedule, it is silent" do
          options = {interval: "5d", monitor_id: SecureRandom.uuid}
          @scheduler.schedule(:interval, options)
          expect(@scheduler.internal_scheduler.jobs.count).to eq(1)
          @scheduler.unschedule({monitor_id: "not_found"})
          expect(@scheduler.internal_scheduler.jobs.count).to eq(1)
        end
      end
    end
  end
  describe "#find" do
    context "when tag is found" do
      it "returns all recurring jobs with the tag" do
        options = {interval: "5d", monitor_id: SecureRandom.uuid}
        @scheduler.schedule(:interval, options)
        expect(@scheduler.find(options[:monitor_id])).to eq(@scheduler.internal_scheduler.jobs)
      end
    end
    context "when tag is not found" do
      it "returns an empty array" do
        @scheduler.schedule(:interval, interval: "5d", monitor_id: SecureRandom.uuid)
        expect(@scheduler.find("not_found")).to eq([])
      end
    end
  end
  describe "#run_now_and_schedule" do
    it "delegates interval_jobs to scheduler" do
      # interval_jobs: runs right now and then schedules to run at the intervals
      options = {interval: "5h"}
      expect(@scheduler).to receive(:schedule).with(:interval, options)
      @scheduler.run_now_and_schedule(options)
    end
  end
  describe "#schedule_and_run_later" do
    it "delegates every_jobs to scheduler" do
      # every_jobs: schedules and runs at the intervals
      options = {interval: "5h"}
      expect(@scheduler).to receive(:schedule).with(:every, options)
      @scheduler.schedule_and_run_later(options)
    end
  end
  describe "#schedule" do
    context "when a valid scheduler_type is provided" do
      context "when a valid interval is provided"  do
        context "when an every job is provided" do
          it "schedules an every job and triggers work at the interval" do
            options = {interval: "9h"}
            @scheduler.schedule(:every, options)
            job = @scheduler.internal_scheduler.jobs.first
            expect(job).to be_a(Rufus::Scheduler::EveryJob)
            expect(job.original).to eq(options[:interval])
            expect(@scheduler).to receive(:trigger_work).with(options)
            job.callable.call
          end
        end
        context "when an interval job is provided" do
          it "schedules an interval job and triggers work at the interval" do
            options = {interval: "8h"}
            @scheduler.schedule(:interval, options)
            job = @scheduler.internal_scheduler.jobs.first
            expect(job).to be_a(Rufus::Scheduler::IntervalJob)
            expect(job.original).to eq(options[:interval])
            expect(@scheduler).to receive(:trigger_work).with(options)
            job.callable.call
          end
        end
        context "when a monitor_id is provided" do
          it "tags the scheduled job with the monitor id" do
            options = {interval: "1h", monitor_id: SecureRandom.uuid}
            @scheduler.schedule(:interval, options)
            jobs = @scheduler.internal_scheduler.jobs(tag: options[:monitor_id])
            expect(jobs.count).to eq(1)
            job = jobs.first
            expect(job).to be_a(Rufus::Scheduler::IntervalJob)
            expect(job.tags.first).to eq(options[:monitor_id])
          end
        end
      end
      context "when a valid interval is not provided" do
        it "raises an error" do
          expect{ @scheduler.schedule(:interval, interval: nil) }.to raise_error(ArgumentError, /cannot schedule/)
        end
      end
    end
    context "when a valid scheduler is not provided" do
      context "when a valid interval is provided" do
        it "raises an exception" do
          expect{ @scheduler.schedule(:not_found, interval: "5m") }.to raise_error(
            ArgumentError, "Unrecognized scheduler_type not_found"
          )
        end
      end
    end
  end
end
