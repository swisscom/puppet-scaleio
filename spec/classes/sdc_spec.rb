require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::sdc', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
    }
  }
  # mdm ips are configured in hiera
  describe 'with standard' do
    #it { should compile.with_all_deps }
    it { should contain_class('scaleio') }
    it { should contain_package__verifiable('EMC-ScaleIO-sdc').with_version('installed') }

    it { should contain_exec('scaleio::sdc_add_mdm').with(
      :command  => '/bin/emc/scaleio/drv_cfg --add_mdm --ip 1.2.3.4,1.2.3.5 --file /bin/emc/scaleio/drv_cfg.txt',
      :unless   => 'grep -qE \'^mdm \' /bin/emc/scaleio/drv_cfg.txt',
      :require  => 'Package::Verifiable[EMC-ScaleIO-sdc]'
    )}

    it { should contain_exec('scaleio::sdc_mod_mdm').with(
      :command => "/bin/emc/scaleio/drv_cfg --mod_mdm_ip --ip $(grep -E '^mdm' /bin/emc/scaleio/drv_cfg.txt |awk '{print $2}' |awk -F ',' '{print $1}') --new_mdm_ip 1.2.3.4,1.2.3.5 --file /bin/emc/scaleio/drv_cfg.txt",
      :unless  => "grep -qE '^mdm 1.2.3.4,1.2.3.5$' /bin/emc/scaleio/drv_cfg.txt",
      :require  => 'Package::Verifiable[EMC-ScaleIO-sdc]'
    )}
    it { should_not contain_file_line ( 'scaleio_lvm_types') }
  end
  context 'with a missing primary ip' do
    let(:pre_condition) {
      "class{'scaleio': primary_mdm_ip => '' }"
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
  context 'with a missing secondary ip' do
    let(:pre_condition) {
      "class{'scaleio': secondary_mdm_ip => '' }"
    }
    it { expect { subject.call('fail') }.to raise_error() }
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
end

