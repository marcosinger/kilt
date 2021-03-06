require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Kilt do
  context "on init with a token" do
    before :each do
      Rufus::Scheduler.stub(:start_new).and_return(@scheduler = mock(Object, :every => nil))
    end

    it "should save the date of the latest activity" do
      client = Kilt.init '123456789' 
      client.date_last_activity.should == Time.utc(2010,"mar",17,21,48,15)
    end

    it "should request the feed with the token" do
      token = '34g43g4334g43g43'
      RestClient.should_receive(:get) do |url, opts|
        opts['X-TrackerToken'].should eql(token)
        mock(Object, :body => latests_activities)
      end
      Kilt.init token
    end

    it "should fetch new activities every 30 seconds" do
      @scheduler.should_receive(:every).with('30s')
      Kilt.init 'fegegege'
    end

    it "should fetch new activities" do
      @scheduler.stub(:every) do |time, block|
        block.call
      end
      RestClient.should_receive(:get).exactly(2).times do
        mock(Object, :body => latests_activities)
      end
      Kilt.init 'fegegege'
    end
  end

  context "on update" do
    before :each do
      @client = Kilt.init('fake')
      @client.stub! :system
      @client.instance_variable_set "@date_last_activity", Time.utc(2010,"mar",17,21,44,42)
    end

    it "should get the new activities and update the date last activity" do
      @client.update
      @client.date_last_activity.should == Time.utc(2010,"mar",17,21,48,15)
    end

    it "should notifify about each new activity" do
      @client.should_receive(:system).exactly(2).times
      @client.update
    end

    context "on os x" do
      before :all do
        silence_warnings { RUBY_PLATFORM = "darwin" }
      end

      it "should notify growl calling growlnotify with 'Pivotal Tracker' as the name the application, the author and the action" do
        regexp = /growlnotify -t \'Pivotal Tracker\' -m \'\S+. finished lorem ipsum\' --image \S+.pivotal\.png/
        @client.should_receive(:system).with(regexp)
        @client.update
      end

      it "should notify newer activities at least" do
        regexp = /growlnotify -t \'Pivotal Tracker\' -m \'SpongeBog finished lorem ipsum\' --image \S+.pivotal\.png/
        regexp2 = /growlnotify -t \'Pivotal Tracker\' -m \'Superman finished lorem ipsum\' --image \S+.pivotal\.png/
        @client.should_receive(:system).with(regexp).ordered
        @client.should_receive(:system).with(regexp2).ordered
        @client.update
      end
    end

    context "on linux" do
      before :all do
        silence_warnings { RUBY_PLATFORM = "linux" }
      end

      it "should notify libnotify calling notify-send with 'Pivotal Tracker' as the name the application, the author and the action" do
        regexp = /notify-send \'Pivotal Tracker\' \'\S+. finished lorem ipsum\' --icon \S+.pivotal\.png/
        @client.should_receive(:system).with(regexp)
        @client.update
      end

      it "should notify newer activities at least" do
        regexp = /notify-send \'Pivotal Tracker\' \'SpongeBog finished lorem ipsum\' --icon \S+.pivotal\.png/
        regexp2 = /notify-send \'Pivotal Tracker\' \'Superman finished lorem ipsum\' --icon \S+.pivotal\.png/
        @client.should_receive(:system).with(regexp).ordered
        @client.should_receive(:system).with(regexp2).ordered
        @client.update
      end
    end
    
    #FIXME SNARL completamente pirado. Cada hora joga uma mensagem diferente
    # context "on windows" do
    #   before :all do
    #     silence_warnings { RUBY_PLATFORM = "mswin" }
    #     Kilt.const_set(:Snarl, @snarl = mock)
    #   end
    # 
    #   it "should notify Snarl calling show_message with 'Pivotal Tracker' as the name the application, the author and the action" do
    #     @snarl.should_receive(:show_message).with('Pivotal Tracker', /\S+ finished lorem ipsum/, /\S+.pivotal\.png/).twice
    #     @client.update
    #   end
    # 
    #   it "should notify newer activities at least" do
    #     @snarl.should_receive(:show_message).with('Pivotal Tracker', 'SpongeBog finished lorem ipsum', /\S+.pivotal\.png/).ordered
    #     @snarl.should_receive(:show_message).with('Pivotal Tracker', 'Superman finished lorem ipsum', /\S+.pivotal\.png/).ordered
    #     @client.update
    #   end
    # end 
  end
end
