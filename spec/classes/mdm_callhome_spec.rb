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
    #it { should compile.with_all_deps }
    it { should contain_class('scaleio::mdm') }
    it { should contain_package('EMC-ScaleIO-callhome').with_ensure('installed') }

    it { should_not contain_exec('add_callhome_user.sh') }
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :require => 'Package[EMC-ScaleIO-callhome]',
      :notify  => ['Exec[restart_callhome_service]'],
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_from = callhome@scaleio.example.net/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /username = callhome/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /password = Callhome13/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /customer_name = "example.net"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /host = localhost/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = root@localhost/,
    )}    
  end

  describe 'with other params' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :fqdn       => 'scaleio.example.net',
        :domain     => 'example.net',
        :ipaddress  => '1.1.2.2',
        :scaleio_is_primary_mdm => 'true',
      }
    }
    let(:pre_condition) {"
      class{'scaleio': 
        callhome          => false, # prevent duplicate declaration
        password          => 'adminpassword',
        primary_mdm_ip    => '1.1.2.2',
      }
    "}
    let(:params){
     {
       :from_mail           => 'root@localhost',
       :user                => 'otheruser',
       :user_role           => 'otherrole',
       :password            => 'callhomepassword',
       :mail_server_address => '1.2.3.4',
       :customer_name       => 'ACME Corp',
       :to_mail             => 'test@puppet.test',
     }
    }
    it { should contain_scaleio_user('otheruser').with(
      :password  => 'callhomepassword',
      :role      => 'otherrole',
      :require   => ['Exec[scaleio::mdm::primary_add_secondary]', 'File[/var/lib/puppet/module_data/scaleio/add_scaleio_user]'],
      :before    => 'File[/opt/emc/scaleio/callhome/cfg/conf.txt]',
    )}

    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :require => 'Package[EMC-ScaleIO-callhome]',
      :notify  => ['Exec[restart_callhome_service]'],
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_from = root@localhost/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /username = otheruser/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /password = callhomepassword/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /customer_name = "ACME Corp"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /host = 1.2.3.4/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = test@puppet.test/,
    )}
    
    it { should contain_exec('restart_callhome_service').with(
      :command     => 'pkill -f \'scaleio/callhome\'',
      :refreshonly => true,
    )}
  end
end
