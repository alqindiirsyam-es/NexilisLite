# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'NexilisLite' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for NexilisLite

  pod 'nuSDKService', '5.0.2'
  pod 'FMDB/SQLCipher', '~> 2.7.12'
  pod 'NotificationBannerSwift', :git => 'https://github.com/Daltron/NotificationBanner.git', :tag => '4.0.0'
  pod 'Alamofire', '~> 5.10.2'
  pod 'SDWebImage', '~> 5.20.0'
  pod 'Toast-Swift', '~> 5.1.1'
  pod 'ZIPFoundation', '~> 0.9.19'
  pod 'SwiftLinkPreview', '~> 3.4.0'
  pod 'Popover', '~> 1.3.0'
  pod 'KeychainAccess', '~> 4.2.2'
  pod 'Firebase/Auth', '~> 11.14.0'

  target 'NexilisLiteTests' do
    # Pods for testing
  end
  
end

# Firebase and SDWebImage must NOT be absorbed into NexilisLite.framework.
#
# Every other pod here is linked statically *into* the framework, which is fine
# because nothing else in the iOS ecosystem is likely to ship a second copy.
# Firebase and SDWebImage are different: they are Objective-C, they register
# their classes with the ObjC runtime by name, and consumers very often already
# have them (firebase_core / firebase_messaging in Flutter, @react-native-firebase
# in React Native). Two copies in one process means duplicate class registration,
# and for Firebase that is not cosmetic — FIRApp holds singleton state, so the
# copy that wins is the copy that owns the FCM token.
#
# Forcing them to build as dynamic frameworks leaves NexilisLite.framework with
# undefined references bound to @rpath instead of its own embedded copy. The
# distribution podspec then declares them with `spec.dependency`, so the
# consumer's CocoaPods resolves exactly one copy for the whole app.
#
# Consequence: consumers must use dynamic frameworks (`use_frameworks!`), since a
# dynamic framework cannot bind to a pod that was linked statically into the app.
DYNAMIC_PODS = %w[
  Firebase
  FirebaseAuth
  FirebaseAuthInterop
  FirebaseAppCheckInterop
  FirebaseCore
  FirebaseCoreExtension
  FirebaseCoreInternal
  GoogleUtilities
  GTMSessionFetcher
  RecaptchaInterop
  SDWebImage
  # FMDB cannot be absorbed: 15 public declarations take or return
  # FMDatabase / FMResultSet / FMDatabaseQueue (Database.shared.getRecords and
  # friends, which AppBuilder uses), so the generated .swiftinterface names the
  # module and a consumer must actually have it. SQLCipher comes with it —
  # FMDB/SQLCipher is compiled against it, not the system libsqlite3.
  FMDB
  SQLCipher
  # Toast-Swift and ZIPFoundation extend UIView and FileManager, and those
  # extensions are reachable from a consumer that only writes `import
  # NexilisLite` — verified: UIView().makeToast(…) and
  # FileManager.default.zipItem(…) both compile against the published binary
  # pod. Hiding them would silently take working API away, so they are shipped
  # as declared dependencies instead. Named types (Keychain, NotificationBanner,
  # Popover, SwiftLinkPreview) are NOT reachable that way and stay absorbed.
  Toast-Swift
  ZIPFoundation
].freeze

pre_install do |installer|
  installer.pod_targets.each do |pod|
    next unless DYNAMIC_PODS.include?(pod.name)
    # `build_type` is derived from the Podfile's `use_frameworks!`, so it has to
    # be overridden per pod target rather than declared in the DSL.
    def pod.build_type
      Pod::BuildType.dynamic_framework
    end
  end
end

# Library evolution belongs to NexilisLite alone.
#
# make-release.sh used to pass BUILD_LIBRARY_FOR_DISTRIBUTION=YES on the xcodebuild
# command line, and command-line settings apply to every target in the workspace —
# including the pods. That mattered once Firebase stopped being absorbed: a
# FirebaseAuth built with library evolution exports 268 resilient dispatch thunks,
# and NexilisLite linked against those thunks. A consumer's CocoaPods builds
# FirebaseAuth normally, which exports zero of them, so the app would compile,
# link, and then die at launch with
#     dyld: Symbol not found: _$s12FirebaseAuth0B0C4authACyFZTj
#
# Setting it here, on the framework target only, leaves the pods non-resilient.
# NexilisLite then calls Firebase through its direct symbols, which are exactly
# what a consumer's build provides, while NexilisLite itself keeps the resilient
# ABI that lets a different Swift compiler consume it.
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |c|
      c.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
  end
  installer.aggregate_targets.each do |agg|
    agg.user_project.targets.each do |t|
      next unless t.name == 'NexilisLite'
      t.build_configurations.each do |c|
        c.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
    agg.user_project.save
  end
end
