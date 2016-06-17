require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio', :type => 'class' do

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
    ]
  end

  describe 'with standard' do
    it { should contain_package('numactl').with_ensure('present') }
    it { should contain_package('python').with_ensure('present') }

    it { should_not contain_class('sdc') }
    it { should_not contain_class('sds') }
    it { should_not contain_class('lia') }
    it { should_not contain_class('mdm') }
    it { should_not contain_class('tb') }
  end


  describe 'mdm install' do
    context 'on the primary mdm node' do
      it { should contain_class('scaleio::mdm') }
    end
    context 'on the third mdm node' do
      let(:facts) { facts_default.merge({
                                            :ipaddress => '10.0.0.3',
                                            :interfaces => 'eth0',
                                            :ipaddress_eth0 => '10.0.0.3',
                                        }) }

      it { should contain_class('scaleio::mdm') }
    end
  end

  describe 'tb install' do
    context 'on the first tie-breaker node' do
      let(:facts) { facts_default.merge({
                                            :ipaddress => '10.0.0.4',
                                            :interfaces => 'eth0',
                                            :ipaddress_eth0 => '10.0.0.4',
                                        }) }

      it { should contain_class('scaleio::tb') }
    end
    context 'on the second tie-breaker node' do
      let(:facts) { facts_default.merge({
                                            :ipaddress => '10.0.0.5',
                                            :interfaces => 'eth0',
                                            :ipaddress_eth0 => '10.0.0.5',
                                        }) }

      it { should contain_class('scaleio::tb') }
    end
  end

  describe 'sdc install' do
    let(:params) { {
        :components => ['sdc'],
    } }

    it { should contain_class('scaleio::sdc') }
  end

  describe 'sds install' do
    let(:params) { {
        :components => ['sds'],
    } }

    it { should contain_class('scaleio::sds') }
  end

  describe 'lia install' do
    let(:params) { {
        :components => ['lia'],
    } }

    it { should contain_class('scaleio::lia') }
  end
end
