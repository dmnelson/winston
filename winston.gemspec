Gem::Specification.new do |gem|
  gem.name        = 'winston'
  gem.version     = '0.1.0'
  gem.authors     = ['David Michael Nelson']
  gem.homepage    = 'http://github.com/dmnelson/winston'

  gem.summary     = 'Constraint Satisfaction Problem (CSP) implementation for Ruby'
  gem.description = 'A small, practical CSP library for Ruby with multiple solvers, heuristics, and a DSL.'
  gem.license     = 'MIT'
  gem.required_ruby_version = ">= 3.0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "bundler", "~> 2.4", ">= 2.4.22"
  gem.add_development_dependency "rake", "~> 13.1"
  gem.add_development_dependency "rspec", "~> 3.13"
end
