require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::cluster_setup', :type => 'class' do

  # facts definition
  let(:facts_default) do
    {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7',
        :concat_basedir => '/var/lib/puppet/concat',
        :is_virtual => false,
        :ipaddress => '10.0.0.1',
        :interfaces => 'eth0',
        :ipaddress_eth0 => '10.0.0.1',
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
    it { is_expected.to compile.with_all_deps }

    it { should contain_exec('scaleio::mdm::cluster_setup::create_cluster').with(
        :command => 'scli --create_mdm_cluster --master_mdm_ip 10.0.0.1 --master_mdm_management_ip 11.0.0.1 --master_mdm_name myMDM1 --use_nonsecure_communication --accept_license; sleep 5',
        :onlyif => 'scli --query_cluster --approve_certificate 2>&1 |grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
        :require => 'Exec[scaleio::mdm::installation::restart_mdm]',
    ).that_comes_before('Exec[scaleio::mdm::cluster_setup::login_default]') }

    it { should contain_exec('scaleio::mdm::cluster_setup::login_default').with(
        :command => "scli --login --username admin --password admin",
        :unless => "scli --login --username admin --password myS3cr3t && scli --logout",
    ).that_notifies('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]') }

    it { should contain_exec('scaleio::mdm::cluster_setup::primary_change_pwd').with(
        :command => "scli --set_password --old_password admin --new_password myS3cr3t",
        :refreshonly => true,
    ) }

    it { should contain_scaleio_mdm('myMDM1').with(
        :ips => '10.0.0.1',
        :mgmt_ips => '11.0.0.1',
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myMDM2').with(
        :ips => '10.0.0.2',
        :mgmt_ips => '11.0.0.2',
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myMDM3').with(
        :ips => '10.0.0.3',
        :mgmt_ips => '11.0.0.3',
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myTB1').with(
        :ips => '10.0.0.4',
        :ensure => 'present',
        :is_tiebreaker => true,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myTB2').with(
        :ips => '10.0.0.5',
        :ensure => 'present',
        :is_tiebreaker => true,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm_cluster('mdm_cluster').with(
        :mdm_names => %w(myMDM1 myMDM2 myMDM3),
        :tb_names => %w(myTB1 myTB2),
    ) }
  end

  describe 'with multiple IPs' do
    let(:facts) { facts_default.merge({:fqdn => '5_node_cluster.example.com'}) }

    it { should contain_exec('scaleio::mdm::cluster_setup::create_cluster').with(
        :command => 'scli --create_mdm_cluster --master_mdm_ip 10.0.0.1,10.0.0.2 --master_mdm_management_ip 11.0.0.1,11.0.0.2 --master_mdm_name myMDM1 --use_nonsecure_communication --accept_license; sleep 5',
        :onlyif => 'scli --query_cluster --approve_certificate 2>&1 |grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
        :require => 'Exec[scaleio::mdm::installation::restart_mdm]',
    ).that_comes_before('Exec[scaleio::mdm::cluster_setup::login_default]') }

    it { should contain_exec('scaleio::mdm::cluster_setup::login_default').with(
        :command => "scli --login --username admin --password admin",
        :unless => "scli --login --username admin --password myS3cr3t && scli --logout",
    ).that_notifies('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]') }

    it { should contain_exec('scaleio::mdm::cluster_setup::primary_change_pwd').with(
        :command => "scli --set_password --old_password admin --new_password myS3cr3t",
        :refreshonly => true,
    ) }

    it { should contain_scaleio_mdm('myMDM1').with(
        :ips => %w(10.0.0.1 10.0.0.2),
        :mgmt_ips => %w(11.0.0.1 11.0.0.2),
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myMDM2').with(
        :ips => %w(20.0.0.1 20.0.0.2),
        :mgmt_ips => %w(21.0.0.1 21.0.0.2),
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myMDM3').with(
        :ips => %w(30.0.0.1 30.0.0.2),
        :mgmt_ips => %w(31.0.0.1 31.0.0.2),
        :ensure => 'present',
        :is_tiebreaker => false,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myTB1').with(
        :ips => %w(40.0.0.1 40.0.0.2),
        :mgmt_ips => %w(41.0.0.1 41.0.0.2),
        :ensure => 'present',
        :is_tiebreaker => true,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm('myTB2').with(
        :ips => %w(50.0.0.1 50.0.0.2),
        :mgmt_ips => %w(51.0.0.1 51.0.0.2),
        :ensure => 'present',
        :is_tiebreaker => true,
    ).that_requires('Exec[scaleio::mdm::cluster_setup::primary_change_pwd]')
                    .that_comes_before('Scaleio_mdm_cluster[mdm_cluster]') }

    it { should contain_scaleio_mdm_cluster('mdm_cluster').with(
        :mdm_names => %w(myMDM1 myMDM2 myMDM3),
        :tb_names => %w(myTB1 myTB2),
    ) }
  end

  describe 'with consul' do
    let(:facts) { facts_default.merge({:fqdn => 'use_consul.example.com'}) }

    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/10.0.0.1').with(
        :tries     => 120,
        :try_sleep => 30,
        :require   => 'Consul_kv[scaleio/sysname/cluster_setup/10.0.0.1]',
    ).that_comes_before('Scaleio_mdm[myMDM1]')
                    .that_comes_before('Scaleio_mdm[myMDM2]')
                    .that_comes_before('Scaleio_mdm[myMDM3]')
                    .that_comes_before('Scaleio_mdm[myTB1]')
                    .that_comes_before('Scaleio_mdm[myTB2]')}

    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/10.0.0.2').with(
        :tries     => 120,
        :try_sleep => 30,
        :require   => 'Consul_kv[scaleio/sysname/cluster_setup/10.0.0.1]',
    ).that_comes_before('Scaleio_mdm[myMDM1]')
                    .that_comes_before('Scaleio_mdm[myMDM2]')
                    .that_comes_before('Scaleio_mdm[myMDM3]')
                    .that_comes_before('Scaleio_mdm[myTB1]')
                    .that_comes_before('Scaleio_mdm[myTB2]')}

    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/10.0.0.3').with(
        :tries     => 120,
        :try_sleep => 30,
        :require   => 'Consul_kv[scaleio/sysname/cluster_setup/10.0.0.1]',
    ).that_comes_before('Scaleio_mdm[myMDM1]')
                    .that_comes_before('Scaleio_mdm[myMDM2]')
                    .that_comes_before('Scaleio_mdm[myMDM3]')
                    .that_comes_before('Scaleio_mdm[myTB1]')
                    .that_comes_before('Scaleio_mdm[myTB2]')}

    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/10.0.0.4').with(
        :tries     => 120,
        :try_sleep => 30,
        :require   => 'Consul_kv[scaleio/sysname/cluster_setup/10.0.0.1]',
    ).that_comes_before('Scaleio_mdm[myMDM1]')
                    .that_comes_before('Scaleio_mdm[myMDM2]')
                    .that_comes_before('Scaleio_mdm[myMDM3]')
                    .that_comes_before('Scaleio_mdm[myTB1]')
                    .that_comes_before('Scaleio_mdm[myTB2]')}

    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/10.0.0.5').with(
        :tries     => 120,
        :try_sleep => 30,
        :require   => 'Consul_kv[scaleio/sysname/cluster_setup/10.0.0.1]',
    ).that_comes_before('Scaleio_mdm[myMDM1]')
                    .that_comes_before('Scaleio_mdm[myMDM2]')
                    .that_comes_before('Scaleio_mdm[myMDM3]')
                    .that_comes_before('Scaleio_mdm[myTB1]')
                    .that_comes_before('Scaleio_mdm[myTB2]')}
  end
end