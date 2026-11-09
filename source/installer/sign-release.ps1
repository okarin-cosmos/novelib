param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9A-Fa-f]{40}$')]
  [string]$CertificateThumbprint,
  [Parameter(Mandatory = $true)]
  [string]$InstallerPath,
  [string]$ApplicationPath = '..\app\build\windows\x64\runner\Release\NoveLib.exe'
)

$ErrorActionPreference = 'Stop'
$signTool = Get-Command signtool.exe -ErrorAction SilentlyContinue
if ($null -eq $signTool) {
  throw 'signtool.exe が見つかりません。Windows SDK をインストールしてください。'
}
$targets = @(
  (Resolve-Path -LiteralPath $ApplicationPath).Path,
  (Resolve-Path -LiteralPath $InstallerPath).Path
)
foreach ($target in $targets) {
  & $signTool.Source sign /sha1 $CertificateThumbprint /fd SHA256 `
    /tr 'http://timestamp.digicert.com' /td SHA256 $target
  if ($LASTEXITCODE -ne 0) { throw "コード署名に失敗しました: $target" }
  & $signTool.Source verify /pa /all $target
  if ($LASTEXITCODE -ne 0) { throw "署名検証に失敗しました: $target" }
}
