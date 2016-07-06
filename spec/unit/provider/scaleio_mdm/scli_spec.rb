require 'spec_helper'

describe Puppet::Type.type(:scaleio_mdm).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_mdm).new(
      {
          :ensure => :present,
          :name => 'mdm-1',
          :ips => ['192.168.1.1', '192.168.1.2'],
          :is_tiebreaker => true,
          :mgmt_ips => ['192.168.2.1'],
      }
  ) }

  let(:no_mdm) { my_fixture_read('prop_empty.cli') }
  let(:multiple_mdms) { my_fixture_read('prop_mdm_multiple.cli') }


  describe 'basics' do
    properties = [:mgmt_ips]

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
    context 'with multiple MDMs' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(multiple_mdms)
        @instances = provider.class.instances
      end
      it 'detects all MDMs and ignores not approved MDM\'s' do
        names = @instances.collect { |x| x.name }
        expect(%w(node1 node2 node3)).to match_array(names)
      end
    end
    context 'with no MDM' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(no_mdm)
        @instances = provider.class.instances
      end
      it 'detects no MDM' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end

  describe 'create' do
    it 'creates a mdm' do
      provider.expects(:scli).with('--add_standby_mdm', '--new_mdm_ip', '192.168.1.1,192.168.1.2', '--new_mdm_name', 'mdm-1', '--mdm_role', 'tb', '--new_mdm_management_ip', '192.168.2.1').returns([])
      provider.create
    end
  end

  describe 'update desc' do
    context 'update mgmt ips' do
      it 'updates the mdm mgmt ip' do
        provider.expects(:scli).with('--modify_management_ip', '--target_mdm_name', 'mdm-1', '--new_mdm_management_ip', '192.168.2.1,192.168.2.2').returns([])
        provider.mgmt_ips = ['192.168.2.1', '192.168.2.2']
      end
    end
  end
end
