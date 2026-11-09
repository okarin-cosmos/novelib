#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('\A\d+\.\d+\.\d+\z')][string]$Version,
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$BuildNumber,
    [Parameter(Mandatory)][uri]$PackageBaseUri,
    [Parameter(Mandatory)][string]$PrivateKeyPath
)

$ErrorActionPreference = 'Stop'
if (!$PackageBaseUri.IsAbsoluteUri -or $PackageBaseUri.Scheme -ne 'https' -or
    $PackageBaseUri.UserInfo -or $PackageBaseUri.Query -or $PackageBaseUri.Fragment -or
    !$PackageBaseUri.AbsolutePath.EndsWith('/')) {
    throw 'PackageBaseUri must be an HTTPS directory URL ending in /.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseDirectory = Join-Path $projectRoot 'releases'
$packageNames = [ordered]@{
    installer = "novelib-v$Version-preview-setup.exe"
    portable = "NoveLib-v$Version-Portable.zip"
}
$packages = [ordered]@{}
foreach ($edition in $packageNames.Keys) {
    $name = $packageNames[$edition]
    $file = Get-Item -LiteralPath (Join-Path $releaseDirectory $name)
    if ($file.PSIsContainer -or $file.Length -le 0) {
        throw "Invalid package: $name"
    }
    $packages[$edition] = [ordered]@{
        url = [uri]::new($PackageBaseUri, $name).AbsoluteUri
        bytes = $file.Length
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

$payload = [ordered]@{
    schema = 1
    product = 'NoveLib'
    channel = 'preview'
    platform = 'windows-x64'
    version = $Version
    build = $BuildNumber
    packages = $packages
}
$payloadBytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 6 -Compress))
$rsa = [Security.Cryptography.RSA]::Create()
try {
    $rsa.ImportFromPem([IO.File]::ReadAllText((Get-Item -LiteralPath $PrivateKeyPath).FullName))
    if ($rsa.KeySize -lt 3072) {
        throw 'The update signing key must be at least RSA-3072.'
    }
    $signature = $rsa.SignData(
        $payloadBytes,
        [Security.Cryptography.HashAlgorithmName]::SHA256,
        [Security.Cryptography.RSASignaturePadding]::Pss
    )
} finally {
    $rsa.Dispose()
}

$envelope = [ordered]@{
    payload = [Convert]::ToBase64String($payloadBytes)
    signature = [Convert]::ToBase64String($signature)
}
$workDirectory = Join-Path $projectRoot 'work'
New-Item -ItemType Directory -Path $workDirectory -Force | Out-Null
$output = Join-Path $workDirectory "novelib-update-$Version+$BuildNumber.json"
$temp = Join-Path $workDirectory ([guid]::NewGuid().ToString('N') + '.tmp')
try {
    [IO.File]::WriteAllText($temp, ($envelope | ConvertTo-Json -Compress))
    [IO.File]::Move($temp, $output)
} finally {
    if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
}
Get-Item -LiteralPath $output
