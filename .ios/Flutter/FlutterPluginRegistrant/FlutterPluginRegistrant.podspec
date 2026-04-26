#
# Generated file, do not edit.
#

Pod::Spec.new do |s|
  s.name             = 'FlutterPluginRegistrant'
  s.version          = '0.0.1'
  s.summary          = 'Registers plugins with your Flutter app'
  s.description      = <<-DESC
Depends on all your plugins, and provides a function to register them.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.ios.deployment_target = '13.0'
  s.source_files =  "Classes", "Classes/**/*.{h,m}"
  s.source           = { :path => '.' }
  s.public_header_files = './Classes/**/*.h'
  s.static_framework    = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.dependency 'Flutter'
  s.dependency 'app_links'
  s.dependency 'device_identity'
  s.dependency 'device_info_plus'
  s.dependency 'file_picker'
  s.dependency 'flutter_email_sender'
  s.dependency 'flutter_fgbg'
  s.dependency 'flutter_inappwebview_ios'
  s.dependency 'flutter_secure_storage_darwin'
  s.dependency 'gal'
  s.dependency 'image_picker_ios'
  s.dependency 'in_app_review'
  s.dependency 'no_screenshot'
  s.dependency 'open_file_ios'
  s.dependency 'path_provider_foundation'
  s.dependency 'permission_handler_apple'
  s.dependency 'quick_actions_ios'
  s.dependency 'screen_brightness_ios'
  s.dependency 'share_plus'
  s.dependency 'shared_preferences_foundation'
  s.dependency 'sqflite_darwin'
  s.dependency 'url_launcher_ios'
end
