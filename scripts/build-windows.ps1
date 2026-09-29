# Builds camillia_core.dll for Windows and generates C# bindings.
#
# Usage: scripts\build-windows.ps1 -OutDir <dir> [-Profile debug|release] [-Target <rust-target>]
# -Target defaults to the host architecture (aarch64- or x86_64-pc-windows-msvc).
#
# Requires uniffi-bindgen-cs matching the pinned uniffi version:
#   cargo install uniffi-bindgen-cs --git https://github.com/NordSecurity/uniffi-bindgen-cs --tag v0.11.0+v0.31.0
#
# Produces:
#   <OutDir>\camillia_core.dll
#   <OutDir>\camillia_core.cs
param(
    [Parameter(Mandatory = $true)][string]$OutDir,
    [ValidateSet("debug", "release")][string]$Profile = "release",
    [string]$Target = ""
)
$ErrorActionPreference = "Stop"

if (-not $Target) {
    $Target = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64-pc-windows-msvc" } else { "x86_64-pc-windows-msvc" }
}

$CoreDir = Resolve-Path (Join-Path $PSScriptRoot "..")
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = Resolve-Path $OutDir

Push-Location $CoreDir
try {
    $buildArgs = @("build", "-p", "camillia_core", "--target", $Target)
    if ($Profile -eq "release") { $buildArgs += "--release" }
    rustup target add $Target | Out-Null
    cargo @buildArgs
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }

    $dll = Join-Path $CoreDir "target\$Target\$Profile\camillia_core.dll"
    uniffi-bindgen-cs --library $dll --config (Join-Path $CoreDir "uniffi.toml") --out-dir $OutDir
    if ($LASTEXITCODE -ne 0) { throw "uniffi-bindgen-cs failed" }

    Copy-Item $dll $OutDir -Force
    Write-Host "camillia_core ($Profile, $Target) -> $OutDir"
}
finally {
    Pop-Location
}
