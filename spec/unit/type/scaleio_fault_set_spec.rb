require 'puppet'
require 'puppet/type/scaleio_fault_set'
describe Puppet::Type.type(:scaleio_fault_set) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_fault_set).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @fault_set = Puppet::Type.type(:scaleio_fault_set).new({
        :name         => 'test-PDO:myFaultSet',
        :ensure       => :present,
      })
    expect(@fault_set[:name]).to eq('test-PDO:myFaultSet')
  end

  it 'should split composite namevar' do
    @fault_set = Puppet::Type.type(:scaleio_fault_set).new({
        :name         => 'test-PDO:myFaultSet',
        :ensure       => 'present',
      })
    expect(@fault_set[:fault_set_name]).to eq('myFaultSet')
    expect(@fault_set[:protection_domain]).to eq('test-PDO')
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_fault_set).new({
        :name         => 'myPDO:my FaultSet',
        :ensure       => :present,
      })
    }.to raise_error Puppet::ResourceError, /not a valid value for fault set/
  end
end
