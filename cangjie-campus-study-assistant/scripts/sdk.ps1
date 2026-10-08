function Resolve-StudyMateSdk {
    param([string]$SdkHome = '')
    if ([string]::IsNullOrWhiteSpace($SdkHome)) { $SdkHome = $env:CANGJIE_HOME }
    if ([string]::IsNullOrWhiteSpace($SdkHome)) {
        $compiler = Get-Command cjc.exe -ErrorAction SilentlyContinue
        if ($null -ne $compiler) { $SdkHome = Split-Path (Split-Path $compiler.Source -Parent) -Parent }
    }
    if ([string]::IsNullOrWhiteSpace($SdkHome)) {
        throw 'Cangjie SDK not found. Set CANGJIE_HOME or pass -SdkHome.'
    }
    $sdkRoot = [IO.Path]::GetFullPath($SdkHome)
    foreach ($relative in @('bin\cjc.exe', 'envsetup.ps1')) {
        if (!(Test-Path -LiteralPath (Join-Path $sdkRoot $relative) -PathType Leaf)) {
            throw "Invalid SDK directory: $sdkRoot (missing $relative)"
        }
    }
    return $sdkRoot
}
