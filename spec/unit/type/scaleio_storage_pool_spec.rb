require 'puppet'
require 'puppet/type/scaleio_storage_pool'
describe Puppet::Type.type(:scaleio_storage_pool) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @pool = Puppet::Type.type(:scaleio_storage_pool).new({
        :name                     => 'test-PDO:myPool',
        :spare_policy             => '12%',
        :ensure                   => :present,
        :ramcache                 => 'enabled',
        :device_scanner_mode      => 'device_only',
        :device_scanner_bandwidth => 10240,
        :rfcache                  => 'enabled',
      })
    expect(@pool[:name]).to eq('test-PDO:myPool')
  end

  it 'should split composite namevar' do
    @pool = Puppet::Type.type(:scaleio_storage_pool).new({
        :name         => 'test-PDO:myPool',
        :spare_policy => '12%',
        :ensure       => 'present',
      })
    expect(@pool[:pool_name]).to eq('myPool')
    expect(@pool[:protection_domain]).to eq('test-PDO')
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
        :name         => 'myPDO:my Pool',
        :spare_policy => '12%',
        :ensure       => :present,
      })
    }.to raise_error Puppet::ResourceError, /not a valid value for storage pool/
  end

  it 'should require spare_policy' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
          :name         => 'test-PDO:myPool',
          :ensure       => 'present',
        })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should validate spare_policy' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
          :name         => 'test-PDO:myPool',
          :spare_policy => '12',
          :ensure       => 'present',
        })
    }.to raise_error Puppet::ResourceError, /not a valid value for the storage pool spare capacity/
  end

  it 'should validate device_scanner_mode' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
                                                       :name         => 'test-PDO:myPool',
                                                       :spare_policy => '12%',
                                                       :device_scanner_mode => 'adsf',
                                                       :ensure       => 'present',
                                                   })
    }.to raise_error Puppet::ResourceError, /Valid values for storage pool device scanner mode/
  end

  it 'should validate ramcache' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
          :name         => 'test-PDO:myPool',
          :ramcache     => 'xx',
          :ensure       => 'present',
        })
    }.to raise_error Puppet::ResourceError, /RAM cache for storage pool can either be enabled or disabled/
  end

  it 'should validate rfcache' do
    expect {
      Puppet::Type.type(:scaleio_storage_pool).new({
          :name         => 'test-PDO:myPool',
          :rfcache      => 'xx',
          :ensure       => 'present',
        })
    }.to raise_error Puppet::ResourceError, /rfcache for storage pool can either be enabled or disabled/
  end
end
