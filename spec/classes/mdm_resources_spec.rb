require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::resources', :type => 'class' do

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
    it { should compile.with_all_deps }

    it { should contain_scaleio_user('api_admin').with(
        :role => 'Administrator',
        :password => 'myPassAPI1',
    ) }

    it { should contain_scaleio_protection_domain('pdo') }

    it { should contain_scaleio_storage_pool('pdo:pool1').with(
        :spare_policy => '34%',
        :ramcache => 'enabled',
        :zeropadding => true
    ) }

    it { should contain_scaleio_storage_pool('pdo:pool2').with(
        :spare_policy => '34%',
        :ramcache => 'disabled',
        :zeropadding => false
    ) }

    it { should contain_scaleio_sds('sds-1').with(
        :protection_domain => 'pdo',
        :pool_devices => {'pool1' => ['/dev/sdb']},
        :ips => ['192.168.56.121'],
        :ramcache_size => 128,
    ) }

    it { should contain_scaleio_sds('sds-2').with(
        :protection_domain => 'pdo',
        :pool_devices => {'pool1' => ['/dev/sdb']},
        :ips => ['192.168.56.122'],
        :ramcache_size => 1024,
    ) }

    it { should contain_scaleio_sds('sds-3').with(
        :protection_domain => 'pdo',
        :pool_devices => {'pool1' => ['/dev/sdb']},
        :ips => ['192.168.56.123'],
        :ramcache_size => -1,
    ) }

    it { should contain_scaleio_sdc('192.168.56.121').with(
        :desc => 'sdc-1',
    ) }

    it { should contain_scaleio_sdc('192.168.56.122').with(
        :desc => 'sdc-2',
    ) }

    it { should contain_scaleio_sdc('192.168.56.123').with(
        :desc => 'sdc-3',
    ) }

    it { should contain_scaleio_volume('volume-1').with(
        :protection_domain => 'pdo',
        :storage_pool => 'pool1',
        :size => 8,
        :type => 'thick',
        :sdc_nodes => ['sdc-1'],
    ) }

    it { should contain_scaleio_volume('volume-2').with(
        :protection_domain => 'pdo',
        :storage_pool => 'pool2',
        :size => 16,
        :type => 'thin',
        :sdc_nodes => ['sdc-1', 'sdc-2'],
    ) }

    it { should contain_resources('scaleio_protection_domain').with(
        :purge => false,
    ) }
    it { should contain_resources('scaleio_storage_pool').with(
        :purge => false,
    ) }
    it { should contain_resources('scaleio_sds').with(
        :purge => false,
    ) }
    it { should contain_resources('scaleio_sdc').with(
        :purge => false,
    ) }
    it { should contain_resources('scaleio_volume').with(
        :purge => false,
    ) }
  end
end
