require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'scaleio', :type => 'class' do
  let(:facts){
    {
      :interfaces => 'eth0',
    }
  }
  describe 'with standard' do
    it { should contain_package('numactl').with_ensure('present') }
    it { should contain_package('python-paramiko').with_ensure('present') }
  end
  context 'on the primary mdm node' do
    let(:facts){
      {
        :interfaces     => 'eth0',
        :ipaddress_eth0 => '1.2.3.4',
      }
    }
    it { should contain_class('scaleio::mdm') }
  end
  context 'with only primary ip' do
    let(:params) {
      {
        :primary_mdm_ip => '1.2.3.4',
        :secondary_mdm_ip => false,
      }
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
  context 'with only secondary ip' do
    let(:params) {
      {
        :primary_mdm_ip => false,
        :secondary_mdm_ip => '1.2.3.4',
      }
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
  context 'with wrong primary ip' do
    let(:params) {
      {
        :primary_mdm_ip => '1.2.3.4a',
        :secondary_mdm_ip => '1.2.3.4',
      }
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
  context 'with wrong secondary ip' do
    let(:params) {
      {
        :primary_mdm_ip => '1.2.3.4',
        :secondary_mdm_ip => '1.2.3.4a',
      }
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
  context 'with wrong tb ip' do
    let(:params) {
      {
        :tb_ip => '1.2.3.4s',
      }
    }
    it { expect { subject.call('fail') }.to raise_error() }
  end
end
