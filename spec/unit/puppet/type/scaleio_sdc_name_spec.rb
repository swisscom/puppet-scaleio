require 'puppet'
require 'puppet/type/scaleio_sdc_name'
describe Puppet::Type.type(:scaleio_sdc_name) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_sdc_name).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @sdc_name = Puppet::Type.type(:scaleio_sdc_name).new({
        :ensure => :present,
        :name => '172.17.17.1',
        :desc => 'mySDC',
      })
    expect(@sdc_name[:name]).to eq('172.17.17.1')
    expect(@sdc_name[:desc]).to eq('mySDC')
  end

  it 'should require a description' do
    expect {
			Puppet::Type.type(:scaleio_sdc_name).new({
        :ensure => :present,
        :name   => '172.17.17.1',
				})
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require a valid IP as name' do
    expect {
			Puppet::Type.type(:scaleio_sdc_name).new({
        :ensure => :present,
        :name   => '259.17.17.1',
        :desc   => 'mySDC',
				})
    }.to raise_error Puppet::ResourceError, /invalid address/
  end
end
