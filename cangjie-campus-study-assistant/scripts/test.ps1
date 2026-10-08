param([string]$SdkHome = '')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'sdk.ps1')
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sdkRoot = Resolve-StudyMateSdk $SdkHome
$testRoot = Join-Path $projectRoot 'target\tests'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$program = Join-Path $testRoot 'studymate-tests.exe'
$sources = @('model.cj', 'planner.cj', 'storage.cj', 'studymate_test.cj') |
    ForEach-Object { Join-Path (Join-Path $projectRoot 'src') $_ }
$previousPath = $env:Path
$previousCangjieHome = $env:CANGJIE_HOME
try {
    . (Join-Path $sdkRoot 'envsetup.ps1')
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & (Join-Path $sdkRoot 'bin\cjc.exe') @sources --test -o $program
        $compileExitCode = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousErrorAction }
    if ($compileExitCode -ne 0) { throw "Test compilation failed: $compileExitCode" }
    & $program
    if ($LASTEXITCODE -ne 0) { throw "Tests failed: $LASTEXITCODE" }
} finally {
    $env:Path = $previousPath
    $env:CANGJIE_HOME = $previousCangjieHome
}
