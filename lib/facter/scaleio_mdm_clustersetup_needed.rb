Facter.add('scaleio_mdm_clustersetup_needed') do
  setcode do
    if Facter.value(:kernel) == 'windows'
      false
    else
      output = Facter::Util::Resolution.exec('scli --query_cluster 2>&1')
      output.nil? ? true : !!(output =~ /The MDM cluster state is incorrect/)
    end
  end
end
