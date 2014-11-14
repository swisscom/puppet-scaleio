require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::mdm::primary', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
    }
  }
  describe 'with standard' do
    it { should contain_class('scaleio::mdm') }

    it { should contain_exec('scaleio::mdm::primary_add_primary').with(
      :command => 'scli --add_primary_mdm --primary_mdm_ip 1.2.3.4 --accept_license && sleep 10',
      :unless  => "scli --query_cluster | grep -qE '^ Primary IP: 1.2.3.4$'",
      :require => 'Package[EMC-ScaleIO-mdm]',
      :before  => 'Exec[scaleio::mdm::primary_add_secondary]',
    )}

    it { should contain_exec('scaleio::mdm::primary_add_secondary').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --add_secondary_mdm --secondary_mdm_ip 1.2.3.5',
      :unless  => "scli --query_cluster | grep -qE '^ Secondary IP: 1.2.3.5$'",
      :before  => 'Exec[scaleio::mdm::primary_add_tb]',
    )}
    it { should contain_exec('scaleio::mdm::primary_add_tb').with(
      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --add_tb --tb_ip 1.2.3.6',
      :unless => "scli --query_cluster | grep -qE '^ Tie-Breaker IP: 1.2.3.6$'",
      :before => 'Exec[scaleio::mdm::primary_go_into_cluster_mode]',
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
      :unless => "scli --query_cluster | grep -qE '^ Name: foo$'",
      :require => 'Exec[scaleio::mdm::primary_go_into_cluster_mode]',
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
      :notify       => 'Exec[scaleio::mdm::primary_change_pwd]',
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
      :notify       => 'Exec[scaleio::mdm::primary_change_pwd]',
      :unless       => 'scli --login --username admin --password foo && scli --logout',
      :require      => 'Exec[scaleio::mdm::primary_add_primary]',
    )}
    it { should contain_exec('scaleio::mdm::primary_change_pwd').with(
      :command      => 'scli --set_password --old_password bla --new_password foo',
      :before       => 'Exec[scaleio::mdm::primary_add_secondary]',
      :refreshonly  => true,
    )}
  end
#  context 'with a syslog ip port' do
#    let(:pre_condition){
#      "class{'scaleio': syslog_ip_port => '1.2.3.7:8080' }"
#    }
#    it { should contain_exec('scaleio::mdm::primary_configure_syslog').with(
#      :command => '/var/lib/puppet/module_data/scaleio/scli_wrap --start_remote_syslog --remote_syslog_server_ip 1.2.3.7 --remote_syslog_server_port 8080 --syslog_facility 16',
#      #:unless => 'TODO:',
#      :require => 'Exec[scaleio::mdm::primary_go_into_cluster_mode]',
#    )}
#  end
#  context 'with a wrong license' do
#    let(:pre_condition){
#      "class{'scaleio': license => 'dd' }"
#    }
#    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
#  end
  context 'with a wrong password' do
    let(:pre_condition){
      "class{'scaleio': password => 'd,' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
  context 'with a wrong primary ip' do
    let(:pre_condition){
      "class{'scaleio': primary_mdm_ip => '1.2.3' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
  context 'with a wrong secondary ip' do
    let(:pre_condition){
      "class{'scaleio': secondary_mdm_ip => '1.2.3' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
  context 'with a wrong tb ip' do
    let(:pre_condition){
      "class{'scaleio': tb_ip => '1.2.3' }"
    }
    it { expect { subject.call('fail') }.to raise_error(Puppet::Error) }
  end
end

