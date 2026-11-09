import 'package:flutter/material.dart';

import '../../catalog/catalog_database.dart';
import '../../theme/app_theme.dart';
import 'release_notes_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.scanFolders,
    required this.isScanning,
    required this.scanMessage,
    required this.onAddFolder,
    required this.onRescanFolder,
    required this.onRemoveFolder,
    this.isManagingFolders = false,
    this.onManageImages,
    this.onDiagnostics,
    this.onManualRegister,
    this.onDataTransfer,
    this.onOpenCatalog,
    this.catalog,
    this.isUpdatingCatalog = false,
    this.onUpdateCatalog,
    this.onRestoreCatalog,
    this.onGuide,
    this.onInformation,
    this.closeToTray = true,
    this.onCloseToTrayChanged,
    this.showAdult = true,
    this.onShowAdultChanged,
    this.themeMode = ThemeMode.dark,
    this.onThemeModeChanged,
    this.blurCovers = false,
    this.onBlurCoversChanged,
    this.reviewSharingAvailable = false,
    this.reviewSharingEnabled = false,
    this.reviewSyncing = false,
    this.reviewSyncStatus,
    this.onReviewSharingChanged,
    this.onReviewSyncRequested,
    this.onEraseSharedReviews,
  });

  final List<String> scanFolders;
  final bool isScanning;
  final bool isManagingFolders;
  final String? scanMessage;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onRescanFolder;
  final ValueChanged<String> onRemoveFolder;
  final VoidCallback? onManageImages, onDiagnostics, onManualRegister;
  final VoidCallback? onDataTransfer;
  final VoidCallback? onOpenCatalog;
  final CatalogDatabase? catalog;
  final bool isUpdatingCatalog;
  final VoidCallback? onUpdateCatalog;
  final VoidCallback? onRestoreCatalog;
  final VoidCallback? onGuide, onInformation;
  final bool closeToTray;
  final ValueChanged<bool>? onCloseToTrayChanged;
  final bool showAdult;
  final ValueChanged<bool>? onShowAdultChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final bool blurCovers;
  final ValueChanged<bool>? onBlurCoversChanged;
  final bool reviewSharingAvailable;
  final bool reviewSharingEnabled;
  final bool reviewSyncing;
  final String? reviewSyncStatus;
  final ValueChanged<bool>? onReviewSharingChanged;
  final VoidCallback? onReviewSyncRequested;
  final VoidCallback? onEraseSharedReviews;

  @override
  Widget build(BuildContext context) {
    final busy = isScanning || isManagingFolders;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ColoredBox(
      color: context.appColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 30,
              compact ? 20 : 26,
              compact ? 18 : 30,
              compact ? 16 : 22,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.appColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('設定', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 5),
                Text(
                  'ゲームの登録場所とアプリの動作を管理します。',
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(compact ? 16 : 30),
              children: [
                SettingsSection(
                  title: 'ゲームフォルダ',
                  description:
                      '指定したフォルダ以下を再スキャンできます。対象から外しても登録作品やゲーム本体は削除されません。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (scanFolders.isEmpty)
                        const EmptyFolderState()
                      else
                        for (final folder in scanFolders)
                          FolderRow(
                            path: folder,
                            onRescan: busy
                                ? null
                                : () => onRescanFolder(folder),
                            onRemove: busy
                                ? null
                                : () => onRemoveFolder(folder),
                          ),
                      if (scanMessage != null) ...[
                        const SizedBox(height: 12),
                        ScanNotice(message: scanMessage!, loading: isScanning),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: busy ? null : onAddFolder,
                          icon: isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.create_new_folder_outlined,
                                  size: 18,
                                ),
                          label: Text(isScanning ? 'スキャン中…' : 'フォルダを追加してスキャン'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SettingsSection(
                  title: 'キーボード操作',
                  description: 'マウスを使わず主要画面へ移動できます。',
                  child: SelectableText(
                    'Ctrl+1  ライブラリ　　Ctrl+2  プレイ状況\n'
                    'Ctrl+3  評価ランキング　Ctrl+4  統計\n'
                    'Ctrl+5  ウィッシュリスト　Ctrl+6  設定\n'
                    'Ctrl+,  設定　　　　　Ctrl+F  画面内検索\n'
                    'Esc / Alt+←  作品詳細からライブラリへ戻る',
                    style: TextStyle(height: 1.8),
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: '作品カタログ',
                  description: catalog == null
                      ? '作品カタログに接続されていません。'
                      : '${catalog!.workCount}作品 ・ 更新 ${catalog!.sourceTimestamp}\n'
                            '更新ファイルは端末内だけで使用し、サーバーへ送信しません。',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: onOpenCatalog,
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('作品カタログを見る'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy || isUpdatingCatalog
                            ? null
                            : onUpdateCatalog,
                        icon: isUpdatingCatalog
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.system_update_alt_rounded),
                        label: Text(
                          isUpdatingCatalog ? '更新中…' : 'ローカル更新ファイルを選択',
                        ),
                      ),
                      if (catalog?.isUsingUpdate == true)
                        TextButton(
                          onPressed: busy || isUpdatingCatalog
                              ? null
                              : onRestoreCatalog,
                          child: const Text('同梱版に戻す'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: '取り込み・画像の管理',
                  description: '未検出・未照合の確認、実行ファイル指定での登録、取得画像の再取得・削除を行います。',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : onDiagnostics,
                        child: const Text('未検出・未照合を確認'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : onManualRegister,
                        child: const Text('実行ファイルを指定して登録'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : onManageImages,
                        child: const Text('画像キャッシュ管理'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: 'データの保存・移行',
                  description: '作品一覧の出力と、全ユーザーデータのバックアップ・復元。',
                  child: OutlinedButton(
                    onPressed: busy ? null : onDataTransfer,
                    child: const Text('エクスポート・バックアップ'),
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: '使い方・データ出典',
                  description: '記録はこのPC内に保存します。画像の取得には外部通信が発生します。',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : onGuide,
                        child: const Text('はじめての使い方'),
                      ),
                      OutlinedButton(
                        onPressed: onInformation,
                        child: const Text('データ出典・プライバシー'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => const ReleaseNotesDialog(),
                        ),
                        icon: const Icon(Icons.history),
                        label: const Text('変更履歴（v$appReleaseVersion）'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: 'アプリの動作',
                  description: '外観、終了時の動作、R18作品の表示を設定します。',
                  child: Column(
                    children: [
                      if (compact) ...[
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.palette_outlined),
                          title: Text('画面テーマ'),
                          subtitle: Text('初期設定はダークです。'),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('ダーク'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('ライト'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: onThemeModeChanged == null
                                ? null
                                : (selected) =>
                                      onThemeModeChanged!(selected.single),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('画面テーマ'),
                          subtitle: const Text('初期設定はダークです。'),
                          trailing: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('ダーク'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('ライト'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: onThemeModeChanged == null
                                ? null
                                : (selected) =>
                                      onThemeModeChanged!(selected.single),
                          ),
                        ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.blur_on_rounded),
                        title: const Text('表紙画像をぼかす'),
                        subtitle: const Text(
                          'ライブラリと作品詳細の表紙へ適用します。作品情報の編集から作品ごとに上書きできます。初期設定はオフです。',
                        ),
                        value: blurCovers,
                        onChanged: onBlurCoversChanged,
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.window_rounded),
                        title: const Text('閉じたときにタスクトレイへ格納'),
                        subtitle: const Text('格納後もゲームのプレイ時間を記録します。'),
                        value: closeToTray,
                        onChanged: onCloseToTrayChanged,
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.visibility_outlined),
                        title: const Text('R18作品を表示'),
                        subtitle: const Text(
                          '18歳以上の利用者向けです。有効化時に年齢確認します。非表示でも登録データは削除されません。',
                        ),
                        value: showAdult,
                        onChanged: onShowAdultChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSection(
                  title: '評価ランキングへの共有',
                  description:
                      '同意した場合だけ、VNDB ID・作品名・評価点・公開コメントを送信します。'
                      'インストール先、実行ファイル、プレイ時間、タグ、個人メモは送信しません。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.cloud_upload_outlined),
                        title: const Text('匿名で評価を共有する'),
                        subtitle: Text(
                          reviewSharingAvailable
                              ? '初回案内では共有オンをおすすめします。オフにしても送信済みデータは残るため、完全削除は下のボタンから行えます。'
                              : '評価サーバー未接続のプレビュー版です。接続済みビルドで利用できます。',
                        ),
                        value: reviewSharingEnabled,
                        onChanged: reviewSharingAvailable
                            ? onReviewSharingChanged
                            : null,
                      ),
                      if (reviewSyncStatus != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          reviewSyncStatus!,
                          key: const Key('review-sync-status'),
                          style: TextStyle(
                            color: context.appColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (reviewSharingEnabled) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: reviewSyncing
                                ? null
                                : onReviewSyncRequested,
                            icon: reviewSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded),
                            label: Text(reviewSyncing ? '同期中…' : '今すぐ同期'),
                          ),
                        ),
                      ],
                      if (reviewSharingAvailable) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: reviewSyncing
                                ? null
                                : onEraseSharedReviews,
                            icon: const Icon(Icons.delete_forever_outlined),
                            label: const Text('共有済み評価をサーバーから削除'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Material(
        color: context.appColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.appColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyFolderState extends StatelessWidget {
  const EmptyFolderState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_off_outlined, color: context.appColors.textFaint),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'まだスキャン対象フォルダがありません',
              style: TextStyle(
                color: context.appColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FolderRow extends StatelessWidget {
  const FolderRow({
    super.key,
    required this.path,
    this.onRescan,
    this.onRemove,
  });
  final String path;
  final VoidCallback? onRescan, onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.canvas,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, color: AppColors.accent, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          IconButton(
            tooltip: '再スキャン',
            onPressed: onRescan,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'スキャン対象から外す',
            onPressed: onRemove,
            icon: const Icon(Icons.folder_off_outlined),
          ),
        ],
      ),
    );
  }
}

class ScanNotice extends StatelessWidget {
  const ScanNotice({super.key, required this.message, required this.loading});
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (loading)
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue,
            size: 17,
          ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: context.appColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.appColors.selected,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
