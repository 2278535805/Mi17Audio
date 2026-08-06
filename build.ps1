$ErrorActionPreference = "Stop"

$modDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rustDir = "..\hyper-audio-rs"
$name = "Mi17Audio"
$zipName = "${name}.zip"
# $version = (Select-String -Path "$modDir\module.prop" -Pattern '^version=').Line.Split('=')[1]
# $zipName = "${name}_${version}.zip"

Write-Host "Building Rust binary..."
Push-Location $rustDir
try {
    cargo ndk -t arm64-v8a build --release
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }
} finally {
    Pop-Location
}

$staging = "$modDir\module_pkg"
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

Write-Host "Copying files..."
Copy-Item -Recurse "$modDir\META-INF"     "$staging\"
Copy-Item -Recurse "$modDir\odm"          "$staging\"
Copy-Item -Recurse "$modDir\system"       "$staging\"
Copy-Item "$modDir\action.sh"             "$staging\"
Copy-Item "$modDir\customize.sh"          "$staging\"
Copy-Item "$modDir\module.prop"           "$staging\"
Copy-Item "$modDir\post-fs-data.sh"       "$staging\"
Copy-Item "$modDir\service.sh"            "$staging\"
Copy-Item "$modDir\system.prop"           "$staging\"
Copy-Item "$rustDir\config.toml"          "$staging\"
Copy-Item "$rustDir\target\aarch64-linux-android\release\hyper-audio" "$staging\hyper-audio"

$outDir = "$modDir"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outZip = "$outDir\$zipName"

Write-Host "Creating $outZip ..."
if (Test-Path $outZip) { Remove-Item $outZip }
Compress-Archive -Path "$staging\*" -DestinationPath $outZip

Remove-Item -Recurse -Force $staging
Write-Host "Done: $outZip"
