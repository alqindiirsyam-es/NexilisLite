#
#  Be sure to run `pod spec lint PalioLite.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "NexilisLite"
  spec.version      = "5.0.5"
  spec.summary      = "NexilisLite Framework"
  spec.description  = <<-DESC
  NexilisLite Framework, embed Contact Center, Live Streaming, Push Notifications, Instant Messaging, Video and VoIP Calling features into your mobile apps within minutes...
                   DESC

  spec.homepage     = "https://nexilis.io/"
  spec.license      = "MIT"
  spec.author       = { "Yayan D Wicaksono" => "ya2n.wicaksono@gmail.com" }
  spec.ios.deployment_target = "14.0"
#  spec.source       = { :http => 'https://nexilis.io/UCPaaSiOS/releases/download/NexilisLite/v2.2.2/NexilisLite.zip' }
  spec.source       = { :path => '.' }
  spec.source_files = 'NexilisLite/Source/**/*'
  spec.resource_bundles = { 'NexilisLite' => ['NexilisLite/Resource/**/*']}
  spec.swift_version = '5.5.1'
  spec.dependency 'FMDB', '~> 2.7.12'
  spec.dependency 'nuSDKService', '~> 4.0.4'
  spec.dependency 'NotificationBannerSwift', '~> 3.1.0'
  spec.dependency 'Alamofire', '~> 5.10.1'
  spec.dependency 'SDWebImage', '~> 5.20.0'
  spec.dependency 'Toast-Swift', '~> 5.1.1'
  spec.dependency 'ZIPFoundation', '~> 0.9.19'
  spec.dependency 'SwiftLinkPreview', '~> 3.4.0'
  spec.dependency 'KeychainAccess'
  spec.dependency 'Popover'
# spec.static_framework = true
# spec.dependency 'iOS-WebP'
#  spec.vendored_frameworks = 'nuSDKService.framework'
  spec.ios.vendored_frameworks = "NexilisLite.framework"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
end
