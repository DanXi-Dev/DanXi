// ignore_for_file: lines_longer_than_80_chars, unnecessary_raw_strings
// ignore_for_file: use_raw_strings, avoid_classes_with_only_static_members
// ignore_for_file: avoid_escaping_inner_quotes, prefer_single_quotes

/// GENERATED CODE - DO NOT MODIFY BY HAND

library pubspec;

// *****************************************************************************
// *                             pubspec_generator                             *
// *****************************************************************************

/*

  MIT License

  Copyright (c) 2024 Plague Fox

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

/// Given a version number MAJOR.MINOR.PATCH, increment the:
///
/// 1. MAJOR version when you make incompatible API changes
/// 2. MINOR version when you add functionality in a backward compatible manner
/// 3. PATCH version when you make backward compatible bug fixes
///
/// Additional labels for pre-release and build metadata are available
/// as extensions to the MAJOR.MINOR.PATCH format.
typedef PubspecVersion = ({
  String representation,
  String canonical,
  int major,
  int minor,
  int patch,
  List<String> preRelease,
  List<String> build
});

/// # The pubspec file
///
/// Code generated pubspec.yaml.g.dart from pubspec.yaml
/// This class is generated from pubspec.yaml, do not edit directly.
///
/// Every pub package needs some metadata so it can specify its dependencies.
/// Pub packages that are shared with others also need to provide some other
/// information so users can discover them. All of this metadata goes
/// in the package’s pubspec:
/// a file named pubspec.yaml that’s written in the YAML language.
///
/// Read more:
/// - https://pub.dev/packages/pubspec_generator
/// - https://dart.dev/tools/pub/pubspec
sealed class Pubspec {
  /// Version
  ///
  /// Current app [version]
  ///
  /// Every package has a version.
  /// A version number is required to host your package on the pub.dev site,
  /// but can be omitted for local-only packages.
  /// If you omit it, your package is implicitly versioned 0.0.0.
  ///
  /// Versioning is necessary for reusing code while letting it evolve quickly.
  /// A version number is three numbers separated by dots, like 0.2.43.
  /// It can also optionally have a build ( +1, +2, +hotfix.oopsie)
  /// or prerelease (-dev.4, -alpha.12, -beta.7, -rc.5) suffix.
  ///
  /// Each time you publish your package, you publish it at a specific version.
  /// Once that’s been done, consider it hermetically sealed:
  /// you can’t touch it anymore. To make more changes,
  /// you’ll need a new version.
  ///
  /// When you select a version,
  /// follow [semantic versioning](https://semver.org/).
  static const PubspecVersion version = (
    /// Non-canonical string representation of the version as provided
    /// in the pubspec.yaml file.
    representation: r'1.4.2+338',

    /// Returns a 'canonicalized' representation
  /// of the application version.
  /// This represents the version string in accordance with
  /// Semantic Versioning (SemVer) standards.
  canonical: r'1.4.2+338',

    /// MAJOR version when you make incompatible API changes.
    /// The major version number: 1 in "1.2.3".
    major: 1,

    /// MINOR version when you add functionality
  /// in a backward compatible manner.
  /// The minor version number: 2 in "1.2.3".
  minor: 4,

    /// PATCH version when you make backward compatible bug fixes.
    /// The patch version number: 3 in "1.2.3".
    patch: 2,

    /// The pre-release identifier: "foo" in "1.2.3-foo".
  preRelease: <String>[],

    /// The build identifier: "foo" in "1.2.3+foo".
    build: <String>[r'338'],
  );

  /// Build date and time (UTC)
  static final DateTime timestamp = DateTime.utc(
    2024,
    3,
    7,
    3,
    22,
    26,
    57,
    981,
  );

  /// Name
  ///
  /// Current app [name]
  ///
  /// Every package needs a name.
  /// It’s how other packages refer to yours, and how it appears to the world,
  /// should you publish it.
  ///
  /// The name should be all lowercase, with underscores to separate words,
  /// just_like_this. Use only basic Latin letters and Arabic digits:
  /// [a-z0-9_]. Also, make sure the name is a valid Dart identifier—that
  /// it doesn’t start with digits
  /// and isn’t a [reserved word](https://dart.dev/language/keywords).
  ///
  /// Try to pick a name that is clear, terse, and not already in use.
  /// A quick search of packages on the [pub.dev site](https://pub.dev/packages)
  /// to make sure that nothing else is using your name is recommended.
  static const String name = r'dan_xi';

  /// Description
  ///
  /// Current app [description]
  ///
  /// This is optional for your own personal packages,
  /// but if you intend to publish your package you must provide a description,
  /// which should be in English.
  /// The description should be relatively short, from 60 to 180 characters
  /// and tell a casual reader what they might want to know about your package.
  ///
  /// Think of the description as the sales pitch for your package.
  /// Users see it when they [browse for packages](https://pub.dev/packages).
  /// The description is plain text: no markdown or HTML.
  static const String description =
      r'Maybe the best all-rounded service app for Fudan University students.';

  /// Homepage
  ///
  /// Current app [homepage]
  ///
  /// This should be a URL pointing to the website for your package.
  /// For [hosted packages](https://dart.dev/tools/pub/dependencies#hosted-packages),
  /// this URL is linked from the package’s page.
  /// While providing a homepage is optional,
  /// please provide it or repository (or both).
  /// It helps users understand where your package is coming from.
  static const String homepage = r'';

  /// Repository
  ///
  /// Current app [repository]
  ///
  /// Repository
  /// The optional repository field should contain the URL for your package’s
  /// source code repository—for example,
  /// https://github.com/<user>/<repository>.
  /// If you publish your package to the pub.dev site,
  /// then your package’s page displays the repository URL.
  /// While providing a repository is optional,
  /// please provide it or homepage (or both).
  /// It helps users understand where your package is coming from.
  static const String repository = r'';

  /// Issue tracker
  ///
  /// Current app [issueTracker]
  ///
  /// The optional issue_tracker field should contain a URL for the package’s
  /// issue tracker, where existing bugs can be viewed and new bugs can be filed.
  /// The pub.dev site attempts to display a link
  /// to each package’s issue tracker, using the value of this field.
  /// If issue_tracker is missing but repository is present and points to GitHub,
  /// then the pub.dev site uses the default issue tracker
  /// (https://github.com/<user>/<repository>/issues).
  static const String issueTracker = r'';

  /// Documentation
  ///
  /// Current app [documentation]
  ///
  /// Some packages have a site that hosts documentation,
  /// separate from the main homepage and from the Pub-generated API reference.
  /// If your package has additional documentation, add a documentation:
  /// field with that URL; pub shows a link to this documentation
  /// on your package’s page.
  static const String documentation = r'';

  /// Publish_to
  ///
  /// Current app [publishTo]
  ///
  /// The default uses the [pub.dev](https://pub.dev/) site.
  /// Specify none to prevent a package from being published.
  /// This setting can be used to specify a custom pub package server to publish.
  ///
  /// ```yaml
  /// publish_to: none
  /// ```
  static const String publishTo = r'none';

  /// Funding
  ///
  /// Current app [funding]
  ///
  /// Package authors can use the funding property to specify
  /// a list of URLs that provide information on how users
  /// can help fund the development of the package. For example:
  ///
  /// ```yaml
  /// funding:
  ///  - https://www.buymeacoffee.com/example_user
  ///  - https://www.patreon.com/some-account
  /// ```
  ///
  /// If published to [pub.dev](https://pub.dev/) the links are displayed on the package page.
  /// This aims to help users fund the development of their dependencies.
  static const List<Object> funding = <Object>[];

  /// False_secrets
  ///
  /// Current app [falseSecrets]
  ///
  /// When you try to publish a package,
  /// pub conducts a search for potential leaks of secret credentials,
  /// API keys, or cryptographic keys.
  /// If pub detects a potential leak in a file that would be published,
  /// then pub warns you and refuses to publish the package.
  ///
  /// Leak detection isn’t perfect. To avoid false positives,
  /// you can tell pub not to search for leaks in certain files,
  /// by creating an allowlist using gitignore
  /// patterns under false_secrets in the pubspec.
  ///
  /// For example, the following entry causes pub not to look
  /// for leaks in the file lib/src/hardcoded_api_key.dart
  /// and in all .pem files in the test/localhost_certificates/ directory:
  ///
  /// ```yaml
  /// false_secrets:
  ///  - /lib/src/hardcoded_api_key.dart
  ///  - /test/localhost_certificates/*.pem
  /// ```
  ///
  /// Starting a gitignore pattern with slash (/) ensures
  /// that the pattern is considered relative to the package’s root directory.
  static const List<Object> falseSecrets = <Object>[];

  /// Screenshots
  ///
  /// Current app [screenshots]
  ///
  /// Packages can showcase their widgets or other visual elements
  /// using screenshots displayed on their pub.dev page.
  /// To specify screenshots for the package to display,
  /// use the screenshots field.
  ///
  /// A package can list up to 10 screenshots under the screenshots field.
  /// Don’t include logos or other branding imagery in this section.
  /// Each screenshot includes one description and one path.
  /// The description explains what the screenshot depicts
  /// in no more than 160 characters. For example:
  ///
  /// ```yaml
  /// screenshots:
  ///   - description: 'This screenshot shows the transformation of a number of bytes
  ///   to a human-readable expression.'
  ///     path: path/to/image/in/package/500x500.webp
  ///   - description: 'This screenshot shows a stack trace returning a human-readable
  ///   representation.'
  ///     path: path/to/image/in/package.png
  /// ```
  ///
  /// Pub.dev limits screenshots to the following specifications:
  ///
  /// - File size: max 4 MB per image.
  /// - File types: png, jpg, gif, or webp.
  /// - Static and animated images are both allowed.
  ///
  /// Keep screenshot files small. Each download of the package
  /// includes all screenshot files.
  ///
  /// Pub.dev generates the package’s thumbnail image from the first screenshot.
  /// If this screenshot uses animation, pub.dev uses its first frame.
  static const List<Object> screenshots = <Object>[];

  /// Topics
  ///
  /// Current app [topics]
  ///
  /// Package authors can use the topics field to categorize their package. Topics can be used to assist discoverability during search with filters on pub.dev. Pub.dev displays the topics on the package page as well as in the search results.
  ///
  /// The field consists of a list of names. For example:
  ///
  /// ```yaml
  /// topics:
  ///   - network
  ///   - http
  /// ```
  ///
  /// Pub.dev requires topics to follow these specifications:
  ///
  /// - Tag each package with at most 5 topics.
  /// - Write the topic name following these requirements:
  ///   1) Use between 2 and 32 characters.
  ///   2) Use only lowercase alphanumeric characters or hyphens (a-z, 0-9, -).
  ///   3) Don’t use two consecutive hyphens (--).
  ///   4) Start the name with lowercase alphabet characters (a-z).
  ///   5) End with alphanumeric characters (a-z or 0-9).
  ///
  /// When choosing topics, consider if existing topics are relevant.
  /// Tagging with existing topics helps users discover your package.
  static const List<Object> topics = <Object>[];

  /// Environment
  static const Map<String, String> environment = <String, String>{
    'sdk': '>=3.0.0',
  };

  /// Platforms
  ///
  /// Current app [platforms]
  ///
  /// When you [publish a package](https://dart.dev/tools/pub/publishing),
  /// pub.dev automatically detects the platforms that the package supports.
  /// If this platform-support list is incorrect,
  /// use platforms to explicitly declare which platforms your package supports.
  ///
  /// For example, the following platforms entry causes
  /// pub.dev to list the package as supporting
  /// Android, iOS, Linux, macOS, Web, and Windows:
  ///
  /// ```yaml
  /// # This package supports all platforms listed below.
  /// platforms:
  ///   android:
  ///   ios:
  ///   linux:
  ///   macos:
  ///   web:
  ///   windows:
  /// ```
  ///
  /// Here is an example of declaring that the package supports only Linux and macOS (and not, for example, Windows):
  ///
  /// ```yaml
  /// # This package supports only Linux and macOS.
  /// platforms:
  ///   linux:
  ///   macos:
  /// ```
  static const Map<String, Object> platforms = <String, Object>{};

  /// Dependencies
  ///
  /// Current app [dependencies]
  ///
  /// [Dependencies](https://dart.dev/tools/pub/glossary#dependency)
  /// are the pubspec’s `raison d’être`.
  /// In this section you list each package that
  /// your package needs in order to work.
  ///
  /// Dependencies fall into one of two types.
  /// Regular dependencies are listed under dependencies:
  /// these are packages that anyone using your package will also need.
  /// Dependencies that are only needed in
  /// the development phase of the package itself
  /// are listed under dev_dependencies.
  ///
  /// During the development process,
  /// you might need to temporarily override a dependency.
  /// You can do so using dependency_overrides.
  ///
  /// For more information,
  /// see [Package dependencies](https://dart.dev/tools/pub/dependencies).
  static const Map<String, Object> dependencies = <String, Object>{
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
    'share_plus': r'^7.0.2',
    'path_provider': r'^2.0.9',
    'screen_brightness': r'^1.0.0',
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
    'http': r'^1.0.0',
    'dio': r'^4.0.6',
    'shared_preferences': r'^2.0.15',
    'flutter_phoenix': r'^1.0.0',
    'asn1lib': r'^1.1.0',
    'image_picker': r'^1.0.0',
    'clipboard': r'^0.1.3',
    'flutter_inappwebview': r'^6.0.0',
    'permission_handler': r'^11.0.1',
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
    'gal': r'^2.1.2',
    'flutter_markdown': <String, Object>{
      'git': <String, Object>{
        'url':
            r'https://github.com/singularity-s0/flutter_markdown_selectable.git',
      },
    },
    'markdown': r'^6.0.0',
    'tray_manager': r'^0.2.1',
    'bitsdojo_window': r'^0.1.6',
    'win32': r'^5.0.2',
    'file_picker': r'^6.0.0',
    'cached_network_image': r'^3.2.1',
    'flutter_typeahead': r'^4.8.0',
    'collection': r'>=1.15.0 <2.0.0',
    'meta': r'>=1.3.0 <2.0.0',
    'flutter_layout_grid': r'^2.0.1',
    'flutter_js': r'^0.8.0',
    'flutter_math_fork': r'^0.7.2',
    'platform_device_id': r'^1.0.1',
    'uuid': r'^4.3.3',
    'screen_capture_event': r'^1.0.0+1',
    'otp': r'^3.0.2',
    'lunar': r'^1.2.20',
    'flutter_fgbg': r'^0.3.0',
    'lazy_load_indexed_stack': r'^1.0.0',
    'js': r'^0.6.7',
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
    'git_info': r'^1.1.2',
  };

  /// Developer dependencies
  static const Map<String, Object> devDependencies = <String, Object>{
    'build_runner': r'^2.1.2',
    'pubspec_generator': r'^4.0.0',
    'flutter_test': <String, Object>{
      'sdk': r'flutter',
    },
    'flutter_lints': r'^3.0.0',
    'intl_utils': r'^2.8.5',
  };

  /// Dependency overrides
  static const Map<String, Object> dependencyOverrides = <String, Object>{
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
    'flutter_platform_widgets': r'^6.0.2',
  };

  /// Executables
  ///
  /// Current app [executables]
  ///
  /// A package may expose one or more of its scripts as executables
  /// that can be run directly from the command line.
  /// To make a script publicly available,
  /// list it under the executables field.
  /// Entries are listed as key/value pairs:
  ///
  /// ```yaml
  /// <name-of-executable>: <Dart-script-from-bin>
  /// ```
  ///
  /// For example, the following pubspec entry lists two scripts:
  ///
  /// ```yaml
  /// executables:
  ///   slidy: main
  ///   fvm:
  /// ```
  ///
  /// Once the package is activated using pub global activate,
  /// typing `slidy` executes `bin/main.dart`.
  /// Typing `fvm` executes `bin/fvm.dart`.
  /// If you don’t specify the value, it is inferred from the key.
  ///
  /// For more information, see pub global.
  static const Map<String, Object> executables = <String, Object>{};

  /// Source data from pubspec.yaml
  static const Map<String, Object> source = <String, Object>{
    'name': name,
    'description': description,
    'repository': repository,
    'issue_tracker': issueTracker,
    'homepage': homepage,
    'documentation': documentation,
    'publish_to': publishTo,
    'version': version,
    'funding': funding,
    'false_secrets': falseSecrets,
    'screenshots': screenshots,
    'topics': topics,
    'platforms': platforms,
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
        r'.git/',
        r'.git/refs/heads/',
        r'.git/refs/heads/main',
        r'.git/refs/heads/foss-build',
      ],
      'fonts': <Object>[
        r'{family: iconfont, fonts: [{asset: assets/fonts/iconfont.ttf}]}',
      ],
    },
  };
}