# =============================================================================
#  build-apk.ps1 — one-command Android APK build for Venue Reservation.
# -----------------------------------------------------------------------------
#  Sets up the required environment variables, builds a release APK, and
#  copies the result to the project root as `venue-reservation.apk` so you
#  always know where to find the latest build.
#
#  Usage (from any directory):
#     pwsh C:\Res\build-apk.ps1
#  or
#     cd C:\Res; .\build-apk.ps1
#
#  Optional flags:
#     -SplitPerAbi       build three per-ABI APKs (~8 MB each) instead of one
#                        universal (~23 MB) APK
#     -AppBundle         also build an .aab for Play Store upload
#     -NoCopy            skip copying to project root (artifact stays in
#                        build/app/outputs/flutter-apk only)
# =============================================================================

param(
    [switch]$SplitPerAbi,
    [switch]$AppBundle,
    [switch]$NoCopy
)

$ErrorActionPreference = 'Stop'
$projectRoot = 'C:\Res'

# ---- Toolchain environment ---------------------------------------------------
# Auto-detect the Microsoft OpenJDK 17 install (version suffix changes with
# patch updates), falling back to a sensible default.
$jdkRoot = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'jdk-17*hotspot' } |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($jdkRoot) { $env:JAVA_HOME = $jdkRoot.FullName }
else { $env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot' }

# Android SDK can live in either %USERPROFILE%\Android\Sdk (legacy) or the
# newer %LOCALAPPDATA%\Android\Sdk; prefer whichever exists.
if (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools") {
    $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
} else {
    $env:ANDROID_HOME = "$env:USERPROFILE\Android\Sdk"
}

$env:Path = "$env:USERPROFILE\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:USERPROFILE\flutter-tools\flutter\bin;$env:Path"

Push-Location $projectRoot
try {
    Write-Host "=== Flutter version ===" -ForegroundColor Cyan
    flutter --version | Select-Object -First 1

    Write-Host ""
    Write-Host "=== Building release APK ===" -ForegroundColor Cyan
    $sw = [Diagnostics.Stopwatch]::StartNew()

    if ($SplitPerAbi) {
        flutter build apk --release --split-per-abi
    } else {
        flutter build apk --release
    }
    if ($LASTEXITCODE -ne 0) { throw "APK build failed with exit code $LASTEXITCODE" }

    if ($AppBundle) {
        Write-Host ""
        Write-Host "=== Building app bundle (.aab) ===" -ForegroundColor Cyan
        flutter build appbundle --release
        if ($LASTEXITCODE -ne 0) { throw "AAB build failed with exit code $LASTEXITCODE" }
    }

    $sw.Stop()
    Write-Host ""
    Write-Host ("=== Build finished in {0} min ===" -f [math]::Round($sw.Elapsed.TotalMinutes, 1)) -ForegroundColor Green

    # ---- Copy final artifact to project root --------------------------------
    if (-not $NoCopy) {
        Write-Host ""
        Write-Host "=== Copying APK(s) to $projectRoot ===" -ForegroundColor Cyan
        $apkSrcDir = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
        $apks = Get-ChildItem "$apkSrcDir\*.apk" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notlike '*.sha1*' }
        foreach ($apk in $apks) {
            # Rename app-release.apk -> venue-reservation.apk
            # Rename app-arm64-v8a-release.apk -> venue-reservation-arm64-v8a.apk, etc.
            $friendly = $apk.Name `
                -replace '^app-', 'venue-reservation-' `
                -replace '-release', '' `
                -replace '^venue-reservation-\.apk$', 'venue-reservation.apk'
            if ($friendly -eq 'venue-reservation-.apk') { $friendly = 'venue-reservation.apk' }
            $dst = Join-Path $projectRoot $friendly
            Copy-Item $apk.FullName $dst -Force
        }

        if ($AppBundle) {
            $aabSrc = Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab'
            if (Test-Path $aabSrc) {
                Copy-Item $aabSrc (Join-Path $projectRoot 'venue-reservation.aab') -Force
            }
        }
    }

    # ---- Report -------------------------------------------------------------
    Write-Host ""
    Write-Host "=== Build artifacts in $projectRoot ===" -ForegroundColor Green
    Get-ChildItem "$projectRoot\venue-reservation*.apk", "$projectRoot\venue-reservation*.aab" `
        -ErrorAction SilentlyContinue |
        Select-Object `
            @{N='File';E={$_.Name}}, `
            @{N='Size';E={ '{0,7:N2} MB' -f ($_.Length / 1MB) }}, `
            @{N='Modified';E={$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')}} |
        Format-Table -AutoSize

    Write-Host "SHA-256 of universal APK:" -ForegroundColor Gray
    $main = Join-Path $projectRoot 'venue-reservation.apk'
    if (Test-Path $main) {
        (Get-FileHash $main -Algorithm SHA256).Hash
    }
}
finally {
    Pop-Location
}
