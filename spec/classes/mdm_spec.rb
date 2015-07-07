require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::mdm', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
      :architecture => 'x86_64',
      :operatingsystem => 'RedHat',
    }
  }

  let(:pre_condition){"Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }"}

  describe 'with standard' do
#    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }
    it { should contain_package__verifiable('EMC-ScaleIO-mdm').with_version('installed') }
    it { should_not contain_class('scaleio::mdm::primary') }
    it { should_not contain_class('sudo::rule') }
    it { should contain_class('scaleio::mdm::callhome') }
    it { should_not contain_consul_kv('scaleio/sysname/cluster_setup/secondary')}
  end
  context 'on the primary' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :ipaddress => '1.2.3.4',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :scaleio_is_primary_mdm => 'true',
      }
    }
    it { should contain_class('scaleio::mdm::primary') }
    it { should_not contain_consul_kv('scaleio/sysname/cluster_setup/secondary')}
  end
  context 'on the primary with ip on a different interface' do
    let(:facts){
      {
        :interfaces => 'eth0,eth10',
        :ipaddress_eth10 => '1.2.3.4',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :scaleio_is_primary_mdm => 'true',
      }
    }
    it { should contain_class('scaleio::mdm::primary') }
  end
  context 'without callhome' do
    let(:pre_condition){[
      "class{'scaleio':
        callhome => false,
       }",
       "Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }"
    ]}
    it { should_not contain_class('scaleio::mdm::callhome') }
  end

  context 'using consul on the secondary' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :ipaddress => '1.2.3.5',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :fqdn => 'consul.example.com',
        :scaleio_mdm_clustersetup_needed => 'true'
      }
    }
    it { should contain_consul_kv('scaleio/sysname/cluster_setup/secondary').with(
        :value   => 'ready',
        :require => 'Package::Verifiable[EMC-ScaleIO-mdm]'
      )}
  end

  context 'using standby MDMs' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :ipaddress => '1.2.3.5',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :fqdn => 'standbymdms.example.com',
        :scaleio_mdm_clustersetup_needed => 'true'
      }
    }
    it { should contain_exec('scaleio::mdm::setup_failover').with(
      :command => "/opt/emc/scaleio/mdm_failover/bin/delete_service.sh ; ps -ef |grep '[m]dm_failover.py' |awk '{print \$2}' |xargs -r kill ; /opt/emc/scaleio/mdm_failover/bin/mdm_failover_post_install.py --mdms_list='[1.2.3.4]+[1.2.3.5]+[1.2.3.6]' --tbs_list='[1.2.3.7]+[1.2.3.8]' --username=admin --password='admin'",
      :unless  => "fgrep \"mdms': '[1.2.3.4]+[1.2.3.5]+[1.2.3.6]\" /opt/emc/scaleio/mdm_failover/cfg/conf.txt |fgrep \"tbs': '[1.2.3.7]+[1.2.3.8]\" |fgrep 'admin'",
      :require => 'Package::Verifiable[EMC-ScaleIO-mdm]',
      :returns => [ 0, '', ' ']
      )}
  end

  context 'with external monitoring user' do
    let(:pre_condition){[
      "class{'scaleio':
        external_monitoring_user => 'monitor'
       }",
       "Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }"
    ]}
    it { should contain_file('/var/lib/puppet/module_data/scaleio/scli_wrap_monitoring').with(
        :owner   => 'root',
        :group   => 0,
        :mode    => '0700',
        :require => 'Package::Verifiable[EMC-ScaleIO-mdm]'
    )}
  end
end

