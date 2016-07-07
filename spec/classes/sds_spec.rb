require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::sds', :type => 'class' do
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

    it { is_expected.to contain_class('scaleio') }
    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-sds').with_version('installed') }
  end

  context 'should not update SIO packages' do
    let(:facts) { facts_default.merge({:package_emc_scaleio_sds_version => '1'}) }

    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-sds').with(
        :version => 'installed',
        :manage_package => false
    ) }
  end
end

