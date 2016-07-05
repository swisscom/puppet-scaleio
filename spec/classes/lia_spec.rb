require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::lia', :type => 'class' do
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
    ]
  end

  describe 'with standard' do
    it { is_expected.to compile.with_all_deps }

    it { should contain_class('scaleio') }

    it { should contain_package_verifiable('EMC-ScaleIO-lia').with(
      :version        => 'installed',
      :manage_package => false
    )}

    it { should contain_exec("yum install -y 'EMC-ScaleIO-lia'").with(
      :environment => [ "TOKEN=myS3cr3t" ],
	  	:unless			 => "rpm -q 'EMC-ScaleIO-lia'",
    )}

    it { should contain_tidy('/opt/emc/scaleio/lia/rpm').with(
	  	:age     => '1w',
	  	:recurse => true,
	  	:matches => [ '*rpm' ]
    )}
    it { should contain_service('lia').with(
      :ensure => 'running',
      :enable => true
    )}
  end


  context 'wth different version' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :ipaddress => '10.0.0.3',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :fqdn => 'version.example.com'
      }
    }
    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }

    it { should contain_package_verifiable('EMC-ScaleIO-lia').with(
      :version        => '1.44-6-el7',
      :manage_package => false
    )}

    it { should contain_exec("yum install -y 'EMC-ScaleIO-lia-1.44-6-el7'").with(
      :environment => [ "TOKEN=myS3cr3t" ],
	  	:unless			 => "rpm -q 'EMC-ScaleIO-lia-1.44-6-el7'",
    )}

    it { should contain_tidy('/opt/emc/scaleio/lia/rpm').with(
	  	:age     => '1w',
	  	:recurse => true,
	  	:matches => [ '*rpm' ]
    )}
    it { should contain_service('lia').with(
      :ensure => 'running',
      :enable => true
    )}
  end
end

