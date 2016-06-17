Facter.add('scaleio_mdm_clustersetup_needed') do
  confine :kernel => 'Linux'

  setcode do
      output = Facter::Util::Resolution.exec('scli --query_cluster --approve_certificate 2>&1')
      output.nil? ? true : !!(output =~ /The MDM cluster state is incorrect/)
  end
end
