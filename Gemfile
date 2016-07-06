source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
  puppetversion = "~> #{ENV['PUPPET_VERSION']}"
else
  puppetversion = ['~> 3.7.5']
end

gem 'puppet', puppetversion
gem 'puppet-lint'
gem 'puppetlabs_spec_helper'
gem 'rake'
gem 'librarian-puppet'

if RUBY_VERSION == '2.3.0'
  gem 'simplecov', :require => false, :group => :test
end
