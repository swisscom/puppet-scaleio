Facter.add('scaleio_is_primary_mdm') do
  setcode do
    command = "scli --query_cluster"
    if Facter.value(:kernel) == 'windows'
      command = "#{command} 2>NUL"
    else
      command = "#{command} 2>/dev/null"
    end
    output = Facter::Util::Resolution.exec command
    output.nil? ? false : output.include?("Primary IP")
  end
end
