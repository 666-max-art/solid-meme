param([string]$SdkHome = '')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'sdk.ps1')
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sdkRoot = Resolve-StudyMateSdk $SdkHome
$nativeRoot = Join-Path $projectRoot 'vendor\CangjieSDL\.sdl3'
$runtimeRoot = Join-Path $sdkRoot 'runtime\lib\windows_x86_64_cjnative'
$nativeNames = @('SDL3.dll', 'SDL3_ttf.dll', 'SDL3_image.dll')
foreach ($name in $nativeNames) {
    foreach ($requiredName in @($name, ('lib' + $name))) {
        if (!(Test-Path -LiteralPath (Join-Path $nativeRoot $requiredName) -PathType Leaf)) {
            throw "Missing SDL library: $requiredName. See docs/BUILD.md."
        }
    }
}
foreach ($name in @('libcangjie-runtime.dll', 'libboundscheck.dll')) {
    if (!(Test-Path -LiteralPath (Join-Path $runtimeRoot $name) -PathType Leaf)) {
        throw "Missing Cangjie runtime: $name"
    }
}
$previousPath = $env:Path
$previousCangjieHome = $env:CANGJIE_HOME
try {
    . (Join-Path $sdkRoot 'envsetup.ps1')
    $packageManager = Get-Command cjpm.exe -ErrorAction SilentlyContinue
    if ($null -eq $packageManager) { throw 'cjpm not found after SDK environment setup.' }
    Push-Location -LiteralPath $projectRoot
    try {
        $previousErrorAction = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $packageManager.Source build
            $buildExitCode = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previousErrorAction }
        if ($buildExitCode -ne 0) { throw "cjpm build failed: $buildExitCode" }
    } finally { Pop-Location }
    $outputRoot = Join-Path $projectRoot 'target\release\bin'
    $compiledExe = Join-Path $outputRoot 'main.exe'
    if (!(Test-Path -LiteralPath $compiledExe -PathType Leaf)) {
        throw 'Expected target/release/bin/main.exe was not created.'
    }
    Copy-Item -LiteralPath $compiledExe -Destination (Join-Path $outputRoot 'StudyMate.exe') -Force
    foreach ($name in $nativeNames) {
        Copy-Item -LiteralPath (Join-Path $nativeRoot $name) -Destination (Join-Path $outputRoot $name) -Force
    }
    foreach ($name in @('libcangjie-runtime.dll', 'libboundscheck.dll')) {
        Copy-Item -LiteralPath (Join-Path $runtimeRoot $name) -Destination (Join-Path $outputRoot $name) -Force
    }
    Write-Host "Built: $(Join-Path $outputRoot 'StudyMate.exe')"
} finally {
    $env:Path = $previousPath
    $env:CANGJIE_HOME = $previousCangjieHome
}
