require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::mdm::callhome', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
      :fqdn       => 'scaleio.example.net',
      :domain     => 'example.net',
      :ipaddress  => '1.1.2.2',
    }
  }
  describe 'with standard' do
    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }
    it { should contain_package('EMC-ScaleIO-callhome').with_ensure('installed') }
       
    it { should_not contain_file('/var/lib/puppet/module_data/scaleio/add_callhome_user.sh') }
    it { should_not contain_exec('add_callhome_user.sh') }
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :require => 'Package[EMC-ScaleIO-callhome]'
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_from = "callhome@scaleio.example.net"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /username = "callhome"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /password = "callhome"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /customer_name = "example.net"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /host = "localhost"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = "root@localhost"/,
    )}    
  end

  describe 'with other params' do
    let(:pre_condition) {"
      class{'scaleio': 
        callhome          => false, # prevent duplicate declaration
        callhome_password => 'callhomepassword',
        password          => 'adminpassword',
        primary_mdm_ip    => '1.1.2.2',
      }
    "}
    let(:params){
     {
       :from_mail           => 'root@localhost',
       :user                => 'otheruser',
       :user_role           => 'otherrole',
       :mail_server_address => '1.2.3.4',
       :customer_name       => 'ACME Corp',
       :to_mail             => 'test@puppet.test',
     }
    }
    it { should contain_file('/var/lib/puppet/module_data/scaleio/add_callhome_user.sh').with(
      :source  => 'puppet:///modules/scaleio/add_callhome_user.sh',
      :owner   => 'root',
      :group   => 0,
      :mode    => '0700',
      :require => ['Package[EMC-ScaleIO-callhome]', 'Exec[scaleio::mdm::primary_go_into_cluster_mode]']

    )}
      
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_from = "root@localhost"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /username = "otheruser"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /password = "callhomepassword"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /customer_name = "ACME Corp"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /host = "1.2.3.4"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = "test@puppet.test"/,
    )}
    
    it { should contain_exec('add_callhome_user.sh').with(
      :command => '/var/lib/puppet/module_data/scaleio/add_callhome_user.sh otheruser otherrole callhomepassword adminpassword',
      :unless  => '/var/lib/puppet/module_data/scaleio/scli_wrap --query_user --username callhome',
    )}
  end
end
