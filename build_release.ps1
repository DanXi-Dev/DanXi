param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("android", "android-armv8", "windows", "aab", "linux")]
  [string]$Target,

  [Parameter(Mandatory = $true)]
  [string]$VersionCode,

  [string]$FlutterPath = "flutter",
  [string]$DartPath = "dart",

  [switch]$NoEnforceLockfile
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$buildScript = Join-Path $repoRoot "build_release.dart"

if (-not (Test-Path $buildScript)) {
  throw "Missing build script: $buildScript"
}

function Invoke-Checked {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$FailureMessage
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FailureMessage Exit code: $LASTEXITCODE."
  }
}

Push-Location $repoRoot
try {
  $pubGetArgs = @("pub", "get")
  if (-not $NoEnforceLockfile) {
    $pubGetArgs += "--enforce-lockfile"
  }
  Invoke-Checked -FilePath $FlutterPath -Arguments $pubGetArgs -FailureMessage "flutter pub get failed."
  Invoke-Checked -FilePath $DartPath -Arguments @("run", "intl_utils:generate") -FailureMessage "dart run intl_utils:generate failed."

  Invoke-Checked -FilePath $DartPath -Arguments @("run", "build_release.dart", "--target", $Target, "--versionCode", $VersionCode, "--flutterPath", $FlutterPath, "--dartPath", $DartPath) -FailureMessage "Release build failed."
} finally {
  Pop-Location
}

Write-Host "Release build completed."