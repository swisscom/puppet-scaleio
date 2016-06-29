require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::primary', :type => 'class' do
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
        "include scaleio",
        "include scaleio::mdm",
    ]
  end

  describe 'with standard' do
    it { should contain_class('scaleio::mdm::cluster_setup') }
    it { should contain_exec('scaleio::mdm::primary::manage_sdc_access_restriction').with(
        :command => '/opt/emc/scaleio/scripts/scli_wrap.sh --set_restricted_sdc_mode --restricted_sdc_mode enabled',
        :unless => "/opt/emc/scaleio/scripts/scli_wrap.sh --query_all |grep -q 'MDM restricted SDC mode: enabled'"
    )}

    it { should contain_exec('scaleio::mdm::primary::rename_system').with(
        :command => '/opt/emc/scaleio/scripts/scli_wrap.sh --rename_system --new_name sysname',
        :unless => "/opt/emc/scaleio/scripts/scli_wrap.sh --query_cluster | grep -qE '^ Name: sysname\\s*Mode'",
        :require   => 'Class[Scaleio::Mdm::Cluster_setup]',
    )}

    it { should contain_scaleio_user('monitoring').with(
        :role      => 'Monitor',
        :password  => 'Monitor1',
        :require   => 'Class[Scaleio::Mdm::Cluster_setup]',
    )}
  end

  context 'SDC restricted mode disabled' do
    let(:facts) { facts_default.merge({:fqdn => 'no_sdc_restriction.example.com'}) }

    it { should contain_exec('scaleio::mdm::primary::manage_sdc_access_restriction').with(
        :command => '/opt/emc/scaleio/scripts/scli_wrap.sh --set_restricted_sdc_mode --restricted_sdc_mode disabled',
        :unless => "/opt/emc/scaleio/scripts/scli_wrap.sh --query_all |grep -q 'MDM restricted SDC mode: disabled'"
    )}
  end
end

