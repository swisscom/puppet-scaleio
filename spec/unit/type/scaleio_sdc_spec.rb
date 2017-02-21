require 'puppet'
require 'puppet/type/scaleio_sdc'
describe Puppet::Type.type(:scaleio_sdc) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_sdc).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @mdm = Puppet::Type.type(:scaleio_sdc).new({
        :ensure => :present,
        :name => '172.17.17.1',
        :desc => 'mySDC',
      })
    expect(@mdm[:name]).to eq('172.17.17.1')
    expect(@mdm[:desc]).to eq('mySDC')
  end

  it 'should require a description' do
    expect {
      Puppet::Type.type(:scaleio_sdc).new({
        :ensure => :present,
        :name   => '172.17.17.1',
        })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require a valid IP as name' do
    expect {
      Puppet::Type.type(:scaleio_sdc).new({
        :ensure => :present,
        :name   => '259.17.17.1',
        :desc   => 'mySDC',
        })
    }.to raise_error Puppet::ResourceError, /invalid address/
  end
end
