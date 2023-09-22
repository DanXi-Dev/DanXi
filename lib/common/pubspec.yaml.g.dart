/// GENERATED CODE - DO NOT MODIFY BY HAND

/// ***************************************************************************
/// *                            pubspec_generator                            * 
/// ***************************************************************************

/*
  
  MIT License
  
  Copyright (c) 2023 Plague Fox
  
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
const String version = r'1.4.0+336';

/// The major version number: "1" in "1.2.3".
const int major = 1;

/// The minor version number: "2" in "1.2.3".
const int minor = 4;

/// The patch version number: "3" in "1.2.3".
const int patch = 0;

/// The pre-release identifier: "foo" in "1.2.3-foo".
const List<String> pre = <String>[];

/// The build identifier: "foo" in "1.2.3+foo".
const List<String> build = <String>[r'336'];

/// Build date in Unix Time (in seconds)
const int timestamp = 1695386740;

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
  'sdk': '>=3.0.0',
};

/// Dependencies
const Map<String, Object> dependencies = <String, Object>{
  'flutter': <String, Object>{
    'sdk': r'flutter',
  },
  'flutter_localizations': <String, Object>{
    'sdk': r'flutter',
  },
  'cupertino_icons': r'^1.0.5',
  'dio_cookie_manager': r'^2.0.0',
  'flutter_progress_dialog': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/Boreas618/flutter_progress_dialog.git',
      'ref': r'master',
    },
  },
  'xiao_mi_push_plugin': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/w568w/FlutterXiaoMiPushPlugin.git',
      'ref': r'master',
    },
  },
  'beautiful_soup_dart': r'^0.3.0',
  'quick_actions': r'^1.0.1',
  'qr_flutter': r'^4.0.0',
  'provider': r'^6.0.5',
  'event_bus': r'^2.0.0',
  'flutter_platform_widgets': r'^3.0.0',
  'share_plus': r'^7.0.2',
  'path_provider': r'^2.0.9',
  'screen_brightness': r'^0.2.1',
  'flutter_email_sender': r'^6.0.1',
  'auto_size_text': r'^3.0.0',
  'ical': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/dartclub/ical.git',
      'ref': r'main',
    },
  },
  'url_launcher': r'^6.1.12',
  'uni_links': r'^0.5.1',
  'desktop_window': r'^0.4.0',
  'http': r'^0.13.4',
  'dio': r'^4.0.6',
  'shared_preferences': r'^2.0.15',
  'flutter_phoenix': r'^1.0.0',
  'asn1lib': r'^1.1.0',
  'image_picker': r'^1.0.0',
  'clipboard': r'^0.1.3',
  'flutter_inappwebview': r'^5.3.2',
  'permission_handler': r'^10.2.0',
  'in_app_review': r'^2.0.4',
  'flutter_linkify': r'^6.0.0',
  'linkify': r'^4.0.0',
  'open_file': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/crazecoder/open_file.git',
    },
  },
  'dio_log': r'^2.0.2',
  'json_serializable': r'^6.2.0',
  'photo_view': r'^0.14.0',
  'gallery_saver': r'^2.3.2',
  'flutter_markdown': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/singularity-s0/flutter_markdown_selectable.git',
    },
  },
  'markdown': r'^6.0.0',
  'system_tray': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/antler119/system_tray.git',
      'ref': r'main',
    },
  },
  'bitsdojo_window': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/DartGit-dev/bitsdojo_window.git',
      'path': r'bitsdojo_window',
      'ref': r'master',
    },
  },
  'win32': r'^5.0.2',
  'file_picker': r'^5.3.2',
  'cached_network_image': r'^3.2.1',
  'flutter_typeahead': r'^4.3.3',
  'collection': r'>=1.15.0 <2.0.0',
  'meta': r'>=1.3.0 <2.0.0',
  'flutter_layout_grid': r'^2.0.1',
  'flutter_js': r'^0.7.0',
  'flutter_math_fork': r'^0.7.1',
  'platform_device_id': r'^1.0.1',
  'uuid': r'^3.0.6',
  'screen_capture_event': r'^1.0.0+1',
  'otp': r'^3.0.2',
  'lunar': r'^1.2.20',
  'flutter_fgbg': r'^0.3.0',
  'lazy_load_indexed_stack': r'^1.0.0',
  'js': r'^0.6.5',
  'nil': r'^1.1.1',
  'flex_color_picker': r'^3.2.0',
  'material_color_generator': r'^1.1.0',
  'flutter_swiper_view': r'^1.1.8',
  'mutex': r'^3.0.1',
  'device_info_plus': r'^9.0.2',
  'receive_intent': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/w568w/receive_intent.git',
    },
  },
  'flutter_secure_storage': r'^8.0.0',
  'encrypt_shared_preferences': r'^0.3.5',
  'device_identity': r'^1.0.0',
  'tutorial_coach_mark': r'^1.2.9',
};

/// Developer dependencies
const Map<String, Object> devDependencies = <String, Object>{
  'build_runner': r'^2.1.2',
  'pubspec_generator': r'^3.0.1',
  'flutter_test': <String, Object>{
    'sdk': r'flutter',
  },
  'flutter_lints': r'^2.0.1',
  'intl_utils': r'^2.8.3',
};

/// Dependency overrides
const Map<String, Object> dependencyOverrides = <String, Object>{
  'intl': r'^0.18.1',
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
  'bitsdojo_window_platform_interface': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/DartGit-dev/bitsdojo_window.git',
      'path': r'bitsdojo_window_platform_interface',
      'ref': r'master',
    },
  },
  'bitsdojo_window_windows': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/DartGit-dev/bitsdojo_window.git',
      'path': r'bitsdojo_window_windows',
      'ref': r'master',
    },
  },
  'bitsdojo_window_macos': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/DartGit-dev/bitsdojo_window.git',
      'path': r'bitsdojo_window_macos',
      'ref': r'master',
    },
  },
  'bitsdojo_window_linux': <String, Object>{
    'git': <String, Object>{
      'url': r'https://github.com/DartGit-dev/bitsdojo_window.git',
      'path': r'bitsdojo_window_linux',
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
