Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-elasticsearch-timestamper"
  spec.version       = "0.3.0"
  spec.authors       = ["Stephen Gran"]
  spec.email         = ["stephen.gran@piksel.com"]
  spec.description   = %q{fluent filter plugin to ensure @timestamp is in proper format}
  spec.summary       = %q{fluent timestamp checker filter}
  spec.homepage      = "https://github.com/pikselpalette/fluent-plugin-elasticsearch-timestamper"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'fluentd', '~> 0.10.17'
  spec.add_runtime_dependency "fluent-mixin-rewrite-tag-name"
  spec.add_development_dependency 'rake'
  spec.add_development_dependency "test-unit", '> 3.2.0'
end
