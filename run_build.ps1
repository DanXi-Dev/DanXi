param(
    [string]$target,
    [string]$version_code
)

if (-not $version_code) {
    $version_code = Read-Host -Prompt "Input your version name to continue"
}

Write-Output "Start building..."

$GIT_HASH = git rev-parse --short HEAD

Write-Output "Executing build runner..."
Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/C dart run build_runner build --delete-conflicting-outputs"

switch ($target) {
    "android" {
        & {
            Write-Output "Build for Android..."
            Write-Output ""
            Write-Output "Clean old files..."
            Remove-Item -Force -Path "build\app\DanXi-$version_code-release.android.apk"
            Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/C flutter build apk --release --dart-define=GIT_HASH=$GIT_HASH"
            Write-Output "Copy file..."
            Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "build\app\DanXi-$version_code-release.android.apk"
            Write-Output ""
        }
    }
    "windows" {
        & {
            Write-Output "Build for Windows..."
            Write-Output ""
            Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/C flutter build windows --release --dart-define=GIT_HASH=$GIT_HASH"
            Write-Output "Clean old files..."
            Remove-Item -Force -Path "build\app\DanXi-$version_code-release.windows-x64.zip"
            Set-Location -Path "build\windows\runner\Release\"
            Write-Output "Copy file..."
            7z a -r -sse "..\..\..\..\build\app\DanXi-$version_code-release.windows-x64.zip" *
            Set-Location -Path "..\..\..\..\"
            Write-Output ""
        }
    }
    "aab" {
        & {
            Write-Output "Build for App Bundle (Google Play Distribution)..."
            Write-Output ""
            Write-Output "Clean old files..."
            Remove-Item -Force -Path "build\app\DanXi-$version_code-release.android.aab"
            Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/C flutter build appbundle --release --dart-define=GIT_HASH=$GIT_HASH"
            Write-Output "Copy file..."
            Copy-Item -Path "build\app\outputs\bundle\release\app-release.aab" -Destination "build\app\DanXi-$version_code-release.android.aab"
        }
    }
    default {
        Write-Error "A valid target is required: android, windows, aab"
        exit 1
    }
}

Write-Output "Build success."
