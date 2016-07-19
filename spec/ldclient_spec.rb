require "spec_helper"


describe LaunchDarkly::LDClient do
  subject { LaunchDarkly::LDClient }
  let(:config) { LaunchDarkly::Config.new({:offline => true}) }  
  let(:client) do
    subject.new("api_key", config)
  end
  let(:feature) do
    data = File.read(File.join("spec", "fixtures", "feature.json"))
    JSON.parse(data, symbolize_names: true)
  end
  let(:user) do
    data = File.read(File.join("spec", "fixtures", "user.json"))
    JSON.parse(data, symbolize_names: true)
  end
  let(:numeric_key_user) do
    data = File.read(File.join("spec", "fixtures", "numeric_key_user.json"))
    JSON.parse(data, symbolize_names: true)
  end
  let(:sanitized_numeric_key_user) do
    data = File.read(File.join("spec", "fixtures", "sanitized_numeric_key_user.json"))
    JSON.parse(data, symbolize_names: true)
  end

  describe '#toggle?' do
    it "will return the default value if the client is offline" do
      result = client.toggle?(feature[:key], user, "default")
      expect(result).to eq "default"
    end
  end

  describe '#track' do 
    it "queues up an custom event" do
      expect(client.instance_variable_get(:@event_processor)).to receive(:add_event).with(hash_including(kind: "custom", key: "custom_event_name", user: user, data: 42))
      client.track("custom_event_name", user, 42)
    end
    it "sanitizes the user in the event" do
      expect(client.instance_variable_get(:@event_processor)).to receive(:add_event).with(hash_including(user: sanitized_numeric_key_user))
      client.track("custom_event_name", numeric_key_user, nil)
    end
  end

  describe '#identify' do 
    it "queues up an identify event" do
      expect(client.instance_variable_get(:@event_processor)).to receive(:add_event).with(hash_including(kind: "identify", key: user[:key], user: user))
      client.identify(user)
    end
    it "sanitizes the user in the event" do
      expect(client.instance_variable_get(:@event_processor)).to receive(:add_event).with(hash_including(user: sanitized_numeric_key_user))
      client.identify(numeric_key_user)
    end
  end

  describe '#log_exception' do
    it "log error data" do
      expect(client.instance_variable_get(:@config).logger).to receive(:error)
      begin
        raise StandardError.new 'asdf'
      rescue StandardError => exn
        client.send(:log_exception, 'caller', exn)
      end
    end
  end
end