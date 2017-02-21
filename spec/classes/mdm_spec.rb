require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm', :type => 'class' do

  # facts definition
  let(:facts_default) do
    {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '7.2',
        :operatingsystemmajrelease => '7',
        :concat_basedir => '/var/lib/puppet/concat',
        :is_virtual => false,
        :ipaddress => '10.0.0.1',
        :interfaces => 'eth0',
        :ipaddress_eth0 => '10.0.0.1',
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
        "include scaleio"
    ]
  end

  describe 'with standard' do
    it { should compile.with_all_deps }

    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-mdm').with(
        :version => 'installed',
        :manage_package => true,
        :tag => 'scaleio-install',
    ) }

    it { is_expected.to contain_file('/opt/emc/scaleio/scripts').with(
        :ensure => 'directory',
        :owner => 'root',
        :group => 'root',
        :mode => '0600',
        :require => 'Package_verifiable[EMC-ScaleIO-mdm]',
    ) }
    it { is_expected.to contain_file('/opt/emc/scaleio/scripts/scli_wrap.sh').with(
        :owner => 'root',
        :group => 'root',
        :mode => '0700',
        :require => 'File[/opt/emc/scaleio/scripts]',
    ) }
    it { is_expected.to contain_file('/opt/emc/scaleio/scripts/add_scaleio_user.sh').with(
        :owner => 'root',
        :group => 'root',
        :mode => '0700',
        :require => 'File[/opt/emc/scaleio/scripts/scli_wrap.sh]',
    ) }
    it { is_expected.to contain_file('/opt/emc/scaleio/scripts/change_scaleio_password.sh').with(
        :owner => 'root',
        :group => 'root',
        :mode => '0700',
        :require => 'File[/opt/emc/scaleio/scripts/add_scaleio_user.sh]',
    ) }
    it { is_expected.to contain_file('/etc/bash_completion.d/si').with(
        :content => 'complete -o bashdefault -o default -o nospace -F _scli si',
        :owner => 'root',
        :group => 'root',
        :mode => '0644',
        :require => 'File[/opt/emc/scaleio/scripts]',
    ) }
    it { is_expected.to contain_file('/usr/bin/si').with(
        :ensure => 'link',
        :target => '/opt/emc/scaleio/scripts/scli_wrap.sh',
    ) }

    it { should_not contain_class('scaleio::mdm::primary') }
    it { is_expected.to contain_class('scaleio::mdm::monitoring') }
    it { is_expected.to contain_class('scaleio::mdm::installation') }
  end

  describe 'on the primary MDM' do
    let(:facts) { facts_default.merge({:scaleio_is_primary_mdm => true}) }

    it { is_expected.to contain_class('scaleio::mdm::primary')
                    .that_requires('File[/opt/emc/scaleio/scripts/change_scaleio_password.sh]') }
  end

  describe 'on the first MDM when cluster_setupping' do
    let(:facts) { facts_default.merge({:scaleio_mdm_clustersetup_needed => true}) }

    it { is_expected.to contain_class('scaleio::mdm::primary')
                    .that_requires('File[/opt/emc/scaleio/scripts/change_scaleio_password.sh]')}
  end

  describe 'on the primary with ip on a different interface' do
    let(:facts) { facts_default.merge({
                                          :scaleio_is_primary_mdm => true,
                                          :interfaces => 'eth0,eth10',
                                          :ipaddress_eth0 => '10.0.0.20',
                                          :ipaddress_eth10 => '10.0.0.1',
                                      }) }

    it { is_expected.to contain_class('scaleio::mdm::primary')
                    .that_requires('File[/opt/emc/scaleio/scripts/change_scaleio_password.sh]')}
  end

end
