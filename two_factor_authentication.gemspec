# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "two_factor_authentication/version"

Gem::Specification.new do |s|
  s.name        = "devise_xfactor_authentication"
  s.version     = TwoFactorAuthentication::VERSION.dup
  s.authors     = ["Jonathon Pickett"]
  s.email       = ["jpickett76@gmail.com"]
  s.homepage    = "https://github.com/jpickett76/devise_xfactor_authentication"
  s.summary     =  %q{Two factor authentication plugin for devise forked from Houdini/two_factor_authentication}
  s.description = <<-EOF
    ### Features ###
    * control sms code pattern
    * configure max login attempts
    * per user level control if he really need two factor authentication
    * your own sms logic
  EOF

  s.rubyforge_project = "two_factor_authentication"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rails', '~> 5.0'
  s.add_runtime_dependency 'devise', '~> 4'
  s.add_runtime_dependency 'randexp', '~> 0.1'
  s.add_runtime_dependency 'rotp', '~> 6.0.0'
  s.add_runtime_dependency 'encryptor', '~> 3.0.0'

  s.add_development_dependency 'bundler', '~> 2'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'rspec-rails', '~> 6.0'
  s.add_development_dependency 'capybara', '~> 3'
  s.add_development_dependency 'pry', '~> 0.14'
  s.add_development_dependency 'timecop', '~> 0.9'
end
