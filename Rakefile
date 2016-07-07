require 'bundler'
Bundler.require(:rake)

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('2.0.0')
  require 'puppet_blacksmith/rake_tasks'
end

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = ["spec/**/*.pp", "vendor/**/*.pp"]
  config.log_format = '%{path}:%{linenumber}:%{KIND}: %{message}'
  config.disable_checks = [ "class_inherits_from_params_class", "80chars" ]
end

# use librarian-puppet to manage fixtures instead of .fixtures.yml
# offers more possibilities like explicit version management, forge downloads,...
task :librarian_spec_prep do
  sh "librarian-puppet install --path=spec/fixtures/modules/"
  pwd = Dir.pwd.strip
  unless File.directory?("#{pwd}/spec/fixtures/modules/scaleio")
    # workaround for windows as symlinks are not supported with 'ln -s' in git-bash
    if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      begin
        sh "cmd /c \"mklink /d #{pwd}\\spec\\fixtures\\modules\\scaleio #{pwd}\""
      rescue Exception => e
        puts '-----------------------------------------'
        puts 'Git Bash must be started as Administrator'
        puts '-----------------------------------------'
        raise e
      end
    else
      sh "ln -s #{pwd} #{pwd}/spec/fixtures/modules/scaleio"
    end
  end
end

# Windows rake spec task for git bash
# default spec task fails because of unsupported symlinks on windows
task :spec_win do
  sh "rspec --pattern spec/\{classes,defines,unit,functions,hosts,integration\}/\*\*/\*_spec.rb --color"
end

task :spec_clean_win do
  pwd = Dir.pwd.strip
  sh "cmd /c \"rmdir /q #{pwd}\\spec\\fixtures\\modules\\scaleio\""
end

task :spec_prep => :librarian_spec_prep

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  task :default => [:spec_prep, :spec_win, :spec_clean, :spec_clean_win, :lint]
else
  task :default => [:spec, :lint]
end
