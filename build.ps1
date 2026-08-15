$ErrorActionPreference = "Stop"

$modDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rustDir = Join-Path $modDir "..\hyper-audio-rs"
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

$staging = Join-Path $modDir "module_pkg"
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Path $staging -Force | Out-Null
New-Item -ItemType Directory -Path "$staging\system\lib64" -Force | Out-Null

Write-Host "Copying files..."
Copy-Item -Recurse (Join-Path $modDir "META-INF") "$staging\"
Copy-Item -Recurse (Join-Path $modDir "odm") "$staging\"
Copy-Item -Recurse (Join-Path $modDir "system\vendor") "$staging\system"
Copy-Item (Join-Path $modDir "\system\lib64\libaaudio_internal.so") "$staging\system\lib64"
Copy-Item (Join-Path $modDir "\system\lib64\libaaudio_internal_builder.so") "$staging\system\lib64"
Copy-Item (Join-Path $modDir "action.sh") "$staging\"
Copy-Item (Join-Path $modDir "customize.sh") "$staging\"
Copy-Item (Join-Path $modDir "module.prop") "$staging\"
Copy-Item (Join-Path $modDir "post-fs-data.sh") "$staging\"
Copy-Item (Join-Path $modDir "service.sh") "$staging\"
Copy-Item (Join-Path $modDir "system.prop") "$staging\"
Copy-Item (Join-Path $rustDir "config.toml") "$staging\"
Copy-Item (Join-Path $rustDir "target\aarch64-linux-android\release\hyper-audio") "$staging\hyper-audio"

$outDir = $modDir
$outZip = Join-Path $outDir $zipName

Write-Host "Creating $outZip ..."
if (Test-Path $outZip) { Remove-Item $outZip }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($outZip, 'Create')
Get-ChildItem -Recurse -File $staging | ForEach-Object {
    $entry = $_.FullName.Substring($staging.Length + 1) -replace '\\', '/'
    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $entry)
}
$archive.Dispose()

Remove-Item -Recurse -Force $staging
Write-Host "Done: $outZip"
