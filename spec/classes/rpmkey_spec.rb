require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::rpmkey', :type => 'class' do

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
    it { should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO').with(
        :source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
        :owner => 'root',
        :group => '0',
        :mode => '0644',
    ).that_notifies('Exec[scaleio::rpmkey::import]') }

    it { should contain_exec('scaleio::rpmkey::import').with(
        :command => 'rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO',
        :refreshonly => true,
    )}
  end
end