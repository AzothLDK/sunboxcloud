#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint smart_ble_link.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'smart_ble_link'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin for SmartBLELink.'
  s.description      = <<-DESC
A new Flutter plugin for SmartBLELink.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :text => 'MIT License' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'jy_blueSDK/jy_blueSDK/**/*.{h,m,c}'
  s.public_header_files = 'Classes/**/*.h', 'jy_blueSDK/jy_blueSDK/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'CoreBluetooth', 'CoreLocation', 'SystemConfiguration'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
