param([switch]$Demo, [switch]$Plan, [switch]$SkipBuild, [string]$SdkHome = '')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (!$SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -SdkHome $SdkHome }
$program = Join-Path $projectRoot 'target\release\bin\StudyMate.exe'
if (!(Test-Path -LiteralPath $program -PathType Leaf)) { throw 'Build the project before running.' }
$dataFile = if ($Demo) { Join-Path $projectRoot 'data\demo-tasks.tsv' } else { Join-Path $projectRoot 'data\tasks.tsv' }
$runArgs = @('--data', ('"' + $dataFile + '"'))
if ($Demo) { $runArgs += '--demo' }
if ($Plan) { $runArgs += '--show-plan' }
Start-Process -FilePath $program -ArgumentList $runArgs -WorkingDirectory $projectRoot -WindowStyle Normal
