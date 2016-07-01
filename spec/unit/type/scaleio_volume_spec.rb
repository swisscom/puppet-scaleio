require 'puppet'
require 'puppet/type/scaleio_volume'
describe Puppet::Type.type(:scaleio_volume) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @volume = Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 504,
        :type              => 'thin',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
      })
    expect(@volume[:name]).to eq('myVol')
    expect(@volume[:protection_domain]).to eq('myPDomain')
    expect(@volume[:storage_pool]).to eq('myPool')
    expect(@volume[:size]).to eq(504)
    expect(@volume[:type]).to eq('thin')
    expect(@volume[:sdc_nodes]).to eq(['sdc1', 'sdc2'])
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol name',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 504,
        :type              => 'thin',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /not a valid value for volume/
  end

  it 'should require a storage pool' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :size              => 504,
        :type              => 'thin',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require a protection domain' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :storage_pool      => 'myPool',
        :size              => 504,
        :type              => 'thin',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require a valid type' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 504,
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /is required/
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 504,
        :type              => 'adsfadsf',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
        })
    }.to raise_error Puppet::ResourceError, /must be either thin or thick/

    # check for allowing thick
    Puppet::Type.type(:scaleio_volume).new({
      :name              => 'myVol',
      :protection_domain => 'myPDomain',
      :storage_pool      => 'myPool',
      :size              => 504,
      :type              => 'thick',
      :sdc_nodes         => ['sdc1', 'sdc2'],
      :ensure            => :present,
      })
  end

  it 'should deny a size that is not a multiple of 8 or smaller than 0' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => -504,
        :type              => 'thick',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /multiple of 8/
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 345,
        :type              => 'thick',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /multiple of 8/
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :type              => 'thick',
        :sdc_nodes         => ['sdc1', 'sdc2'],
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'validate sdc node names' do
    expect {
      Puppet::Type.type(:scaleio_volume).new({
        :name              => 'myVol',
        :protection_domain => 'myPDomain',
        :storage_pool      => 'myPool',
        :size              => 504,
        :type              => 'thick',
        :sdc_nodes         => ['sdc 9'],
        :ensure            => :present,
      })
    }.to raise_error Puppet::ResourceError, /is not a valid SDC name/
  end
end
