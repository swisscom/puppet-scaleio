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
        :name         => 'test-PDO:myPool',
        :spare_policy => '12%',
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
end
