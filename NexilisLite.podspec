#
#  Be sure to run `pod spec lint PalioLite.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "NexilisLite"
  spec.version      = "6.0.7"
  spec.summary      = "NexilisLite Framework"
  spec.description  = <<-DESC
  NexilisLite Framework, embed Contact Center, Live Streaming, Push Notifications, Instant Messaging, Video and VoIP Calling features into your mobile apps within minutes...
                   DESC

  spec.homepage     = "https://nexilis.io/"
  spec.license      = "MIT"
  spec.author       = { "Yayan D Wicaksono" => "ya2n.wicaksono@gmail.com" }
  spec.ios.deployment_target = "15.0"
#  spec.source       = { :http => 'https://nexilis.io/UCPaaSiOS/releases/download/NexilisLite/v2.2.2/NexilisLite.zip' }
  spec.source       = { :path => '.' }
  spec.source_files = 'NexilisLite/Source/**/*'
  # Files, named one folder at a time. Fix: '**/*' matched the Gifs, Sound, Stickers and fonts
  # folders as well as what is in them, so the bundle carried every one of those files twice -
  # once loose, where the code looks for them, and once again inside a copy of the folder.
  spec.resource_bundles = { 'NexilisLite' => [
    'NexilisLite/Resource/*.{xcassets,storyboard,xib,lproj}',
    'NexilisLite/Resource/{Gifs,Sound,Stickers,fonts}/*.*'
  ]}
  spec.swift_version = '5.5.1'
  spec.dependency 'NexilisZTA', '~> 6.0.7'
  spec.dependency 'NexilisSecurityShield', '~> 6.0.7'
  spec.dependency 'FMDB/SQLCipher', '~> 2.7.12'
  spec.dependency 'nuSDKService', '5.0.2'
  spec.dependency 'NotificationBannerSwift'
  spec.dependency 'Alamofire', '~> 5.10.2'
  spec.dependency 'SDWebImage', '~> 5.20.0'
  spec.dependency 'Toast-Swift', '~> 5.1.1'
  spec.dependency 'ZIPFoundation', '~> 0.9.19'
  spec.dependency 'SwiftLinkPreview', '~> 3.4.0'
  spec.dependency 'KeychainAccess', '~> 4.2.2'
  spec.dependency 'Popover', '~> 1.3.0'
  spec.dependency 'Firebase/Auth', '~> 11.14.0'
# spec.static_framework = true
# spec.dependency 'iOS-WebP'
#  spec.vendored_frameworks = 'nuSDKService.framework'
  spec.ios.vendored_frameworks = "NexilisLite.framework"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
end
