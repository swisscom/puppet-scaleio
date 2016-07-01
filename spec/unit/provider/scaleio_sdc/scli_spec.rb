require 'spec_helper'

describe Puppet::Type.type(:scaleio_sdc).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_sdc).new(
      {
          :ensure => :present,
          :name => '172.17.121.10',
          :desc => 'mySDC',
      }
  ) }

  let(:no_sdc) { my_fixture_read('prop_empty.cli') }
  let(:multiple_sdcs) { my_fixture_read('prop_sdc_ip_approved_multiple.cli') }


  describe 'basics' do
    properties = [:desc]

    it("should have a create method") { expect(provider).to respond_to(:create) }
    it("should have a destroy method") { expect(provider).to respond_to(:destroy) }
    it("should have an exists? method") { expect(provider).to respond_to(:exists?) }
    properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        expect(provider).to respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        expect(provider).to respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    context 'with multiple SDCs' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(multiple_sdcs)
        @instances = provider.class.instances
      end
      it 'detects all SDCs and ignores not approved SDC\'s' do
        names = @instances.collect { |x| x.name }
        expect(['192.168.56.122', '192.168.56.123']).to match_array(names)
      end
    end
    context 'with no SDC' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(no_sdc)
        @instances = provider.class.instances
      end
      it 'detects no SDC' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end

  describe 'create' do
    it 'creates a sdc_name' do
      provider.expects(:scli).with('--add_sdc', '--sdc_ip', '172.17.121.10', '--sdc_name', 'mySDC').returns([])
      provider.create
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
