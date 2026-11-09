# NoveLib

Windows向けのビジュアルノベル管理アプリです。Flutterアプリは
[source/app](source/app)、インストーラー設定は
[source/installer](source/installer) にあります。

## ライセンス

NoveLibの自作アプリコードは [MIT License](LICENSE) です。
第三者のコードには各コンポーネントのライセンスが適用されます。
同梱のVNDB由来カタログにはODbL／DbCLが適用されます。
出典と適用範囲は [カタログ資料](docs/CATALOG-DATA.md) を参照してください。
ロゴと画像素材はアプリコードのMITライセンスの対象外です。

## Windowsでのビルド

Flutter SDK、Visual Studioの「C++によるデスクトップ開発」ワークロードが必要です。
PowerShellでリポジトリのルートから実行します。

```powershell
Set-Location source/app
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter build windows --release
```

インストーラーとZIPを作る場合は、Inno Setup 6も用意し、
リポジトリのルートに戻って `tools/build-windows-installer.ps1` を実行します。
