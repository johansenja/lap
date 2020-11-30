require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Build ruby files from rbs files"
task :make do
  require "find"
  Find.find(File.join(File.expand_path(File.dirname(__FILE__)), "sig")).each do |fname|
    next unless fname.end_with? ".rbs" # TODO: better way to exclude dirs?

    fname_relative_to_project = fname[%r{sig/.*\.rbs}]
    output_fname = fname_relative_to_project.sub(/sig/, "lib")
                                            .chomp("s") # turn rbs to rb
    sh "./exe/lap #{fname_relative_to_project} > #{output_fname}"
  end
end
