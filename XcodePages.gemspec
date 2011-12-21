# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "XcodePages/version"

Gem::Specification.new do |s|
  s.name        = "XcodePages"
  s.version     = XcodePages::VERSION
  s.authors     = ["Roy Ratcliffe"]
  s.email       = ["roy@pioneeringsoftware.co.uk"]
  s.homepage    = ""
  s.summary     = %q{Helps you publish documentation from within Xcode using Doxygen}
  s.description = %q{
    Helps you publish HTML web pages on the Internet somewhere appropriate, e.g.
    on GitHub via the gh-pages branch feature.

    Works for Objective-C projects built using Apple's Xcode IDE and
    consequently focuses on documentation within Objective-C and Objective-C++
    source files; files ending with extensions h, m or mm.}

  s.rubyforge_project = "XcodePages"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_runtime_dependency "activesupport"
end
