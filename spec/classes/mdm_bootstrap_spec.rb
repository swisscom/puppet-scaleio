require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::bootstrap', :type => 'class' do

  # facts definition
  let(:facts_default) do
    {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7',
        :concat_basedir => '/var/lib/puppet/concat',
        :is_virtual => false,
        :ipaddress => '10.0.0.1',
        :fqdn => 'node1.example.com',
        :kernel => 'linux',
        :architecture => 'x86_64',
    }
  end
  let(:facts) { facts_default }

  # pre_condition definition
  let(:pre_condition) do
    [
        "Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }",
        "include scaleio"
    ]
  end

  describe 'with standard' do
    it { should contain_exec('scaleio::mdm::bootstrap::create_cluster').with(
        :command => 'scli --create_mdm_cluster --master_mdm_ip 10.0.0.1 --use_nonsecure_communication --accept_license; sleep 5',
        :onlyif => 'scli --query_cluster --approve_certificate 2>&1 |grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
        :require => 'Exec[scaleio::mdm::installation::restart_mdm]',
    ) }
  end
end