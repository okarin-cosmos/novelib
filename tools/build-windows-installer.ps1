param(
    [string]$Version = '0.46.3',
    [int]$BuildNumber = 55
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $projectRoot 'source\app'
$installerScript = Join-Path $projectRoot 'source\installer\NoveLib.iss'
$releaseOutput = Join-Path $projectRoot 'releases'
$buildOutput = Join-Path $appRoot 'build\windows\x64\runner\Release'
$notes = Join-Path $appRoot "assets\release_notes\v$Version.txt"
if (-not (Test-Path -LiteralPath $notes)) { throw '公開用パッチノートがありません。変更履歴を記録してからビルドしてください。' }
$packageVersion = Get-Content (Join-Path $appRoot 'pubspec.yaml') -Raw
if ($packageVersion -notmatch "(?m)^version: $([regex]::Escape($Version))\+$BuildNumber\s*$") {
    throw 'pubspec.yamlと指定バージョンが一致しません。'
}
$portableZip = Join-Path $releaseOutput "NoveLib-v$Version-Portable.zip"
$installerZip = Join-Path $releaseOutput "NoveLib-v$Version-Installer.zip"
$releaseNotes = Join-Path $releaseOutput "NoveLib-v$Version-PATCH-NOTES.txt"
$hashFile = Join-Path $releaseOutput "novelib-v$Version-preview-SHA256.txt"
$expectedInstaller = Join-Path $releaseOutput "novelib-v$Version-preview-setup.exe"
foreach ($target in @($portableZip,$installerZip,$releaseNotes,$hashFile,$expectedInstaller)) {
    if (Test-Path -LiteralPath $target) { throw "既存の配布物は上書きしません: $target" }
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    $bundledFlutter = Join-Path (Split-Path -Parent $projectRoot) 'flutter-sdk\bin\flutter.bat'
    if (Test-Path -LiteralPath $bundledFlutter) {
        $flutter = Get-Item -LiteralPath $bundledFlutter
    } else {
        throw 'Flutter SDK が見つかりません。flutterをPATHへ追加してから再試行してください。'
    }
}
$compiler = Get-Command iscc.exe -ErrorAction SilentlyContinue
if (-not $compiler) {
    $compilerCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    )
    $defaultCompiler = $compilerCandidates |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if (-not $defaultCompiler) {
        throw 'Inno Setup 6 が見つかりません。winget install --id JRSoftware.InnoSetup を実行してから再試行してください。'
    }
    $compiler = Get-Item -LiteralPath $defaultCompiler
}

Push-Location $appRoot
try {
    & $flutter.FullName pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get に失敗しました。' }

    # Golden画像を含むため、文字描画の並列実行差を避けて直列で検証する。
    & $flutter.FullName test --concurrency=1
    if ($LASTEXITCODE -ne 0) { throw 'テストに失敗しました。' }

    & $flutter.FullName build windows --release --build-name $Version --build-number $BuildNumber
    if ($LASTEXITCODE -ne 0) { throw 'Windowsリリースビルドに失敗しました。' }
} finally {
    Pop-Location
}

& $compiler.FullName "/DMyAppVersion=$Version" "/DBuildOutput=$buildOutput" "/DReleaseOutput=$releaseOutput" $installerScript
if ($LASTEXITCODE -ne 0) { throw 'インストーラー作成に失敗しました。' }

$installer = Join-Path $releaseOutput "novelib-v$Version-preview-setup.exe"
if (-not (Test-Path -LiteralPath $installer)) {
    throw "インストーラーが生成されませんでした: $installer"
}

Copy-Item -LiteralPath $notes -Destination $releaseNotes
$packageWork = Join-Path $projectRoot ("work\package-$Version-" + [guid]::NewGuid().ToString('N'))
$portableWork = Join-Path $packageWork 'Portable'
$installerWork = Join-Path $packageWork 'Installer'
New-Item -ItemType Directory -Path $portableWork,$installerWork | Out-Null
Get-ChildItem -LiteralPath $buildOutput | Copy-Item -Destination $portableWork -Recurse
Copy-Item -LiteralPath $notes -Destination (Join-Path $portableWork 'PATCH-NOTES.txt')
Copy-Item -LiteralPath $installer -Destination $installerWork
Copy-Item -LiteralPath $notes -Destination (Join-Path $installerWork 'PATCH-NOTES.txt')
Compress-Archive -Path (Join-Path $portableWork '*') -DestinationPath $portableZip
Compress-Archive -Path (Join-Path $installerWork '*') -DestinationPath $installerZip
$hashLines = foreach ($file in @($portableZip,$installerZip,$installer,$releaseNotes)) {
    $hash = Get-FileHash -LiteralPath $file -Algorithm SHA256
    "$($hash.Hash)  $([IO.Path]::GetFileName($file))"
}
[IO.File]::WriteAllLines($hashFile,$hashLines,[Text.UTF8Encoding]::new($false))
$hashLines
