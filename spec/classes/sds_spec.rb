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
end

