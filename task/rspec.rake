require 'rspec/core/rake_task'

desc 'Run Rspec tests'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--color --format documentation --backtrace'
end
