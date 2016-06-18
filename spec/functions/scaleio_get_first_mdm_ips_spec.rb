require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe "scaleio_get_first_mdm_ips", :type => 'puppet_function' do
  before :all do
    Puppet::Parser::Functions.autoloader.loadall
  end
  let(:scope) do
    PuppetlabsSpec::PuppetInternals.scope
  end
  it "should exist" do
    expect(Puppet::Parser::Functions.function("scaleio_get_first_mdm_ips")).to eq("function_scaleio_get_first_mdm_ips")
  end

  subject do
    function_name = Puppet::Parser::Functions.function(:scaleio_get_first_mdm_ips)
    scope.method(function_name)
  end

  describe 'validation' do
    it { expect { subject.call(['1']) }.to raise_error(Puppet::ParseError) }
    it { expect { subject.call(['1', '2', '3']) }.to raise_error(Puppet::ParseError) }
  end

  describe 'simple test' do
    it {
      result = subject.call([{
                                'name1' => {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                'name2' => {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                'name3' => {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                             }, 'ips'])
      expect(result).to eq(%w(10.0.0.1 10.0.0.2 10.0.0.3))
    }
  end

  describe 'get mgmt ips' do
    it {
      result = subject.call([{
                                 'name1' => {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                 'name2' => {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                 'name3' => {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                             }, 'mgmt_ips'])
      expect(result).to eq(%w(11.0.0.1 11.0.0.2 11.0.0.3))
    }
  end

  describe 'ips as array' do
    it {
      result = subject.call([{
                                 'name1' => {'ips' => %w(10.0.0.1 10.0.0.11), 'mgmt_ips' => '11.0.0.1'},
                                 'name2' => {'ips' => %w(10.0.0.2 10.0.0.12), 'mgmt_ips' => '11.0.0.2'},
                                 'name3' => {'ips' => %w(10.0.0.3 10.0.0.13), 'mgmt_ips' => '11.0.0.3'},
                             }, 'ips'])
      expect(result).to eq(%w(10.0.0.1 10.0.0.2 10.0.0.3))
    }
  end
end
