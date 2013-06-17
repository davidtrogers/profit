$:.push File.expand_path("../lib", __FILE__)

require "profit/version"

Gem::Specification.new do |s|
  s.name        = "profit"
  s.version     = Profit::VERSION
  s.executables << 'profit_server'
  s.executables << 'profit_app'
  s.authors     = ["Dave Rogers"]
  s.email       = ["david.t.rogers@gmail.com"]
  s.homepage    = "https://github.com/davidtrogers/profit"
  s.summary     = "A simple library to store profiling information for ruby code."
  s.description = "This is a client/server combination that allows you to profile code and send the results to a remote Redis server."

  s.files = Dir["{lib}/**/*"] + ["README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "eventmachine"
  s.add_dependency "rbczmq"
  s.add_dependency "em-hiredis"
  s.add_dependency "sinatra"
  s.add_dependency "active_support"

  s.add_development_dependency "debugger"
  s.add_development_dependency "redis"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "capybara"
  s.add_development_dependency "shotgun"
  s.add_development_dependency "thin"
end
