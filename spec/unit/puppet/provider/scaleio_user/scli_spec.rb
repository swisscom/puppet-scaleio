require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_user).provider(:scaleio_user)
all_properties = [
]

describe provider_class do

  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:users_one)       { File.read(File.join(fixtures_cli,"users_one.cli")) }
  let(:users_two)       { File.read(File.join(fixtures_cli,"users_two.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_user).new({
      :ensure       => :present,
      :name         => 'api',
      :password     => 'myPW',
      :role         => 'Monitor',
      :provider     => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource        = stub 'resource'
      @user_name = "api_test"
      @role      = "Configure"
      @password  = "newPW"
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @user_name
      @resource.stubs(:[]).with(:role).returns @role
      @resource.stubs(:[]).with(:password).returns @password
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_user[#{@user_name}]"
      @provider = provider_class.new(@resource)
    end
    it("should have a create method")   { @provider.should respond_to(:create)  }
    it("should have a destroy method")  { @provider.should respond_to(:destroy) }
    it("should have an exists? method") { @provider.should respond_to(:exists?) }
    all_properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        @provider.should respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        @provider.should respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    it 'returns an array w/ no users' do
      provider.class.stubs(:scli).with('--query_users').returns(users_one)
      user_instances = provider.class.instances
      user_names      = user_instances.collect {|x| x.name }
      expect(['admin']).to match_array(user_names)
    end
    it 'returns an array w/ 2 users' do
      provider.class.stubs(:scli).with('--query_users').returns(users_two)
      user_instances = provider.class.instances
      user_names     = user_instances.collect {|x| x.name }
      expect(['callhome', 'admin']).to match_array(user_names)
    end
  end

  describe 'create' do
    it 'creates a user' do
      provider.expects(:add_scaleio_user).with('api', 'Monitor', 'myPW').returns([])
      provider.create
    end
  end

  describe 'change_password=' do
    it 'updates a password' do
      provider.expects(:change_scaleio_password).with('api', 'myPW').returns([])
      provider.change_password=(true)
    end
  end

  describe 'destroy' do
    it 'destroys a user' do
      provider.expects(:scli).with('--delete_user', '--username', 'api').returns([])
      provider.destroy
    end
  end
end
