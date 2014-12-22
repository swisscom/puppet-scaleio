require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_sdc_name).provider(:scaleio_sdc_name)
all_properties = [
  :desc,
]

describe provider_class do

  # load sample cli outputs
  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:threeSDC)        { File.read(File.join(fixtures_cli,"sdc_name_query_all_three_sdc.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_sdc_name).new({
      :ensure   => :present,
      :name     => '172.17.121.10',
      :desc     => 'mySDC',
      :provider => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource = stub 'resource'
      @name     = '172.17.121.11'
      @desc     = 'myNewSDC'
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @name
      @resource.stubs(:[]).with(:desc).returns @desc
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_sdc_name[#{@name}]"
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
    it 'returns an array w/ three sdc_name\'s' do
      provider.class.stubs(:scli).with('--query_all_sdc').returns(threeSDC)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(['192.168.56.111', '192.168.56.112', '192.168.56.113']).to match_array(names)
    end
    it 'has discoverd the correct property values' do
      provider.class.stubs(:scli).with('--query_all_sdc').returns(threeSDC)
      instances = provider.class.instances
      expect(instances[0].desc).to match('sdc1')
    end
  end

  describe 'create' do
    it 'creates a sdc_name' do
      provider.expects(:rename_sdc).with('mySDC').returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a sdc_name' do
      expect{
        provider.destroy
      }.to raise_error Puppet::Error, /Destroying \(unmapping\) an SDC name from an IP is not \(yet\?\) supported by ScaleIO/
    end
  end

  describe 'update desc' do
    it 'updates the sdc name' do
      provider.expects(:rename_sdc).with('newSDCName').returns([])
      provider.desc = 'newSDCName'
    end
  end

  describe 'rename_sdc' do
    it 'updates the sdc name' do
      provider.expects(:scli).with('--rename_sdc', '--sdc_ip', '172.17.121.10', '--new_name', 'newSDCName').returns([])
      provider.rename_sdc('newSDCName')
    end
  end
end
