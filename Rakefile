require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task["spec"].execute
end
