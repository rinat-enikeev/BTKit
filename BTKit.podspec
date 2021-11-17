Pod::Spec.new do |spec|
  spec.name         = "BTKit"
  spec.version      = "0.4.0"
  spec.summary      = "Hardcoded bluetooth devices API"
  spec.description  = <<-DESC
                        Use to scan for bluetooth devices. Very limited set of devices is available.
                        DESC

  spec.homepage     = "https://github.com/rinat-enikeev/BTKit"
  spec.license      = { :type => "BSD", :file => "LICENSE" }
  spec.author             = { "Rinat Enikeev" => "rinat.enikeev@gmail.com" }
  spec.social_media_url   = "http://facebook.com/enikeev"
  spec.platform     = :ios, "13.0"
  spec.swift_version = '5.3'

  spec.source       = { :git => "https://github.com/rinat-enikeev/BTKit.git", :tag => spec.version.to_s }

  spec.source_files  = "Sources/**/*.{swift,h}"
  spec.resource_bundle = { "BTKit" => ["Sources/BTKit/*.lproj/*.strings"] }
end
