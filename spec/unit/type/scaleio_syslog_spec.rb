require 'spec_helper'
require 'puppet'
require 'puppet/type/scaleio_syslog'
describe Puppet::Type.type(:scaleio_syslog) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_syslog).new({})
    }.to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it 'should accept valid parameters' do
    Resolv.expects(:getaddresses).with('log-host.local').returns(['::1','192.168.2.2'])
    @PDO = Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log-host.local',
        :port         => '43534',
      })
    expect(@PDO[:name]).to eq('192.168.2.2')
    expect(@PDO[:port]).to eq('43534')
  end

  it 'should not accept a syslog destination with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log host.local',
        :port         => '43534',
      })
    }.to raise_error(Puppet::ResourceError, /is not a valid syslog destination./)
  end

  it 'should require a port' do
    Resolv.expects(:getaddresses).with('log-host.local').returns(['192.168.2.2','::1'])
    expect {
      Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log-host.local',
      })
    }.to raise_error(Puppet::ResourceError, /parameter 'port' is required/)
  end

  it 'should require a valid role' do
    Resolv.expects(:getaddresses).with('log-host.local').returns(['192.168.2.2','::1'])
    expect {
      Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log-host.local',
        :port         => 'fdas',
      })
    }.to raise_error(Puppet::ResourceError, /Syslog destination port must be a number/)
  end

  it 'should accept a facility' do
    Resolv.expects(:getaddresses).with('log-host.local').returns(['::1','192.168.2.2'])
    @PDO = Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log-host.local',
        :port         => '1564',
        :facility     => '15',
      })
    expect(@PDO[:facility]).to eq('15')
  end

  it 'should deny a wrong facility' do
    Resolv.expects(:getaddresses).with('log-host.local').returns(['::1','192.168.2.2'])
    expect {
      Puppet::Type.type(:scaleio_syslog).new({
        :ensure       => :present,
        :name         => 'log-host.local',
        :port         => '541',
        :facility     => '17',
      })
    }.to raise_error(Puppet::ResourceError, /is not a valid syslog facility/)
  end
end
