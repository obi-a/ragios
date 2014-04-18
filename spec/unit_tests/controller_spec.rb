require 'spec_base.rb'

module Ragios
  module Notifier
    class MockNotifier
      def initialize(monitor)
      end
      def failed(test_result)
      end
      def resolved(test_result)
      end
    end
 end
end

module Ragios
  module Plugin
    class MockPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        @test_result = :test_passed
        return true
      end
    end
  end
end

class MockModel
  attr_accessor :messages
  def initialize()
    @messages = []
  end

  def save(*args)
    @messages << :save
  end

  def update(*args)
    @messages << :update
  end

  def active_monitors
    @messages << :active_monitors
    [{:monitor => 'something', :via => 'mock_notifier', :plugin => 'mock_plugin', :every => '5m', :_id => 'monitor_id'}]
  end

  def where(options)
    @messages << :where
    data = [[{:monitor => 'website 1',:via => 'mock_notifier', :plugin => 'mock_plugin', :every => '5m', :_id => '0', :status_ => 'active'}], [{:monitor => 'website 1',:via => 'mock_notifier', :plugin => 'mock_plugin', :every => '5m', :_id => '1', :status_ => 'stopped'}],[] ]
    return data[options[:_id]]
  end

  def find(monitor_id)
    @messages << :find
    data = [{:monitor => 'website 1',:via => 'mock_notifier', :plugin => 'mock_plugin', :every => '5m', :_id => '0', :status_ => 'active'}, {:monitor => 'website 1',:via => 'mock_notifier', :plugin => 'mock_plugin', :every => '5m', :_id => '1', :status_ => 'stopped'}]
    return data[monitor_id]
  end

  def delete(*args)
    @messages << :delete
  end
end

class MockLogger
  attr_accessor :messages
  def initialize
    @messages = []
  end

  def log(*args)
    @messages << :log
  end
end

class MockScheduler
  attr_accessor :messages
  def initialize
    @messages = []
  end

  def schedule(*args)
    @messages << :schedule
  end

  def stop(*args)
    @messages << :stop
  end
end

controller = Ragios::Controller

controller.model(MockModel.new)
controller.logger(MockLogger.new)
controller.scheduler(MockScheduler.new)

model = Ragios::Controller.model
logger = Ragios::Controller.logger
scheduler = Ragios::Controller.scheduler

Active = 0
Inactive = 1
Dont_exist = 2

describe "controller behavior" do
  after(:each) do
    model.messages = []
    scheduler.messages = []
    model.messages = []
    logger.messages = []
  end

  it "should add a monitor" do

    monitor = {monitor: "something",
               via: "mock_notifier",
               plugin: "mock_plugin" }

    generic_monitors = controller.add([monitor])
    generic_monitors.first.options.should include(:_id,:created_at_)
    generic_monitors.first.options.should include(:status_ => 'active')

    model.messages.should == [:save,:update]
    scheduler.messages.should == [:schedule]
    logger.messages.should == [:log]
  end

  it "should restart all monitors from database" do
    generic_monitors = controller.restart_all
    generic_monitors.first.id.should == 'monitor_id'
    generic_monitors.length.should == 1
    model.messages.should == [:active_monitors,:update]
    scheduler.messages.should == [:schedule]
    logger.messages.should == [:log]
  end

  it "should not restart an already active monitor" do
    monitor = controller.restart(Active)
    monitor.should == MockModel.new.find(Active)

    model.messages.should == [:find]
    scheduler.messages.should_not include(:schedule)
    logger.messages.should_not include(:log)
  end

  it "should restart an inactive monitor" do
    monitor = controller.restart(Inactive)
    monitor[:_id].should == Inactive.to_s

    model.messages.should  == [:find,:update]
    scheduler.messages.should == [:schedule]
    logger.messages.should == [:log]
  end

  it "cannot restart a monitor that doesn't exist" do
    expect { controller.restart(Dont_exist) }.to raise_error

    model.messages.should == [:find]
    scheduler.messages.should_not include(:schedule)
    logger.messages.should_not include(:log)
  end

  it "should stop a running monitor" do
    controller.stop(Active)
    scheduler.messages.should == [:stop]
    model.messages.should == [:update]
  end

  it "should attempt to stop an already stopped monitor" do
    controller.stop(Inactive)
    scheduler.messages.should == [:stop]
    model.messages.should == [:update]
  end

  it "should delete a running monitor" do
    controller.delete(Active)
    model.messages.should == [:find,:update,:delete]
    scheduler.messages.should == [:stop]
  end

  it "should delete a stopped monitor" do
    controller.delete(Inactive)
    model.messages.should == [:find,:delete]
    scheduler.messages.should == []
  end

  it "should attempt to delete a deleted monitor" do
    expect { controller.delete(Dont_exist) }.to raise_error
    model.messages.should == [:find]
    scheduler.messages.should == []
  end

  it "should perform a test" do
    options = {monitor: "something",
               via: "mock_notifier",
               plugin: "mock_plugin" }
    generic_monitor = Ragios::GenericMonitor.new(options)
    generic_monitor.state.should == "pending"
    controller.perform(generic_monitor)
    model.messages.should == [:update]
    logger.messages.should == [:log]
    generic_monitor.state.should == "passed"
  end

  it "should test a monitor with given id" do
    controller.test_now(Active)
    model.messages.should == [:find,:update]
    logger.messages.should == [:log]
  end

  it "should update an active monitor" do
    controller.update(Active,{every: '10m'})
    model.messages.should include(:update,:find)
    scheduler.messages.should include(:stop)
  end

  it "should update an inactive monitor" do
    controller.update(Inactive,{every: '10m'})
    model.messages.should == [:update,:find]
    scheduler.messages.should_not == [:stop]
  end

  it "should run monitors without persistence" do
    monitor = {monitor: "something",
               via: "mock_notifier",
               plugin: "mock_plugin" }

    controller.run([monitor])

    model.messages.should_not include(:save,:update)
    scheduler.messages.should == [:schedule]
    logger.messages.should_not include(:log)
  end
end
