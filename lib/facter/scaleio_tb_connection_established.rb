Facter.add('scaleio_tb_connection_established') do
  setcode do
    if Facter.value(:kernel) == 'windows'
      false
    else
      output = Facter::Util::Resolution.exec "netstat -apn"
      output.nil? ? false : !!(output =~ /9011\s*ESTABLISHED/)
    end
  end
end
