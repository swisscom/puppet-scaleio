require 'puppet'
require 'puppet/type/scaleio_sds'
describe Puppet::Type.type(:scaleio_sds) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @sds = Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :port              => 2342,
        :useconsul         => true,
        :ensure            => :present,
      })
    expect(@sds[:name]).to eq('mySDS')
    expect(@sds[:protection_domain]).to eq('myPDomain')
    expect(@sds[:ips]).to eq(['172.17.121.10'])
    expect(@sds[:pool_devices]).to eq({'myPool' => ['/dev/sda', '/dev/sdb']})
    expect(@sds[:port]).to eq(2342)
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS name',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /not a valid value for SDS/
  end

  it 'should require a protection domain' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :ips               => ['172.17.121.10'],
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require valid IP(s)' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['259.17.121.10'],
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /invalid address/
  end

  it 'should require pool devices' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :pool_devices      => ['/dev/sda', '/dev/sdb'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /pool_devices should be/
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :pool_devices      => '/dev/sda',
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /pool_devices should be/
  end

  it 'should deny a non digit port' do
    expect {
      Puppet::Type.type(:scaleio_sds).new({
        :name              => 'mySDS',
        :protection_domain => 'myPDomain',
        :ips               => ['172.17.121.10'],
        :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
        :port              => 'adf',
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /not a valid value for SDS port/
  end
end
