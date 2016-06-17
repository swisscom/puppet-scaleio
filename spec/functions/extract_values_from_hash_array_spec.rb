require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe "extract_values_from_hash_array", :type => 'puppet_function' do
  before :all do
    Puppet::Parser::Functions.autoloader.loadall
  end
  let(:scope) do
    PuppetlabsSpec::PuppetInternals.scope
  end
  it "should exist" do
    expect(Puppet::Parser::Functions.function("extract_values_from_hash_array")).to eq("function_extract_values_from_hash_array")
  end

  subject do
    function_name = Puppet::Parser::Functions.function(:extract_values_from_hash_array)
    scope.method(function_name)
  end

  describe 'validation' do
    it { expect { subject.call(['1']) }.to raise_error(Puppet::ParseError) }
    it { expect { subject.call(['1', '2', '3']) }.to raise_error(Puppet::ParseError) }
  end

  describe 'simple test' do
    it {
      result = subject.call([[
                                {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                            ], 'ips'])
      expect(result).to eq(%w(10.0.0.1 10.0.0.2 10.0.0.3))
    }
  end

  describe 'get mgmt ips' do
    it {
      result = subject.call([[
                                 {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                 {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                 {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                             ], 'mgmt_ips'])
      expect(result).to eq(%w(11.0.0.1 11.0.0.2 11.0.0.3))
    }
  end
end
