Pod::Spec.new do |spec|
  spec.name         = "BTKit"
  spec.version      = "0.0.4"
  spec.summary      = "Hardcoded bluetooth devices API"
  spec.description  = <<-DESC
                        Use to scan for bluetooth devices. Very limited set of devices is available.
                        DESC

  spec.homepage     = "https://github.com/rinat-enikeev/BTKit"
  spec.license      = { :type => "BSD", :file => "LICENSE" }
  spec.author             = { "Rinat Enikeev" => "rinat.enikeev@gmail.com" }
  spec.social_media_url   = "http://facebook.com/enikeev"
  spec.platform     = :ios, "10.0"
  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/rinat-enikeev/BTKit.git", :tag => spec.version.to_s }

  spec.source_files  = "BTKit/Source/**/*.{swift,h}"

  spec.subspec 'Devices' do |ss|
    ss.source_files = 'BTKit/Source/Devices/**/*.{swift,h}'
  end

  spec.subspec 'Scanner' do |ss|
    ss.source_files = 'BTKit/Source/Scanner/**/*.{swift,h}'
    ss.dependency 'BTKit/Devices'
  end

  spec.subspec 'Ruuvi' do |ss|
    ss.source_files = 'BTKit/Source/Vendor/Ruuvi/**/*.{swift,h}'
    ss.dependency 'BTKit/Devices'
    ss.dependency 'BTKit/Scanner'
  end


end
