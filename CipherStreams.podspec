Pod::Spec.new do |s|

  s.name         = "CipherStreams"
  s.version      = "0.2.0"
  s.summary      = "High-level API for reading and writing large encrypted files"

  s.homepage     = "https://github.com/jospete/CipherStreams"
  s.license      = "MIT"
  s.author             = { "Obsidize LLC" => "obsidize@gmail.com" }
 
  s.osx.deployment_target = '10.13'
  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '5.1'

  s.source       = { :git => "https://github.com/jospete/CipherStreams.git", :tag => s.version.to_s }

  s.source_files  = "CipherStreams"

  # New way to specify Swift version 
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    "APPLICATION_EXTENSION_API_ONLY" => "YES"
  }

  s.dependency 'IDZSwiftCommonCrypto', '~> 0.13'

end
