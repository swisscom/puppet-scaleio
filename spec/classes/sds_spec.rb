require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio::sds', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
    }
  }
  describe 'with standard' do
    it { should compile.with_all_deps }
    it { should contain_class('scaleio') }
    it { should contain_package__verifiable('EMC-ScaleIO-sds').with_version('installed') }
  end
  context 'should not update SIO packages' do
    let(:facts){
      {
        :interfaces => 'eth0,eth10',
        :ipaddress_eth10 => '1.2.3.4',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
        :package_emc_scaleio_sds_version => 'asdfadf',
      }
    }
    it { should contain_package__verifiable('EMC-ScaleIO-sds').with(
      :version        => 'installed',
      :manage_package => false
    )}
    it { should contain_package('EMC-ScaleIO-sds').with(
      :ensure  => 'installed',
    )}
  end
end

