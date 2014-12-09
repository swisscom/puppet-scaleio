require 'puppet'
require 'puppet/type/scaleio_protection_domain'
describe Puppet::Type.type(:scaleio_protection_domain) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_protection_domain).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept valid parameters' do
    @PDO = Puppet::Type.type(:scaleio_protection_domain).new({
        :name         => 'test-PDO',
      })
    expect(@PDO[:name]).to eq('test-PDO')
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_protection_domain).new({
        :name       => 'my PDO',
      })
    }.to raise_error Puppet::ResourceError, /not a valid value for Protection Domain name/
  end
end
