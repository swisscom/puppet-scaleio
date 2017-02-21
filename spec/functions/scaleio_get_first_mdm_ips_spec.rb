require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe "scaleio_get_first_mdm_ips", :type => 'puppet_function' do

  describe 'validation' do
    it { expect { subject.call(['1']) }.to raise_error(Puppet::ParseError) }
    it { expect { subject.call(['1', '2', '3']) }.to raise_error(Puppet::ParseError) }
  end

  context 'simple test' do
    it { is_expected.to run.with_params({
                                'name1' => {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                'name2' => {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                'name3' => {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                             }, 'ips')
    .and_return(%w(10.0.0.1 10.0.0.2 10.0.0.3)) }
  end

  context 'get mgmt ips' do
    it { is_expected.to run.with_params({
                                 'name1' => {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                 'name2' => {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                 'name3' => {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                             }, 'mgmt_ips')
      .and_return(%w(11.0.0.1 11.0.0.2 11.0.0.3))}
  end

  context 'ips as array' do
    it { is_expected.to run.with_params({
                                 'name1' => {'ips' => %w(10.0.0.1 10.0.0.11), 'mgmt_ips' => '11.0.0.1'},
                                 'name2' => {'ips' => %w(10.0.0.2 10.0.0.12), 'mgmt_ips' => '11.0.0.2'},
                                 'name3' => {'ips' => %w(10.0.0.3 10.0.0.13), 'mgmt_ips' => '11.0.0.3'},
                             }, 'ips')
      .and_return(%w(10.0.0.1 10.0.0.2 10.0.0.3))}
  end
end
