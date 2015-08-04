require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
      :architecture => 'x86_64',
      :operatingsystem => 'RedHat',
    }
  }
  describe 'with standard' do
    it { should contain_package('numactl').with_ensure('present') }
    it { should contain_package('python').with_ensure('present') }
  end
  context 'on the primary mdm node' do
    let(:facts){
      {
        :interfaces     => 'eth0',
        :ipaddress_eth0 => '1.2.3.4',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
      }
    }
    it { should contain_class('scaleio::mdm') }
  end
  context 'with only primary ip' do
    let(:params) {
      {
        :mdm_ips => ['1.2.3.4', false],
      }
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with only secondary ip' do
    let(:params) {
      {
        :mdm_ips => [false, '1.2.3.4'],
      }
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with wrong primary ip' do
    let(:params) {
      {
        :mdm_ips => ['1.2.3.4a', '1.2.3.4'],
      }
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with wrong secondary ip' do
    let(:params) {
      {
        :mdm_ips => ['1.2.3.4', '1.2.3.4a'],
      }
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with wrong tb ip' do
    let(:params) {
      {
        :tb_ips => ['1.2.3.4s'],
      }
    }
    it { expect { subject.call('fail') }.to raise_error(/wrong number of arguments/) }
  end
  context 'with standby mdms' do
    let(:facts){
      {
        :interfaces     => 'eth0',
        :ipaddress_eth0 => '1.2.3.4',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
      }
    }
    let(:params) {
      {
        :mdm_ips => ['1.2.3.4','1.2.3.5','1.2.3.6','1.2.3.7'],
        :tb_ips => ['1.2.3.8','1.2.3.9'],
      }
    }
    it { should contain_class('scaleio::mdm') }
  end
  context 'with standby tbs' do
    let(:facts){
      {
        :interfaces     => 'eth0',
        :ipaddress_eth0 => '1.2.3.8',
        :architecture => 'x86_64',
        :operatingsystem => 'RedHat',
      }
    }
    let(:params) {
      {
        :mdm_ips => ['1.2.3.4','1.2.3.5','1.2.3.6','1.2.3.7'],
        :tb_ips => ['1.2.3.8','1.2.3.9'],
      }
    }
    it { should contain_class('scaleio::tb') }
  end
end
