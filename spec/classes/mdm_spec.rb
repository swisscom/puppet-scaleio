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
    it { should contain_package('EMC-ScaleIO-mdm').with_ensure('installed') }
    it { should_not contain_class('scaleio::mdm::primary') }
    it { should contain_class('scaleio::mdm::callhome') }
    it { should_not contain_consul_kv('scaleio/cluster_setup/secondary')}
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
    it { should_not contain_consul_kv('scaleio/cluster_setup/secondary')}
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
    it { should contain_consul_kv('scaleio/cluster_setup/secondary').with(
        :value   => 'ready',
        :require => 'Package[EMC-ScaleIO-mdm]'
      )}
  end
end

