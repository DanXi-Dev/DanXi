param(
  [string]$BundleName = "com.example.danxi",
  [string]$AbilityName = "EntryAbility",
  [string]$HapPath = (Join-Path $PSScriptRoot "Harmony\entry\build\default\outputs\default\entry-default-signed.hap"),
  [switch]$InstallOnly,
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

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

if (-not $SkipInstall) {
  if (-not (Test-Path $HapPath)) {
    throw "HAP not found: $HapPath"
  }
  Invoke-Checked -FilePath "hdc" -Arguments @("install", "-r", $HapPath) -FailureMessage "HAP install failed."
}

if ($InstallOnly) {
  Write-Host "HAP installed successfully:"
  Write-Host "  $HapPath"
  exit 0
}

& "hdc" "shell" "aa" "force-stop" $BundleName | Out-Null
Invoke-Checked -FilePath "hdc" -Arguments @("shell", "aa", "start", "-a", $AbilityName, "-b", $BundleName) -FailureMessage "App launch failed."

Write-Host "Harmony app launched:"
Write-Host "  Bundle: $BundleName"
Write-Host "  Ability: $AbilityName"
