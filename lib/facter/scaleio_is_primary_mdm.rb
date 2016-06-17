Facter.add('scaleio_is_primary_mdm') do
  confine :kernel => 'Linux'

  setcode do
    output = Facter::Util::Resolution.exec('scli --query_cluster --approve_certificate 2>/dev/null')
    output.nil? ? false : !!(output =~ /Master MDM:/)
  end
end
