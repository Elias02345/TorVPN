#!/usr/bin/env pwsh
# dev-cargo.ps1 - run cargo inside the MSVC build environment on Windows.
#
# Why this exists:
#   The Rust `*-pc-windows-msvc` toolchain needs two things a normal PowerShell
#   session does not provide:
#     1. The MSVC `link.exe` ahead of Git's coreutils `link.exe` on PATH
#        (Git ships C:\Program Files\Git\usr\bin\link.exe which otherwise wins).
#     2. The Windows SDK library paths in the LIB environment variable
#        (otherwise linking fails with "cannot open input file 'kernel32.lib'").
#   Both are provided by the Visual Studio "vcvars64" environment. This wrapper
#   loads that environment and then forwards all arguments to cargo, so the same
#   `cargo ...` invocation works from any shell.
#
# Usage (from the repository root):
#   tools/dev-cargo.ps1 build --workspace
#   tools/dev-cargo.ps1 test --workspace
#   tools/dev-cargo.ps1 fmt --check
#   tools/dev-cargo.ps1 clippy --workspace --all-targets -- -D warnings
#
# On Linux/macOS just call cargo directly; this wrapper is Windows-only.

$ErrorActionPreference = 'Stop'

function Find-VcVars64 {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath
        if ($installPath) {
            $candidate = Join-Path $installPath 'VC\Auxiliary\Build\vcvars64.bat'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    foreach ($edition in @('Community', 'Professional', 'Enterprise', 'BuildTools')) {
        $candidate = "C:\Program Files\Microsoft Visual Studio\2022\$edition\VC\Auxiliary\Build\vcvars64.bat"
        if (Test-Path $candidate) { return $candidate }
    }
    throw "vcvars64.bat not found. Install Visual Studio 2022 with the 'Desktop development with C++' workload and the Windows SDK."
}

function Import-VcVarsEnv {
    param([Parameter(Mandatory)] [string] $VcVarsPath)
    # Run vcvars64 in a child cmd and import the resulting environment variables.
    $captured = & cmd /c "`"$VcVarsPath`" >nul 2>&1 && set"
    foreach ($line in $captured) {
        if ($line -match '^([^=]+)=(.*)$') {
            Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
        }
    }
}

$vcvars = Find-VcVars64
Import-VcVarsEnv -VcVarsPath $vcvars

# Sanity check: the Windows SDK must be present, otherwise linking will fail.
if (-not $env:LIB -or ($env:LIB -notmatch 'Windows Kits')) {
    Write-Warning "Windows SDK libraries were not found in LIB. Install the Windows SDK via the Visual Studio Installer (component Microsoft.VisualStudio.Component.Windows11SDK.22621)."
}

& cargo @args
exit $LASTEXITCODE
