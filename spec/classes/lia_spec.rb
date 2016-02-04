require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::lia', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
      :architecture => 'x86_64',
      :operatingsystem => 'RedHat',
    }
  }

  let(:pre_condition){"Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }"}

  describe 'with standard' do
    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }

    it { should contain_package__verifiable('EMC-ScaleIO-lia').with(
      :version        => 'installed',
      :manage_package => false
    )}

    it { should contain_exec("yum install -y 'EMC-ScaleIO-lia'").with(
      :environment => [ "TOKEN=admin" ],
	  	:unless			 => "rpm -q 'EMC-ScaleIO-lia'",
    )}

    it { should contain_tidy('/opt/emc/scaleio/lia/rpm').with(
	  	:age     => '1w',
	  	:recurse => true,
	  	:matches => [ '*rpm' ]
    )}
  end


  context 'wth different version' do
    let(:facts){
      {
        :interfaces => 'eth0',
        :ipaddress => '1.2.3.6',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :fqdn => 'version.example.com'
      }
    }
    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }

    it { should contain_package__verifiable('EMC-ScaleIO-lia').with(
      :version        => '1.44-6-el7',
      :manage_package => false
    )}

    it { should contain_exec("yum install -y 'EMC-ScaleIO-lia-1.44-6-el7'").with(
      :environment => [ "TOKEN=admin" ],
	  	:unless			 => "rpm -q 'EMC-ScaleIO-lia-1.44-6-el7'",
    )}

    it { should contain_tidy('/opt/emc/scaleio/lia/rpm').with(
	  	:age     => '1w',
	  	:recurse => true,
	  	:matches => [ '*rpm' ]
    )}
  end
end

