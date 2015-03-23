require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_storage_pool).provider(:scaleio_storage_pool)
all_properties = [
  :spare_policy,
]

describe provider_class do

  # load sample cli outputs
  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:myPool)          { File.read(File.join(fixtures_cli,"pool_query_myPDomain_myPool.cli")) }
  let(:myPool2)         { File.read(File.join(fixtures_cli,"pool_query_myPDomain_myPool2.cli")) }
  let(:myPDomain)       { File.read(File.join(fixtures_cli,"pool_query_myPDomain.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_storage_pool).new({
      :ensure       => :present,
      :name         => 'myPDomain:myNewPool',
      :spare_policy => '34%',
      :provider     => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource     = stub 'resource'
      @pool_name    = "myNewPool"
      @protection_domain = "myPDomain"
      @name          = "#{@protection_domain}:#{@pool_name}"
      @spare_policy  = "8%"
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @name
      @resource.stubs(:[]).with(:pool_name).returns @pool_name
      @resource.stubs(:[]).with(:protection_domain).returns @protection_domain
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:[]).with(:zeropadding).returns true
      @resource.stubs(:ref).returns "Scaleio_storage_pool[#{@name}]"
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
    it 'returns an array w/ two pools' do
      provider.class.stubs(:getProtectionDomains).returns(['myPDomain'])
      provider.class.stubs(:scli).with('--query_protection_domain', '--protection_domain_name', 'myPDomain').returns(myPDomain)
      provider.class.stubs(:scli).with('--query_storage_pool', '--storage_pool_name', 'myPool', '--protection_domain_name', 'myPDomain').returns(myPool)
      provider.class.stubs(:scli).with('--query_storage_pool', '--storage_pool_name', 'myPool2', '--protection_domain_name', 'myPDomain').returns(myPool2)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(['myPDomain:myPool', 'myPDomain:myPool2']).to match_array(names)
    end
    it 'has the correct spare policy' do
      provider.class.stubs(:getProtectionDomains).returns(['myPDomain'])
      provider.class.stubs(:scli).with('--query_protection_domain', '--protection_domain_name', 'myPDomain').returns(myPDomain)
      provider.class.stubs(:scli).with('--query_storage_pool', '--storage_pool_name', 'myPool', '--protection_domain_name', 'myPDomain').returns(myPool)
      provider.class.stubs(:scli).with('--query_storage_pool', '--storage_pool_name', 'myPool2', '--protection_domain_name', 'myPDomain').returns(myPool2)
      instances = provider.class.instances
      expect(instances[0].spare_policy).to match('11%')
    end
  end

  describe 'create' do
    it 'creates a storage pool' do
      provider.expects(:scli).with('--add_storage_pool', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool').returns([])
      provider.expects(:scli).with('--modify_spare_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--spare_percentage', '34%', '--i_am_sure').returns([])
      provider.expects(:scli).with('--modify_zero_padding_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--enable_zero_padding').returns([])
      provider.expects(:sleep).with(30).returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a storage pool' do
      provider.expects(:scli).with('--remove_storage_pool', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool').returns([])
      provider.destroy
    end
  end

  describe 'update' do
    it 'updates the spare policy' do
      provider.expects(:scli).with('--modify_spare_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--spare_percentage', '34%', '--i_am_sure').returns([])
      provider.updateSparePolicy('34%')
    end
  end
end
