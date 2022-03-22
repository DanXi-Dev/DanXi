/// GENERATED CODE - DO NOT MODIFY BY HAND

/// ***************************************************************************
/// *                            pubspec_generator                            * 
/// ***************************************************************************

/*
  
  MIT License
  
  Copyright (c) 2022 Plague Fox
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
   
 */

// The pubspec file:
// https://dart.dev/tools/pub/pubspec

// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: unnecessary_raw_strings
// ignore_for_file: use_raw_strings
// ignore_for_file: avoid_escaping_inner_quotes
// ignore_for_file: prefer_single_quotes

/// Current app version
const String version = r'1.3.7+163';

/// The major version number: "1" in "1.2.3".
const int major = 1;

/// The minor version number: "2" in "1.2.3".
const int minor = 3;

/// The patch version number: "3" in "1.2.3".
const int patch = 7;

/// The pre-release identifier: "foo" in "1.2.3-foo".
const List<String> pre = <String>[];

/// The build identifier: "foo" in "1.2.3+foo".
const List<String> build = <String>[r'163'];

/// Build date in Unix Time (in seconds)
const int timestamp = 1647747519;

/// Name [name]
const String name = r'dan_xi';

/// Description [description]
const String description = r'Maybe the best all-rounded service app for Fudan University students.';

/// Repository [repository]
const String repository = r'';

/// Issue tracker [issue_tracker]
const String issueTracker = r'';

/// Homepage [homepage]
const String homepage = r'';

/// Documentation [documentation]
const String documentation = r'';

/// Publish to [publish_to]
const String publishTo = r'none';

/// Environment
const Map<String, String> environment = <String, String>{
  'sdk': '>=2.12.0 <3.0.0',
};

/// Dependencies
const Map<String, Object> dependencies = <String, Object>{
  'flutter': <String, Object>{
    'sdk': r'flutter',
  },
  'flutter_localizations': <String, Object>{
    'sdk': r'flutter',
  },
  'cupertino_icons': r'^1.0.4',
  'dio_cookie_manager': r'^2.0.0',
  'flutter_progress_dialog': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/singularity-s0/flutter_progress_dialog.git',
      'ref': r'master',
    },
  },
  'xiao_mi_push_plugin': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/w568w/FlutterXiaoMiPushPlugin.git',
      'ref': r'master',
    },
  },
  'beautiful_soup_dart': r'^0.2.0',
  'quick_actions': r'^0.6.0+9',
  'qr_flutter': r'^4.0.0',
  'provider': r'^6.0.2',
  'event_bus': r'^2.0.0',
  'flutter_platform_widgets': r'^1.20.0',
  'share_plus': r'^3.1.0',
  'path_provider': r'^2.0.9',
  'screen_brightness': r'^0.1.4',
  'flutter_email_sender': r'^5.1.0',
  'auto_size_text': r'^3.0.0',
  'ical': r'^0.2.2',
  'url_launcher': r'^6.0.20',
  'desktop_window': r'^0.4.0',
  'intl': r'^0.17.0',
  'http': r'^0.13.4',
  'dio': r'^4.0.4',
  'shared_preferences': r'^2.0.13',
  'flutter_phoenix': r'^1.0.0',
  'asn1lib': r'^1.0.0',
  'image_picker': r'^0.8.4+9',
  'clipboard': r'^0.1.3',
  'flutter_inappwebview': r'^5.3.2',
  'permission_handler': r'^8.3.0',
  'in_app_review': r'^2.0.4',
  'flutter_linkify': r'^5.0.2',
  'linkify': r'^4.0.0',
  'open_file': r'^3.2.1',
  'dio_log': r'^2.0.2',
  'json_serializable': r'^6.1.4',
  'photo_view': r'^0.13.0',
  'gallery_saver': r'^2.3.2',
  'flutter_markdown': r'^0.6.9',
  'markdown': r'^4.0.1',
  'system_tray': r'^0.1.0',
  'bitsdojo_window': r'^0.1.1+1',
  'win32': r'^2.4.1',
  'file_picker': r'^4.0.0',
  'cached_network_image': r'^3.2.0',
  'google_mobile_ads': r'^1.1.0',
  'flutter_typeahead': r'>=3.1.0 <4.0.0',
  'collection': r'>=1.15.0 <2.0.0',
  'meta': r'>=1.3.0 <2.0.0',
  'flutter_layout_grid': r'^1.0.3',
  'flutter_js': r'^0.5.0+6',
  'flutter_math_fork': r'^0.6.1',
  'platform_device_id': r'^1.0.1',
  'uuid': r'^3.0.5',
  'screen_capture_event': r'^1.0.0+1',
  'otp': r'^3.0.2',
  'lunar': r'^1.2.17',
  'animated_text_kit': r'^4.2.1',
  'flutter_fgbg': r'^0.1.0',
  'lazy_load_indexed_stack': r'^0.1.3',
  'js': r'^0.6.3',
  'add_2_calendar': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/singularity-s0/add_2_calendar.git',
      'ref': r'master',
    },
  },
};

/// Developer dependencies
const Map<String, Object> devDependencies = <String, Object>{
  'build_runner': r'^2.1.2',
  'pubspec_generator': r'^3.0.1',
  'flutter_test': <String, Object>{
    'sdk': r'flutter',
  },
  'flutter_lints': r'^1.0.4',
};

/// Dependency overrides
const Map<String, Object> dependencyOverrides = <String, Object>{
  'device_info_plus': r'^3.2.1',
  'fluttertoast': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/ponnamkarthik/FlutterToast.git',
      'ref': r'master',
    },
  },
  'linkify': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/singularity-s0/linkify.git',
      'ref': r'master',
    },
  },
};

/// Executables
const Map<String, Object> executables = <String, Object>{};

/// Source data from pubspec.yaml
const Map<String, Object> source = <String, Object>{
  'name': name,
  'description': description,
  'repository': repository,
  'issue_tracker': issueTracker,
  'homepage': homepage,
  'documentation': documentation,
  'publish_to': publishTo,
  'version': version,
  'environment': environment,
  'dependencies': dependencies,
  'dev_dependencies': devDependencies,
  'dependency_overrides': dependencyOverrides,
  'flutter_intl': <String, Object>{
    'enabled': true,
  },
  'flutter': <String, Object>{
    'uses-material-design': true,
    'assets': <Object>[
      r'assets/graphics/',
      r'assets/texts/',
    ],
    'fonts': <Object>[
      <String, Object>{
        'family': r'iconfont',
        'fonts': <Object>[
          <String, Object>{
            'asset': r'assets/fonts/iconfont.ttf',
          },
        ],
      },
    ],
  },
};
