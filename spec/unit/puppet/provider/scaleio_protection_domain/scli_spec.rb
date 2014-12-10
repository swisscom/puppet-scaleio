require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_protection_domain).provider(:scaleio_protection_domain)
all_properties = [
]

describe provider_class do

  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:no_pdo)       		{ File.read(File.join(fixtures_cli,"pdo_query_all_no_pdo.cli")) }
  let(:one_pdo)       	{ File.read(File.join(fixtures_cli,"pdo_query_all_one_pdo.cli")) }
  let(:two_pdo)       { File.read(File.join(fixtures_cli,"pdo_query_all_two_pdo.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_protection_domain).new(
    { :ensure       => :present,
      :name         => 'test-PDO',
      :provider     => described_class.name,
    }
    )
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource        = stub 'resource'
      @pdo_name = "my-PDO"
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @pdo_name
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_protection_domain[#{@pdo_name}]"
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
    it 'returns an array w/ no protection domains' do
      provider.class.stubs(:scli).with('--query_all').returns(no_pdo)
      pdo_instances = provider.class.instances
      pdo_names     = pdo_instances.collect {|x| x.name }
      expect([]).to match_array(pdo_names)
    end
    it 'returns an array w/ 1 protection domain' do
      provider.class.stubs(:scli).with('--query_all').returns(one_pdo)
      pdo_instances = provider.class.instances
      pdo_names     = pdo_instances.collect {|x| x.name }
      expect(['myPDomain']).to match_array(pdo_names)
    end
    it 'returns an array w/ 2 protection domains' do
      provider.class.stubs(:scli).with('--query_all').returns(two_pdo)
      pdo_instances = provider.class.instances
      pdo_names     = pdo_instances.collect {|x| x.name }
      expect(['pd2', 'myPDomain']).to match_array(pdo_names)
    end
  end

  describe 'create' do
    it 'creates a protection domain' do
      provider.expects(:scli).with('--add_protection_domain', '--protection_domain_name', 'test-PDO').returns([])
      provider.create
    end
  end
end
