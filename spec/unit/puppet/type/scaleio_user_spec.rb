require 'puppet'
require 'puppet/type/scaleio_user'
describe Puppet::Type.type(:scaleio_user) do

  it 'should require a name' do
    expect {
      Puppet::Type.type(:scaleio_user).new({})
    }.to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it 'should accept valid parameters' do
    @PDO = Puppet::Type.type(:scaleio_user).new({
        :ensure       => :present,
        :name         => 'api',
        :password     => 'myPW',
        :role         => 'Monitor',
      })
    expect(@PDO[:name]).to eq('api')
    expect(@PDO[:password]).to eq('myPW')
    expect(@PDO[:role]).to eq('Monitor')
  end

  it 'should not accept name with whitespaces' do
    expect {
      Puppet::Type.type(:scaleio_user).new({
        :ensure     => :present,
        :name       => 'api test',
        :password   => 'myPW',
        :role       => 'Monitor',
      })
    }.to raise_error(Puppet::ResourceError, /not a valid value for a user name/)
  end

  it 'should require a password' do
    expect {
      Puppet::Type.type(:scaleio_user).new({
        :ensure     => :present,
        :name       => 'api',
        :role       => 'Monitor',
      })
    }.to raise_error(Puppet::ResourceError, /parameter 'password' is required/)
  end

  it 'should require a role' do
    expect {
      Puppet::Type.type(:scaleio_user).new({
        :ensure     => :present,
        :name       => 'api',
        :password   => 'myPW',
      })
    }.to raise_error(Puppet::ResourceError, /parameter 'role' is required/)
  end

  it 'should require a valid role' do
    expect {
      Puppet::Type.type(:scaleio_user).new({
        :ensure     => :present,
        :name       => 'api',
        :password   => 'myPW',
        :role       => 'customrole',
      })
    }.to raise_error(Puppet::ResourceError, /is not a valid role/)
  end
end
