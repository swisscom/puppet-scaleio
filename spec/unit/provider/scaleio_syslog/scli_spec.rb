require 'spec_helper'

describe Puppet::Type.type(:scaleio_syslog).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_syslog).new(
      {
          :ensure => :present,
          :name => 'log-host.local',
          :port => '1564',
          :facility => '15',
      }
  ) }

  let(:no_syslogs) { my_fixture_read('syslog_no_destinations.cli') }
  let(:two_syslogs) { my_fixture_read('syslog_two_destinations.cli') }

  describe 'basics' do
    properties = []

    it("should have a create method") { expect(provider).to respond_to(:create) }
    it("should have a destroy method") { expect(provider).to respond_to(:destroy) }
    it("should have an exists? method") { expect(provider).to respond_to(:exists?) }
    properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        expect(provider).to respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        expect(provider).to respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    it 'returns an array with no syslog destinations' do
      provider.class.stubs(:scli).with('--query_remote_syslog').returns(no_syslogs)
      syslog_instances = provider.class.instances
      syslog_names = syslog_instances.collect { |x| x.name }
      expect([]).to match_array(syslog_names)
    end
    it 'returns an array w/ 2 syslog destinations' do
      Resolv.stubs(:getaddresses).with('log-host.local').returns(['192.168.2.2', '::1'])
      Resolv.stubs(:getaddresses).with('192.168.56.200').returns(['::1', '192.168.56.200'])
      Resolv.stubs(:getaddresses).with('127.127.127.127').returns(['::1', '127.127.127.127'])
      provider.class.stubs(:scli).with('--query_remote_syslog').returns(two_syslogs)
      syslog_instances = provider.class.instances
      syslog_names = syslog_instances.collect { |x| x.name }
      expect(['127.127.127.127', '192.168.56.200']).to match_array(syslog_names)
    end
  end

  describe 'create' do
    it 'creates a syslog' do
      Resolv.stubs(:getaddresses).returns(['192.168.2.2', '::1'])
      provider.expects(:scli).with('--stop_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2').returns([])
      provider.expects(:scli).with('--start_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2', '--remote_syslog_server_port', '1564', '--syslog_facility', '15').returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'destroys a syslog' do
      Resolv.stubs(:getaddresses).returns(['::1', '192.168.2.2'])
      provider.expects(:scli).with('--stop_remote_syslog', '--remote_syslog_server_ip', '192.168.2.2').returns([])
      provider.destroy
    end
  end
end
