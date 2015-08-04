require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::mdm::primary', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
      :architecture => 'x86_64',
      :operatingsystem => 'RedHat',
    }
  }
  describe 'with standard' do

    it { should_not contain_consul_kv_blocker('scaleio/sysname/cluster_setup/secondary')}
    it { should_not contain_consul_kv_blocker('scaleio/sysname/cluster_setup/tiebreaker')}

    it { should contain_class('scaleio::mdm') }

    it { should contain_exec('scaleio::mdm::primary_add_primary').with(
      :command => 'scli --add_primary_mdm --primary_mdm_ip 1.2.3.4 --accept_license && sleep 10',
      :unless  => "scli --query_cluster | grep -qE '^ Primary (MDM )?IP: (([0-9]+.?))+$'",
      :require => 'Package::Verifiable[EMC-ScaleIO-mdm]',
      :before  => 'Exec[scaleio::mdm::primary_add_secondary]',
    )}

    it { should contain_exec('scaleio::mdm::primary_add_secondary').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --add_secondary_mdm --secondary_mdm_ip 1.2.3.5',
      :unless  => "scli --query_cluster | grep -qE '^ Secondary (MDM )?IP: (([0-9]+.?))+$'",
      :before  => ['Exec[scaleio::mdm::primary_add_tb]'],
    )}
    it { should contain_exec('scaleio::mdm::primary_add_tb').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --add_tb --tb_ip 1.2.3.6',
      :unless => "scli --query_cluster | grep -qE '^ Tie-Breaker IP: (([0-9]+.?))+$'",
      :before => ['Exec[scaleio::mdm::primary_go_into_cluster_mode]'],
    )}

    it { should contain_exec('scaleio::mdm::primary_go_into_cluster_mode').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --switch_to_cluster_mode',
      :unless => "scli --query_cluster | grep -qE '^ Mode: Cluster, Cluster State: '"
    )}
  end
  context 'with a name' do
    let(:pre_condition){
      "class{'scaleio': system_name => 'foo' }"
    }
    it { should contain_exec('scaleio::mdm::primary_rename_system').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --rename_system --new_name foo',
      :unless => "scli --query_cluster | grep -qE '^ Name: foo$'"
    )}
  end
#  context 'with a protection domain name' do
#    let(:pre_condition){
#      "class{'scaleio': system_name => 'foo' }"
#    }
#    it { should contain_exec('scaleio::mdm::add_protection_domain').with(
#      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --add_protection_domain --protection_domain_name pdo-foo',
#      :unless  => "scli --query_all | grep -qE '^Protection Domain pdo-foo$'",
#      :require => 'Exec[scaleio::mdm::primary_go_into_cluster_mode]',
#    )}
#  end
  context 'with a password different than admin' do
    let(:pre_condition){
      "class{'scaleio': password => 'foo' }"
    }
    it { should contain_exec('scaleio::mdm::primary_login_default').with(
      :command      => 'scli --login --username admin --password admin',
      :notify       => ['Exec[scaleio::mdm::primary_change_pwd]'],
      :unless       => 'scli --login --username admin --password foo && scli --logout',
      :require      => 'Exec[scaleio::mdm::primary_add_primary]',
    )}
    it { should contain_exec('scaleio::mdm::primary_change_pwd').with(
      :command      => 'scli --set_password --old_password admin --new_password foo',
      :before       => 'Exec[scaleio::mdm::primary_add_secondary]',
      :refreshonly  => true,
    )}
  end
  context 'with a newpassword different than admin' do
    let(:pre_condition){
      "class{'scaleio': password => 'foo', old_password => 'bla' }"
    }
    it { should contain_exec('scaleio::mdm::primary_login_default').with(
      :command      => 'scli --login --username admin --password bla',
      :notify       => ['Exec[scaleio::mdm::primary_change_pwd]'],
      :unless       => 'scli --login --username admin --password foo && scli --logout',
      :require      => 'Exec[scaleio::mdm::primary_add_primary]',
    )}
    it { should contain_exec('scaleio::mdm::primary_change_pwd').with(
      :command      => 'scli --set_password --old_password bla --new_password foo',
      :before       => 'Exec[scaleio::mdm::primary_add_secondary]',
      :refreshonly  => true,
    )}
  end
  context 'with a syslog ip port' do
    let(:pre_condition){
      "class{'scaleio': syslog_ip_port => '1.2.3.7:8080' }"
    }
    it { should contain_scaleio_syslog('1.2.3.7').with(
      :port => '8080',
      :require => 'Exec[scaleio::mdm::primary_add_secondary]',
    )}
  end
  context 'with a syslog ip port - support version 1.30' do
    let(:pre_condition){
      "class{'scaleio': syslog_ip_port => '1.2.3.7:8080', version => '1.30-2134' }"
    }
    it { should contain_exec('scaleio::mdm::primary_configure_syslog').with(
        :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --start_remote_syslog --remote_syslog_server_ip 1.2.3.7 --remote_syslog_server_port 8080',
        :unless  => "netstat -apn |grep mdm |egrep -q ':8080'",
        :require => 'Exec[scaleio::mdm::primary_add_secondary]',
    )}
  end
  context 'with management addresses' do
    let(:pre_condition){
      "class{'scaleio': mgmt_addresses => ['1.2.3.4', '1.2.3.5'] }"
    }

    it { should contain_exec('scaleio::mdm::set_mgmt_addresses').with(
      :command => "/var/lib/puppet/module_data/scaleio/scli_wrap --modify_management_ip --mdm_management_ip 1.2.3.4,1.2.3.5",
      :unless  => "scli --query_cluster |sed 's/\s*//g' | grep -qE '^ManagementIP:1.2.3.4,1.2.3.5$'",
      :require => 'Exec[scaleio::mdm::primary_go_into_cluster_mode]'
    )}
  end
  #context 'with a wrong license' do
  #  let(:pre_condition){
  #    "class{'scaleio': license => 'dd' }"
  #  }
  #  it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  #end
  context 'with a wrong password' do
    let(:pre_condition){
      "class{'scaleio': password => 'd,' }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with a wrong primary ip' do
    let(:pre_condition){
      "class{'scaleio': mdm_ips => ['1.2.3', '1.2.3.4'] }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with a wrong secondary ip' do
    let(:pre_condition){
      "class{'scaleio': mdm_ips => ['1.2.3.4', '1.2.3'] }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with a wrong tb ip' do
    let(:pre_condition){
      "class{'scaleio': tb_ips => ['1.2.3'] }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end

  context 'with consul' do
   let(:facts){
      {
        :interfaces => 'eth0',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :fqdn => 'consul.example.com'
      }
    }
    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/secondary').with(
      :tries => 120,
      :try_sleep => 30
    )}    
    it { should contain_consul_kv_blocker('scaleio/sysname/cluster_setup/tiebreaker').with(
      :tries => 120,
      :try_sleep => 30
    )}
  end
  context 'external monitoring user' do
    let(:pre_condition){
      "class{'scaleio': external_monitoring_user => 'monitor' }"
    }
    it { should contain_scaleio_user('monitoring').with(
      :role      => 'Monitor',
      :password  => 'Monitor1',
      :require   => ['Exec[scaleio::mdm::primary_add_secondary]', 'File[/var/lib/puppet/module_data/scaleio/add_scaleio_user]']
    )}
  end
end

