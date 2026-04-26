param(
  [ValidateSet("debug", "release")]
  [string]$BuildMode = "release",
  [string]$Product = "default",
  [string]$FlutterSdkPath = $env:DANXI_OHOS_FLUTTER_ROOT,
  [switch]$EnableImpeller,
  [switch]$SkipHar,
  [switch]$SkipFlutterSdkUpdate
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$harmonyRoot = Join-Path $repoRoot "Harmony"
$harBuilder = Join-Path $repoRoot "build_har_from_override.ps1"

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

function Resolve-Hvigor {
  $cmd = Get-Command hvigorw -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $candidates = @(
    (Join-Path $env:LOCALAPPDATA "Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat"),
    "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat",
    (Join-Path $env:DEVECO_HOME "tools\hvigor\bin\hvigorw.bat")
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { return $c }
  }

  throw "hvigorw not found. Install DevEco Studio command line tools, add hvigorw to PATH, or set DEVECO_HOME."
}

if (-not (Test-Path $harmonyRoot)) {
  throw "Missing Harmony project: $harmonyRoot"
}

if (-not $SkipHar) {
  $harParams = @{
    BuildMode = $BuildMode
  }
  if ($FlutterSdkPath) {
    $harParams.FlutterSdkPath = $FlutterSdkPath
  }
  if ($SkipFlutterSdkUpdate) {
    $harParams.SkipFlutterSdkUpdate = $true
  }
  if ($EnableImpeller) {
    $harParams.EnableImpeller = $true
  }
  & $harBuilder @harParams
  if ($LASTEXITCODE -ne 0) {
    throw "HAR build failed. Exit code: $LASTEXITCODE."
  }
}

Push-Location $harmonyRoot
try {
  Invoke-Checked -FilePath "ohpm" -Arguments @("install") -FailureMessage "ohpm install failed."
  $hvigor = Resolve-Hvigor
  Invoke-Checked -FilePath $hvigor -Arguments @(
    "assembleHap",
    "-p",
    "product=$Product",
    "-p",
    "buildMode=$BuildMode",
    "--no-daemon"
  ) -FailureMessage "Harmony HAP build failed."
} finally {
  Pop-Location
}

$hapSource = Join-Path $harmonyRoot "entry\build\default\outputs\default\entry-default-signed.hap"
if (Test-Path $hapSource) {
  $harDir = Join-Path $repoRoot "har"
  New-Item -ItemType Directory -Path $harDir -Force | Out-Null
  $hapDestination = Join-Path $harDir "danxi_harmony_entry-default-signed.hap"
  Copy-Item -LiteralPath $hapSource -Destination $hapDestination -Force
  $hapHash = (Get-FileHash -Algorithm SHA256 -Path $hapDestination).Hash
  Write-Host "  HAP artifact: $hapDestination"
  Write-Host "  HAP sha256: $hapHash"
}

Write-Host "Harmony build succeeded:"
Write-Host "  HAR: $repoRoot\har"
Write-Host "  HAP: $harmonyRoot\entry\build"
