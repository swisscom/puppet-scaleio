require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::monitoring', :type => 'class' do
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
        "class{'scaleio': external_monitoring_user => 'monUser'}",
    ]
  end

  describe 'with standard' do
    it { should contain_file('/opt/emc/scaleio/scripts/scli_wrap_monitoring.sh').with(
          :content => /--username monitoring/,
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0700',
    )}
  end
end

