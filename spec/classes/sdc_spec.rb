require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::sdc', :type => 'class' do
  # facts definition
  let(:facts_default) do
    {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7',
        :concat_basedir => '/var/lib/puppet/concat',
        :is_virtual => false,
        :ipaddress => '10.0.0.1',
        :interfaces => 'eth0',
        :ipaddress_eth0 => '10.0.0.20',
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
    it { should contain_package_verifiable('EMC-ScaleIO-sdc').with_version('installed') }

    it { should contain_service('scini').with(
      :ensure  => 'running',
      :enable  => true,
      :require => 'Package_verifiable[EMC-ScaleIO-sdc]',
      :before  => 'Exec[scaleio::sdc_add_mdm]',
    )}

    it { should contain_exec('scaleio::sdc_add_mdm').with(
      :command  => '/bin/emc/scaleio/drv_cfg --add_mdm --ip 10.0.0.1,10.0.0.2,10.0.0.3 --file /bin/emc/scaleio/drv_cfg.txt',
      :unless   => 'grep -qE \'^mdm \' /bin/emc/scaleio/drv_cfg.txt',
      :before   => ['Exec[scaleio::sdc_mod_mdm]'],
    )}

    it { should contain_exec('scaleio::sdc_mod_mdm').with(
      :command => "/bin/emc/scaleio/drv_cfg --mod_mdm_ip --ip $(grep -E '^mdm' /bin/emc/scaleio/drv_cfg.txt |awk '{print $2}' |awk -F ',' '{print $1}') --new_mdm_ip 10.0.0.1,10.0.0.2,10.0.0.3 --file /bin/emc/scaleio/drv_cfg.txt",
      :unless  => "grep -qE '^mdm 10.0.0.1,10.0.0.2,10.0.0.3$' /bin/emc/scaleio/drv_cfg.txt",
    )}
    it { should_not contain_file_line ( 'scaleio_lvm_types') }
  end
  context 'with a missing primary ip' do
    let(:pre_condition) {
      "class{'scaleio': mdm_ips => [] }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with a missing secondary ip' do
    let(:pre_condition) {
      "class{'scaleio': mdm_ips => [] }"
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with lvm config' do
    let(:pre_condition){
      "class{'scaleio': lvm => true }"
    }
    it { should contain_file_line('scaleio_lvm_types').with(
      :ensure => 'present',
      :path   => '/etc/lvm/lvm.conf',
      :line   => '    types = [ "scini", 16 ]',
      :match  => 'types\s*=\s*\['
    )}
  end
  context 'should not update SIO packages' do
    let(:facts) { facts_default.merge({:package_emc_scaleio_sdc_version => '1'}) }

    it { should contain_package_verifiable('EMC-ScaleIO-sdc').with(
      :version        => 'installed',
      :manage_package => false
    )}
  end
end

