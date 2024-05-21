# encoding: utf-8
require 'rake'
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "fluent-plugin-redaction-alt"
  gem.description = "Fluentd redaction filter plugin for anonymize specific strings in text data."
  gem.license = "MIT License"
  gem.homepage = "https://github.com/oleewere/fluent-plugin-redaction"
  gem.summary = gem.description
  gem.version = File.read("VERSION").strip
  gem.authors = ["Oliver Szabo"]
  gem.email = ["oleewere@gmail.com"]
  #gem.platform    = Gem::Platform::RUBY
  gem.files = FileList['lib/**/*.rb']
  gem.test_files = FileList['test/**/*.rb']
  gem.executables =  FileList['bin/*']
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'fluentd', ['>= 1.0', '< 2']
  gem.add_development_dependency "rake",      ["~> 13.0"]
  gem.add_development_dependency 'test-unit', '~> 3.3', '>= 3.3.3'
  gem.add_development_dependency 'test-unit-rr', '~> 1.0', '>= 1.0.5'
end
