// ignore_for_file: unnecessary_raw_strings
/// Current app version
const String version = r'1.2.4+55';

/// The major version number: "1" in "1.2.3".
const int major = 1;

/// The minor version number: "2" in "1.2.3".
const int minor = 2;

/// The patch version number: "3" in "1.2.3".
const int patch = 4;

/// The pre-release identifier: "foo" in "1.2.3-foo".
const List<String> pre = <String>[];

/// The build identifier: "foo" in "1.2.3+foo".
const List<String> build = <String>[r'55'];

/// Build date in Unix Time
const int date = 1631148813;

/// Get pubspec.yaml as Map<String, dynamic>
const Map<String, dynamic> pubspec = <String, dynamic>{
  'name': r'dan_xi',
  'description':
      r'Maybe the best all-rounded service app for Fudan University students.',
  'publish_to': r'none',
  'version': r'1.2.4+55',
  'environment': <String, dynamic>{
    'sdk': r'>=2.7.0 <3.0.0',
  },
  'dependencies':  <String, dynamic>{
      'flutter':  <String, dynamic>{
        'sdk':  r'flutter',
      },
      'flutter_localizations':  <String, dynamic>{
        'sdk':  r'flutter',
      },
      'cupertino_icons':  r'^1.0.2',
      'dio_cookie_manager':  r'^2.0.0',
      'flutter_progress_dialog':  <String, dynamic>{
        'git':  <String, dynamic>{
        'url':  r'git://github.com/w568w/flutter_progress_dialog.git',
        'ref':  r'master',
      },
      },
      'beautifulsoup':  r'^0.0.1',
      'quick_actions':  r'^0.6.0+1',
      'qr_flutter':  r'^4.0.0',
      'provider':  r'^5.0.0',
      'catcher':  r'^0.6.5',
      'event_bus':  r'^2.0.0',
      'flutter_platform_widgets':  r'^1.1.0',
      'share':  r'^2.0.1',
      'path_provider':  r'^2.0.1',
      'screen':  r'^0.0.5',
      'flutter_email_sender':  r'^5.0.0',
      'auto_size_text':  r'^2.1.0',
      'ical':  r'^0.1.3',
      'url_launcher':  r'^6.0.3',
      'desktop_window':  r'^0.4.0',
      'flutter_html':  r'^2.0.0',
      'intl':  r'^0.17.0-nullsafety.2',
      'http':  r'^0.13.1',
      'dio':  r'^4.0.0',
      'crypto':  r'^3.0.1',
      'shared_preferences':  r'^2.0.5',
      'flutter_phoenix':  r'^1.0.0',
      'asn1lib':  r'^1.0.0',
      'image_picker':  r'^0.8.1',
      'flutter_tagging':  r'^3.0.0',
      'clipboard':  r'^0.1.3',
      'flutter_inappwebview':  r'^5.3.2',
      'permission_handler':  r'^8.1.4+2',
      'in_app_review':  r'^2.0.2',
      'flutter_linkify':  r'^5.0.2',
      'linkify':  r'^4.0.0',
      'open_file':  r'^3.2.1',
      'dio_log':  r'^2.0.0',
      'json_serializable':  r'^3.5.1',
      'photo_view':  r'^0.12.0',
      'gallery_saver':  r'^2.1.2',
      'flutter_markdown':  r'^0.6.2',
      'markdown':  r'^4.0.0',
      'system_tray':  r'^0.0.6',
      'bitsdojo_window':  r'^0.1.1+1',
      'win32':  r'^2.2.5',
      'file_picker':  r'^4.0.0',
      'cached_network_image':  r'^3.1.0',
      'google_mobile_ads':  r'^0.13.4',
  },
  'dependency_overrides':  <String, dynamic>{
      'fluttertoast':  <String, dynamic>{
        'git':  <String, dynamic>{
        'url':  r'git://github.com/ponnamkarthik/FlutterToast.git',
        'ref':  r'master',
      },
      },
      'linkify':  <String, dynamic>{
        'git':  <String, dynamic>{
        'url':  r'git://github.com/kavinzhao/linkify.git',
        'ref':  r'master',
      },
      },
      'html':  r'^0.15.0',
  },
  'dev_dependencies':  <String, dynamic>{
      'build_runner':  r'^1.11.0',
      'pubspec_generator':  r'^2.1.1-dev',
      'flutter_test':  <String, dynamic>{
        'sdk':  r'flutter',
      },
  },
  'flutter_intl':  <String, dynamic>{
      'enabled':  r'true',
  },
  'flutter':  <String, dynamic>{
      'uses-material-design':  r'true',
      'assets':  <dynamic>[
r'assets/graphics/',
      ],
      'fonts':  <dynamic>[
<String, dynamic>{
        'family':  r'iconfont',
        'fonts':  <dynamic>[
<String, dynamic>{
        'asset':  r'assets/fonts/iconfont.ttf',
      },
      ],
      },
      ],
  },
};
