param(
  [ValidateSet("debug", "release")]
  [string]$BuildMode = "debug",
  [string]$FlutterSdkPath = $env:DANXI_OHOS_FLUTTER_ROOT,
  [switch]$EnableImpeller,
  [switch]$SkipFlutterSdkUpdate
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$overrideOhosPath = Join-Path $repoRoot "pubspec_overrides.ohos.yaml"
$rootPubspecPath = Join-Path $repoRoot "pubspec.yaml"
$activeOverridePath = Join-Path $repoRoot "pubspec_overrides.yaml"
$ohosBuildProfileCandidates = @(
  (Join-Path $repoRoot ".ohos\build-profile.json5")
)
$ohosPackageCandidates = @(
  (Join-Path $repoRoot ".ohos\oh-package.json5")
)
$harOutputDir = Join-Path $repoRoot "har"
$pluginHarDir = Join-Path $harOutputDir "plugins"
$engineHarDst = Join-Path $harOutputDir "danxi_flutter.har"
$moduleHarDst = Join-Path $harOutputDir "danxi_flutter_module.har"

$fileBackups = @{}
$createdFiles = New-Object System.Collections.Generic.List[string]

function Backup-File {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }
  $full = [System.IO.Path]::GetFullPath($Path)
  if (-not $fileBackups.ContainsKey($full)) {
    $fileBackups[$full] = Get-Content -Raw -Path $full
  }
}

function Write-File {
  param(
    [string]$Path,
    [string]$Content
  )
  if (-not (Test-Path $Path)) {
    $createdFiles.Add([System.IO.Path]::GetFullPath($Path))
  } else {
    Backup-File $Path
  }
  Set-Content -Path $Path -Value $Content -NoNewline -Encoding utf8
}

function Set-DefaultEnv {
  if (-not $env:FLUTTER_STORAGE_BASE_URL) {
    $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
  }
  if (-not $env:FLUTTER_OHOS_STORAGE_BASE_URL) {
    $env:FLUTTER_OHOS_STORAGE_BASE_URL = "https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com"
  }
  if (-not $env:PUB_HOSTED_URL) {
    $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
  }
}

function Invoke-Checked {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$FailureMessage,
    [switch]$AllowNonZeroExit
  )

  & $FilePath @Arguments
  $exitCode = $LASTEXITCODE
  if (-not $AllowNonZeroExit -and $exitCode -ne 0) {
    throw "$FailureMessage Exit code: $exitCode."
  }
  return $exitCode
}

function Resolve-FlutterSdkRoot {
  param([string]$ConfiguredPath)

  if ($ConfiguredPath) {
    $candidate = [System.IO.Path]::GetFullPath($ConfiguredPath)
    $flutterExe = Join-Path $candidate "bin\flutter.bat"
    if (-not (Test-Path $flutterExe)) {
      throw "Flutter OHOS SDK not found under $candidate. Expected $flutterExe."
    }
    return $candidate
  }

  $flutterCmd = Get-Command flutter -ErrorAction Stop
  $flutterBinDir = Split-Path -Parent $flutterCmd.Source
  return (Split-Path -Parent $flutterBinDir)
}

function Resolve-HarFileFromSdk {
  param(
    [string]$SdkRoot,
    [string]$HarName
  )

  return Get-ChildItem -Path $SdkRoot -Filter $HarName -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
}

function Resolve-FirstExistingPath {
  param([string[]]$Candidates)

  foreach ($candidate in $Candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return [System.IO.Path]::GetFullPath($candidate)
    }
  }

  return $null
}

function Sync-VendorPluginRuntimeHars {
  param(
    [string]$RepoRoot,
    [string]$FlutterHarSource
  )

  if (-not $FlutterHarSource) { return }

  $vendorOhosPackages = Get-ChildItem -Path (Join-Path $RepoRoot ".vendor_ohos") -Filter "oh-package.json5" -File -Recurse -ErrorAction SilentlyContinue
  foreach ($packageFile in $vendorOhosPackages) {
    $content = Get-Content -Raw $packageFile.FullName
    if ($content -notmatch 'file:libs/flutter\.har') { continue }

    $libsDir = Join-Path $packageFile.Directory.FullName "libs"
    New-Item -ItemType Directory -Path $libsDir -Force | Out-Null
    Copy-Item -LiteralPath $FlutterHarSource -Destination (Join-Path $libsDir "flutter.har") -Force
  }
}

function Repack-ModuleHarAssets {
  param(
    [string]$ModuleHarPath,
    [string]$RepoRoot,
    [bool]$EnableImpeller = $false
  )

  $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("danxi-ohos-har-" + [System.Guid]::NewGuid().ToString("N"))
  $tempArchive = "$ModuleHarPath.tmp"
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

  try {
    tar -xf $ModuleHarPath -C $tempDir
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to extract module HAR for repacking."
    }

    $flutterAssetsRoot = Join-Path $tempDir "package\src\main\resources\rawfile\flutter_assets"
    if (-not (Test-Path $flutterAssetsRoot)) {
      throw "Expected flutter assets directory missing in module HAR: $flutterAssetsRoot"
    }

    $targetAssetsDir = Join-Path $flutterAssetsRoot "assets"
    $rawfileRoot = Join-Path $tempDir "package\src\main\resources\rawfile"
    New-Item -ItemType Directory -Path $targetAssetsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $rawfileRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot "assets\*") -Destination $targetAssetsDir -Recurse -Force

    $buildInfo = @{
      string = @(
        @{
          name = "enable_impeller"
          value = $EnableImpeller.ToString().ToLowerInvariant()
        }
      )
    } | ConvertTo-Json -Depth 4
    Set-Content -Path (Join-Path $rawfileRoot "buildinfo.json5") -Value $buildInfo -Encoding utf8

    $framesTemplate = Join-Path $flutterRoot "packages\flutter_tools\templates\app\ohos.tmpl\entry\src\main\resources\base\profile\framesconfig.json"
    if (Test-Path $framesTemplate) {
      Copy-Item -LiteralPath $framesTemplate -Destination (Join-Path $rawfileRoot "framesconfig.json") -Force
    }

    if (Test-Path $tempArchive) {
      Remove-Item -LiteralPath $tempArchive -Force
    }
    tar -czf $tempArchive -C $tempDir package
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to repack module HAR."
    }
    Move-Item -LiteralPath $tempArchive -Destination $ModuleHarPath -Force
  }
  finally {
    if (Test-Path $tempDir) {
      Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
    if (Test-Path $tempArchive) {
      Remove-Item -LiteralPath $tempArchive -Force
    }
  }
}

Set-DefaultEnv

$flutterRoot = Resolve-FlutterSdkRoot -ConfiguredPath $FlutterSdkPath
$flutterExe = Join-Path $flutterRoot "bin\flutter.bat"
$dartExe = Join-Path $flutterRoot "bin\dart.bat"

Push-Location $repoRoot
try {
  if (-not (Test-Path $overrideOhosPath)) { throw "Missing file: $overrideOhosPath" }
  if (-not (Test-Path $rootPubspecPath)) { throw "Missing file: $rootPubspecPath" }

  $sdkVersion = & $flutterExe --version 2>&1 | Select-String "Flutter\s+(\S+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
  if (-not $sdkVersion -or -not ($sdkVersion -match "^3\.35\.")) {
    throw "Flutter OHOS SDK version mismatch. Expected 3.35.x, got '$sdkVersion'. Set DANXI_OHOS_FLUTTER_ROOT to the correct SDK checkout or add it to PATH."
  }
  Write-Host "Flutter OHOS SDK: $sdkVersion" -ForegroundColor Green

  $sdkFlutterHar = Resolve-HarFileFromSdk -SdkRoot $flutterRoot -HarName "flutter.har"
  Sync-VendorPluginRuntimeHars -RepoRoot $repoRoot -FlutterHarSource $sdkFlutterHar

  $pubspec = Get-Content -Raw $rootPubspecPath
  Backup-File $rootPubspecPath

  if ($pubspec -match 'sdk:\s*"[^"]+"') {
    $pubspec = [regex]::Replace($pubspec, 'sdk:\s*"[^"]+"', 'sdk: ">=3.8.0 <4.0.0"', 1)
  }

  $pubspec = [regex]::Replace($pubspec, '(?m)^\s*pubspec_generator:\s*.*\r?\n', '')
  $pubspec = [regex]::Replace($pubspec, '(?ms)^\s*flutter_test:\s*\r?\n\s*sdk:\s*flutter\s*\r?\n', '')
  $pubspec = [regex]::Replace($pubspec, '(?m)^\s*flutter_lints:\s*.*\r?\n', '')
  $pubspec = [regex]::Replace($pubspec, '(?m)^\s*custom_lint:\s*.*\r?\n', '')
  $pubspec = [regex]::Replace($pubspec, '(?m)^\s*riverpod_lint:\s*.*\r?\n', '')
  if ($pubspec -notmatch '(?m)^\s+module:\s*$') {
    $pubspec = [regex]::Replace(
      $pubspec,
      '(?m)^flutter:\s*$',
      "flutter:`r`n  module:`r`n    androidPackage: io.github.danxi`r`n    iosBundleIdentifier: io.github.danxi",
      1
    )
  }
  Write-File -Path $rootPubspecPath -Content $pubspec

  $overrideContent = Get-Content -Raw $overrideOhosPath
  $overrideContent = [regex]::Replace(
    $overrideContent,
    '(?m)^(\s*path:\s*)\.\./(\.vendor_ohos/.*)$',
    '$1./$2'
  )
  Write-File -Path $activeOverridePath -Content $overrideContent

  $ohosBuildProfilePath = $ohosBuildProfileCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($ohosBuildProfilePath) {
    $profile = Get-Content -Raw $ohosBuildProfilePath
    if ($profile -notmatch '"name"\s*:\s*"flutter_module"') {
      Backup-File $ohosBuildProfilePath
      $flutterModuleItem = @"
,
    {
      "name": "flutter_module",
      "srcPath": "../.ohos/flutter_module",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    }
"@
      $profile = [regex]::Replace(
        $profile,
        '(?s)("modules"\s*:\s*\[)(.*?)(\n\s*\]\s*\n\})',
        { param($m) $m.Groups[1].Value + $m.Groups[2].Value + $flutterModuleItem + $m.Groups[3].Value },
        1
      )
      Write-File -Path $ohosBuildProfilePath -Content $profile
    }
  }

  try {
    Invoke-Checked -FilePath $flutterExe -Arguments @("pub", "get") -FailureMessage "flutter pub get failed."
  } catch {
    Write-Host "flutter pub get failed, retrying with --offline using the local cache." -ForegroundColor Yellow
    Invoke-Checked -FilePath $flutterExe -Arguments @("pub", "get", "--offline") -FailureMessage "flutter pub get --offline failed."
  }
  Invoke-Checked -FilePath $flutterExe -Arguments @("pub", "global", "activate", "intl_utils") -FailureMessage "flutter pub global activate intl_utils failed."
  Invoke-Checked -FilePath $dartExe -Arguments @("run", "intl_utils:generate") -FailureMessage "intl_utils code generation failed."
  Invoke-Checked -FilePath $dartExe -Arguments @("run", "build_runner", "build", "--delete-conflicting-outputs") -FailureMessage "build_runner code generation failed."

  $ohosPackagePath = $ohosPackageCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  $ohosLocalPropertiesPath = Join-Path $repoRoot ".ohos\local.properties"
  $arm64ArtifactDir = if ($BuildMode -eq "debug") { "ohos-arm64" } else { "ohos-arm64-$BuildMode" }
  $x64ArtifactDir = if ($BuildMode -eq "debug") { "ohos-x64" } else { "ohos-x64-$BuildMode" }
  $arm64NativeHar = Join-Path $flutterRoot "bin\cache\artifacts\engine\$arm64ArtifactDir\arm64_v8a_${BuildMode}.har"
  $x64NativeHar = Join-Path $flutterRoot "bin\cache\artifacts\engine\$x64ArtifactDir\x86_64_${BuildMode}.har"
  if (-not (Test-Path $arm64NativeHar)) { throw "Missing native runtime HAR: $arm64NativeHar" }
  if (-not (Test-Path $x64NativeHar)) { throw "Missing native runtime HAR: $x64NativeHar" }

  $devEcoHome = Resolve-FirstExistingPath -Candidates @(
    $env:DEVECO_HOME,
    "C:\Program Files\Huawei\DevEco Studio"
  )
  $openharmonyCandidates = @($env:DEVECO_SDK_HOME, "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony")
  if ($devEcoHome) {
    $openharmonyCandidates = @((Join-Path $devEcoHome "sdk\default\openharmony")) + $openharmonyCandidates
  }
  $openharmonySdkDir = Resolve-FirstExistingPath -Candidates $openharmonyCandidates
  $nodeJsCandidates = @("C:\Program Files\Huawei\DevEco Studio\tools\node")
  if ($devEcoHome) {
    $nodeJsCandidates = @((Join-Path $devEcoHome "tools\node")) + $nodeJsCandidates
  }
  $nodeJsDir = Resolve-FirstExistingPath -Candidates $nodeJsCandidates
  if (-not $openharmonySdkDir) {
    throw "OpenHarmony SDK directory not found. Set DEVECO_SDK_HOME or install DevEco Studio SDK."
  }
  $localProperties = @(
    "sdk.dir=$($openharmonySdkDir -replace '\\','/')"
    "flutter.sdk=$($flutterRoot -replace '\\','/')"
  )
  if ($nodeJsDir) {
    $localProperties += "nodejs.dir=$($nodeJsDir -replace '\\','/')"
  }
  Write-File -Path $ohosLocalPropertiesPath -Content ($localProperties -join "`r`n")

  if ($ohosPackagePath) {
    $ohosPackage = Get-Content -Raw $ohosPackagePath
    $patchedPackage = $ohosPackage
    if ($patchedPackage -notmatch '"overrides"\s*:\s*\{') {
      $patchedPackage = [regex]::Replace(
        $patchedPackage,
        '(?s)\}\s*$',
        ",`r`n  `"overrides`": {`r`n  }`r`n}"
      )
    }
    if ($patchedPackage -notmatch '"flutter_native_arm64_v8a"\s*:') {
      $patchedPackage = [regex]::Replace(
        $patchedPackage,
        '(?s)("overrides"\s*:\s*\{)',
        "`$1`r`n    `"flutter_native_arm64_v8a`": `"file:$($arm64NativeHar -replace '\\','/')`",`r`n    `"flutter_native_x86_64`": `"file:$($x64NativeHar -replace '\\','/')`","
      )
    }
    if ($patchedPackage -ne $ohosPackage) {
      Write-File -Path $ohosPackagePath -Content $patchedPackage
    }
  }

  $flutterBuildArgs = @("build", "har", "--$BuildMode")
  if ($EnableImpeller) {
    $flutterBuildArgs += "--enable-impeller"
  }
  $flutterBuildExit = Invoke-Checked -FilePath $flutterExe -Arguments $flutterBuildArgs -FailureMessage "flutter build har failed." -AllowNonZeroExit

  $harSearchRoots = @(
    (Join-Path $repoRoot ".ohos")
  ) | Where-Object { Test-Path $_ }

  $engineHarSrc = $null
  $moduleHarSrc = $null
  foreach ($root in $harSearchRoots) {
    if (-not $engineHarSrc) {
      $engineHarSrc = Get-ChildItem -Path $root -Filter "flutter.har" -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $moduleHarSrc) {
      $moduleHarSrc = Get-ChildItem -Path $root -Filter "flutter_module.har" -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    }
  }

  if (-not $moduleHarSrc) {
    throw "flutter build har exited with code $flutterBuildExit and module HAR not found under .ohos."
  }

  if ($flutterBuildExit -ne 0) {
    Write-Host "flutter build har exited with code $flutterBuildExit, but module HAR was generated. Continuing." -ForegroundColor Yellow
  }

  if (-not $engineHarSrc) {
    $engineHarSrc = $sdkFlutterHar
  }
  if (-not $engineHarSrc) {
    Write-Host "flutter.har not found under .ohos or the OHOS Flutter SDK. Harmony host build may fail without it." -ForegroundColor Yellow
  }

  New-Item -ItemType Directory -Path $harOutputDir -Force | Out-Null
  New-Item -ItemType Directory -Path $pluginHarDir -Force | Out-Null
  if ($engineHarSrc) {
    Copy-Item -LiteralPath $engineHarSrc -Destination $engineHarDst -Force
  }
  Copy-Item -LiteralPath $moduleHarSrc -Destination $moduleHarDst -Force
  Repack-ModuleHarAssets -ModuleHarPath $moduleHarDst -RepoRoot $repoRoot -EnableImpeller:$EnableImpeller
  Copy-Item -LiteralPath $arm64NativeHar -Destination (Join-Path $pluginHarDir "flutter_native_arm64_v8a.har") -Force
  Copy-Item -LiteralPath $x64NativeHar -Destination (Join-Path $pluginHarDir "flutter_native_x86_64.har") -Force

  $pluginHarFiles = $harSearchRoots | ForEach-Object {
      Get-ChildItem -Path $_ -Filter "*.har" -File -Recurse -ErrorAction SilentlyContinue
    } |
    Where-Object {
      $_.FullName -ne $engineHarSrc -and
      $_.FullName -ne $moduleHarSrc -and
      $_.FullName -ne $arm64NativeHar -and
      $_.FullName -ne $x64NativeHar
    } |
    Sort-Object Name -Unique

  foreach ($pluginHar in $pluginHarFiles) {
    Copy-Item -LiteralPath $pluginHar.FullName -Destination (Join-Path $pluginHarDir $pluginHar.Name) -Force
  }

  Write-Host "HAR build succeeded:"
  if ($engineHarSrc) {
    Write-Host "  $engineHarDst"
  }
  Write-Host "  $moduleHarDst"
}
finally {
  foreach ($fullPath in $fileBackups.Keys) {
    Set-Content -Path $fullPath -Value $fileBackups[$fullPath] -NoNewline -Encoding utf8
  }

  foreach ($created in $createdFiles) {
    if (Test-Path $created) {
      Remove-Item -LiteralPath $created -Force
    }
  }

  Pop-Location
}
