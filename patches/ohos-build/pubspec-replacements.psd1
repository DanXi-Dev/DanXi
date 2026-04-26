@{
  Replacements = @(
    @{
      Type = "regex"
      Pattern = 'sdk:\s*"[^"]+"'
      Replacement = 'sdk: ">=3.8.0 <4.0.0"'
      Count = 1
    }
    @{
      Type = "regex"
      Pattern = '(?m)^\s*pubspec_generator:\s*.*\r?\n'
      Replacement = ''
    }
    @{
      Type = "regex"
      Pattern = '(?ms)^\s*flutter_test:\s*\r?\n\s*sdk:\s*flutter\s*\r?\n'
      Replacement = ''
    }
    @{
      Type = "regex"
      Pattern = '(?m)^\s*flutter_lints:\s*.*\r?\n'
      Replacement = ''
    }
    @{
      Type = "regex"
      Pattern = '(?m)^\s*custom_lint:\s*.*\r?\n'
      Replacement = ''
    }
    @{
      Type = "regex"
      Pattern = '(?m)^\s*riverpod_lint:\s*.*\r?\n'
      Replacement = ''
    }
    @{
      Type = "regex"
      Pattern = '(?m)^flutter:\s*$'
      Replacement = "flutter:`r`n  module:`r`n    androidPackage: io.github.danxi`r`n    iosBundleIdentifier: io.github.danxi"
      Count = 1
      WhenMissing = '(?m)^\s+module:\s*$'
    }
  )
}
