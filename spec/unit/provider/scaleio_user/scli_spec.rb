require 'spec_helper'

describe Puppet::Type.type(:scaleio_user).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_user).new(
      {
          :ensure       => :present,
          :name         => 'api',
          :password     => 'myPW',
          :role         => 'Monitor',
      }
  ) }

  let(:no_users) { my_fixture_read('no_users.cli') }
  let(:two_users) { my_fixture_read('two_users.cli') }

  describe 'basics' do
    properties = []

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
    it 'returns an array with no users' do
      provider.class.stubs(:scli).with('--query_users').returns(no_users)
      user_instances = provider.class.instances
      user_names      = user_instances.collect {|x| x.name }
      expect([]).to match_array(user_names)
    end
    it 'returns an array w/ 2 users' do
      provider.class.stubs(:scli).with('--query_users').returns(two_users)
      user_instances = provider.class.instances
      user_names     = user_instances.collect {|x| x.name }
      expect(['callhome', 'myuser']).to match_array(user_names)
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
