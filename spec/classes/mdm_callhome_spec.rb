require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::mdm::callhome', :type => 'class' do
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
        :domain => 'example.com'
    }
  end
  let(:facts) { facts_default }

  # pre_condition definition
  let(:pre_condition) do
    [
        "Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }",
        "include scaleio",
        "include scaleio::mdm",
    ]
  end

  describe 'with standard' do
    it { is_expected.to compile.with_all_deps }

    it { should contain_package__verifiable('EMC-ScaleIO-callhome').with_version('installed') }

    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :require => 'Package::Verifiable[EMC-ScaleIO-callhome]',
      :notify  => ['Exec[restart_callhome_service]'],
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_from = callhome@node1\.example\.com/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /username = callhome/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /password = Callhome13/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /customer_name = "example\.com"/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /host = localhost/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = root@localhost/,
    )}    
  end

  describe 'with other params' do
    let(:facts) { facts_default.merge({
                                          :scaleio_is_primary_mdm => true,
                                      }) }
    let(:params){
     {
       :from_mail           => 'root@localhost',
       :user                => 'otheruser',
       :user_role           => 'otherrole',
       :password            => 'callhomepassword',
       :mail_server_address => '10.0.0.1',
       :customer_name       => 'ACME Corp',
       :to_mail             => 'test@puppet.test',
     }
    }
    it { should contain_scaleio_user('otheruser').with(
      :password  => 'callhomepassword',
      :role      => 'otherrole',
      :require   => 'File[/opt/emc/scaleio/scripts/add_scaleio_user.sh]',
      :before    => 'File[/opt/emc/scaleio/callhome/cfg/conf.txt]',
    )}

    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :require => 'Package::Verifiable[EMC-ScaleIO-callhome]',
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
      :content => /host = 10.0.0.1/,
    )}
    it { should contain_file('/opt/emc/scaleio/callhome/cfg/conf.txt').with(
      :content => /email_to = test@puppet.test/,
    )}
    
    it { should contain_exec('restart_callhome_service').with(
      :command     => 'pkill -f \'scaleio/callhome\'',
      :refreshonly => true,
    )}
  end
  context 'should not update SIO packages' do
    let(:facts) { facts_default.merge({
                                          :package_emc_scaleio_callhome_version => '1',
                                      }) }

    it { should contain_package__verifiable('EMC-ScaleIO-callhome').with(
      :version        => 'installed',
      :manage_package => false
    )}
  end
end
