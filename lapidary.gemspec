require_relative 'lib/lapidary/version'

Gem::Specification.new do |spec|
  spec.name          = "lapidary"
  spec.version       = Lapidary::VERSION
  spec.authors       = ["Joseph Johansen"]
  spec.email         = ["joe@stotles.com"]

  spec.summary       = %q{Generate ruby from rbs blueprints}
  spec.description   = "Don't write your code, and rbs types! Write the rbs types first, then generate a bolierplate to fill in with business logic."
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "rbs"
  spec.add_development_dependency "pry-byebug"
end
