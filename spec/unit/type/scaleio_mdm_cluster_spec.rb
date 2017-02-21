require 'puppet'
require 'puppet/type/scaleio_mdm_cluster'

describe Puppet::Type.type(:scaleio_mdm_cluster) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_mdm_cluster).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @mdm = Puppet::Type.type(:scaleio_mdm_cluster).new({
                                                        :ensure => :present,
                                                        :name => 'mdm_cluster',
                                                        :mdm_names => ['mdm-1', 'mdm-2'],
                                                        :tb_names => ['mdm-3'],
                                                    })
    expect(@mdm[:name]).to eq('mdm_cluster')
    expect(@mdm[:mdm_names]).to eq(['mdm-1', 'mdm-2'])
    expect(@mdm[:tb_names]).to eq(['mdm-3'])
  end

  it 'should require tb_names' do
    expect {
      Puppet::Type.type(:scaleio_mdm_cluster).new({
                                              :ensure => :present,
                                              :name => 'mdm_cluster',
                                              :mdm_names => ['mdm-1', 'mdm-2'],
                                          })
    }.to raise_error Puppet::ResourceError, /is required/
  end

  it 'should require mdm_names' do
    expect {
      Puppet::Type.type(:scaleio_mdm_cluster).new({
                                              :ensure => :present,
                                              :name => 'mdm_cluster',
                                              :tb_names => ['mdm-3'],
                                          })
    }.to raise_error Puppet::ResourceError, /is required/
  end
end
