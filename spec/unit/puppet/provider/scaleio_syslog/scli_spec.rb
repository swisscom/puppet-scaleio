require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_syslog).provider(:scaleio_syslog)
all_properties = [
]

describe provider_class do

  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:syslog_no)       { File.read(File.join(fixtures_cli,"syslog_no_destinations.cli")) }
  let(:syslog_two)      { File.read(File.join(fixtures_cli,"syslog_two_destinations.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_syslog).new({
      :ensure       => :present,
      :name         => 'log-host.local',
      :port         => '1564',
      :facility     => '15',
      :provider     => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource        = stub 'resource'
      @syslog_name     = "log-host.local"
      @syslog_ip       = "192.168.2.2"
      @port            = "48749"
      @facility        = "12"
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @syslog_ip
      @resource.stubs(:[]).with(:port).returns @port
      @resource.stubs(:[]).with(:facility).returns @facility
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_syslog[#{@syslog_name}]"
      @provider = provider_class.new(@resource)
    end
    it("should have a create method")   { @provider.should respond_to(:create)  }
    it("should have a destroy method")  { @provider.should respond_to(:destroy) }
    it("should have an exists? method") { @provider.should respond_to(:exists?) }
    all_properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        @provider.should respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        @provider.should respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    it 'returns an array w/ no syslog destinations' do
     Resolv.stubs(:getaddress).with('log-host.local').returns('192.168.2.2')
      provider.class.stubs(:scli).with('--query_remote_syslog').returns(syslog_no)
      syslog_instances  = provider.class.instances
      syslog_names      = syslog_instances.collect {|x| x.name }
      expect([]).to match_array(syslog_names)
    end
    it 'returns an array w/ 2 syslog destinations' do
      Resolv.stubs(:getaddress).with('log-host.local').returns('192.168.2.2')
      Resolv.stubs(:getaddress).with('192.168.56.200').returns('192.168.56.200')
      Resolv.stubs(:getaddress).with('127.127.127.127').returns('127.127.127.127')
      provider.class.stubs(:scli).with('--query_remote_syslog').returns(syslog_two)
      syslog_instances = provider.class.instances
      syslog_names     = syslog_instances.collect {|x| x.name }
      expect(['127.127.127.127', '192.168.56.200']).to match_array(syslog_names)
    end
  end

  describe 'create' do
    it 'creates a syslog' do
      Resolv.stubs(:getaddress).returns('192.168.2.2')
      provider.expects(:scli).with('--stop_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2').returns([])
      provider.expects(:scli).with('--start_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2', '--remote_syslog_server_port', '1564', '--syslog_facility', '15').returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'destroys a syslog' do
      Resolv.stubs(:getaddress).returns('192.168.2.2')
      provider.expects(:scli).with('--stop_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2').returns([])
      provider.destroy
    end
  end
end
