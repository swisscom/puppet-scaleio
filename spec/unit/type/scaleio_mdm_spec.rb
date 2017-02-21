require 'puppet'
require 'puppet/type/scaleio_mdm'

describe Puppet::Type.type(:scaleio_mdm) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_mdm).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @mdm = Puppet::Type.type(:scaleio_mdm).new({
                                                        :ensure => :present,
                                                        :name => 'mdm-1',
                                                        :ips => ['192.168.1.1'],
                                                        :is_tiebreaker => true,
                                                        :mgmt_ips => ['192.168.2.1'],
                                                    })
    expect(@mdm[:name]).to eq('mdm-1')
    expect(@mdm[:ips]).to eq(['192.168.1.1'])
    expect(@mdm[:mgmt_ips]).to eq(['192.168.2.1'])
    expect(@mdm[:is_tiebreaker]).to eq(true)
  end

  it 'should require is_tiebreaker' do
    expect {
      Puppet::Type.type(:scaleio_mdm).new({
                                              :ensure => :present,
                                              :name => 'mdm-1',
                                              :ips => ['192.168.1.1'],
                                          })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require an IP' do
    expect {
      Puppet::Type.type(:scaleio_mdm).new({
                                              :ensure => :present,
                                              :name => 'mdm-1',
                                              :is_tiebreaker => true,
                                          })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require a valid IP' do
    expect {
      Puppet::Type.type(:scaleio_mdm).new({
                                              :ensure => :present,
                                              :name => 'mdm-1',
                                              :is_tiebreaker => true,
                                              :ips => ['260.168.1.1'],
                                          })
    }.to raise_error Puppet::ResourceError, /invalid address/
  end

  it 'should require a valid mgmt IP' do
    expect {
      Puppet::Type.type(:scaleio_mdm).new({
                                              :ensure => :present,
                                              :name => 'mdm-1',
                                              :is_tiebreaker => true,
                                              :ips => ['192.168.1.1'],
                                              :mgmt_ips => ['260.168.1.1'],
                                          })
    }.to raise_error Puppet::ResourceError, /invalid address/
  end
end
