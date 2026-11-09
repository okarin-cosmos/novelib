import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../database/app_database.dart';
import '../../catalog/catalog_database.dart';
import '../../widgets/responsive_dialog.dart';

const welcomeSettingKey = 'welcome.completed.v1';
const officialSiteUrl = 'https://okarin-novelab.cfbx.jp/';
const privacyPolicyUrl =
    'https://www.okarin-novelab.cfbx.jp/プライバシーポリシー/';
const developmentXUrl = 'https://x.com/okarin_novelab';
const supportEmail = 'okarin.novelab@gmail.com';

Future<void> _openExternal(BuildContext context, String value) async {
  final opened = await launchUrl(
    Uri.parse(value),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('リンクを開けませんでした。')),
    );
  }
}

Future<bool> needsWelcome(AppDatabase db) async {
  if (await db.readSetting(welcomeSettingKey) == 'true') return false;
  if ((await db.getGames()).isNotEmpty) return false;
  return (await db.getScanFolders()).isEmpty;
}

class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({super.key, required this.onComplete});
  final Future<void> Function() onComplete;
  @override
  State<WelcomeDialog> createState() => _WelcomeState();
}

class _WelcomeState extends State<WelcomeDialog> {
  int step = 0;
  bool busy = false;
  String? error;
  static const titles = ['NoveLibへようこそ', '作品と画像を確認する', '記録を残し、バックアップする'];
  static const descriptions = [
    'NoveLibは、このPCのビジュアルノベルを管理するアプリです。\n\n設定でゲームの入ったフォルダを追加し、スキャンしてください。フォルダ内の実行ファイルと関連データから候補を探します。スキャンだけでゲームを起動することはありません。\n\n見つからない作品は「実行ファイルを指定して登録」も利用できます。',
    '取り込み後はタイトル・保存場所・起動ファイルを確認してください。\n\n「画像・照合を確認」から候補を選べます。版・配信・バージョン表記とカタログ別名を考慮しますが、短い名前や共通のフォルダ名は誤照合防止のため自動確定しません。カタログにない作品は手動で情報や画像を指定できます。\n\n画像の表示時には外部の画像配信元へ通信します。取得した画像はこのPCに保存して再利用します。表紙のぼかしは全体設定に加えて作品情報の編集から個別指定できます。すべての作品の検出・画像取得を保証するものではありません。',
    '作品をクリックすると詳細画面を開きます。評価は10段階とコメントを保存できます。「作品記録」ではタグ・攻略メモ・プレイ予定・履歴を編集できます。「ウィッシュリスト」では未登録の購入候補を管理します。\n\n作品・評価・履歴などはこのPCのSQLiteに保存します。設定からJSONバックアップを保存してください。ゲーム本体や画像ファイルはバックアップに含まれません。\n\nライブラリからの削除は登録とその記録の削除です。ゲーム本体は消しません。復元は全置き換えなので、確認内容をよく読んで実行してください。',
  ];
  Future<void> complete() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onComplete();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = '完了状態を保存できませんでした。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(titles[step]),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${step + 1} / 3', semanticsLabel: '全3ステップの${step + 1}番目'),
              const SizedBox(height: 16),
              Text(descriptions[step], style: const TextStyle(height: 1.6)),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('あとで（設定から再表示）'),
        ),
        if (step > 0)
          TextButton(
            onPressed: busy ? null : () => setState(() => step--),
            child: const Text('戻る'),
          ),
        FilledButton(
          onPressed: busy
              ? null
              : step < 2
              ? () => setState(() => step++)
              : complete,
          child: Text(
            busy
                ? '保存中…'
                : step < 2
                ? '次へ'
                : '完了して設定を開く',
          ),
        ),
      ],
    ),
  );
}

class AppInformationDialog extends StatelessWidget {
  const AppInformationDialog({super.key, this.catalog});
  final CatalogDatabase? catalog;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('データ出典・プライバシー'),
    content: SizedBox(
      width: 700,
      height: responsiveDialogHeight(context, 480),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SelectableText(
              'NoveLib v0.46.0\n運営：おかりん研究室\nお問い合わせ：okarin.novelab@gmail.com\n\n作品カタログの出典：VNDB https://vndb.org/\n公開データベースダンプから生成。原作言語が日本語で、開発中止ではない作品を収録。',
            ),
            SelectableText(
              '収録件数：${catalog?.workCount.toString() ?? '未接続'}\n出典日時：${catalog?.sourceTimestamp ?? '未接続'}',
            ),
            const SizedBox(height: 16),
            const SelectableText(
              'データベース：Open Database License 1.0（ODbL）\nデータ内容：Database Contents License 1.0（DbCL）\n\n作品画像・作品名等の権利は各権利者に帰属します。画像を含む作品素材の再利用許諾を示すものではありません。画像ファイルは同梱せず、配信元から取得します。',
            ),
            const SizedBox(height: 16),
            const SelectableText(
              '保存と通信\n作品の所有状況、評価、メモ、履歴、フォルダ・実行ファイルのパスはこのPC内に保存します。評価ランキングへの匿名共有を有効にした場合だけ、作品ID・点数・任意の評価コメントを評価サーバーへ送信します。保存場所やプレイ履歴は送信しません。共有設定はいつでも停止できます。\n\n画像取得時は画像URLの配信元（通常はVNDBの画像配信サーバー）へ接続し、接続先にはIPアドレスや要求した画像のURLなどが伝わります。カタログ検索自体は同梱DB内で行います。\n\nCSV・JSONを書き出すと、メモや保存場所などの個人情報を含む場合があります。共有先と保存先に注意してください。ゲーム起動後の通信は各ゲームの仕様によります。',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final name in ['ODBL', 'DBCL'])
                  OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => LicenseTextDialog(name: name),
                    ),
                    child: Text('$name 全文'),
                  ),
                OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const PrivacyPolicyDialog(),
                  ),
                  child: const Text('プライバシーポリシー'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openExternal(context, officialSiteUrl),
                  icon: const Icon(Icons.public),
                  label: const Text('公式サイト'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openExternal(context, privacyPolicyUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('公開中のポリシー'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openExternal(
                    context,
                    'mailto:$supportEmail?subject=NoveLibについて',
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('お問い合わせ'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openExternal(context, developmentXUrl),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('開発情報（X）'),
                ),
                OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const TermsDialog(),
                  ),
                  child: const Text('利用規約'),
                ),
                OutlinedButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'NoveLib',
                    applicationVersion: '0.46.0',
                  ),
                  child: const Text('使用ライブラリのライセンス'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('プライバシーポリシー'),
    content: const SizedBox(
      width: 700,
      child: SingleChildScrollView(
        child: SelectableText(
          '最終更新：2026年9月5日\n\n'
          '運営者：おかりん研究室\nお問い合わせ：okarin.novelab@gmail.com\n公式サイト：https://okarin-novelab.cfbx.jp/\n\n'
          'NoveLibは、ライブラリ、保存場所、起動ファイル、プレイ履歴、タグ、メモを端末内に保存します。これらを評価サーバーへ送信しません。\n\n'
          '利用者が評価共有へ同意した場合、VNDB作品ID、評価点、任意のコメント、更新日時、ランダム生成した匿名端末識別子の不可逆ハッシュを保存します。送信制限と不正対策のため、ネットワーク情報は生値を保存せず不可逆なHMAC値として短期的な回数判定に利用します。\n\n'
          '公開コメントには個人情報を書かないでください。設定の「共有済み評価をサーバーから削除」から、この端末が共有した評価とコメントを削除できます。端末内データは削除されません。\n\n'
          '画像取得時には画像配信元へIPアドレス、要求先URL等が伝わる場合があります。法令対応、障害調査、不正利用防止に必要な範囲を除き、取得情報を第三者へ販売しません。\n\n最新版は公式サイトのプライバシーポリシーをご確認ください。',
          style: TextStyle(height: 1.6),
        ),
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: () => _openExternal(context, privacyPolicyUrl),
        icon: const Icon(Icons.open_in_new),
        label: const Text('公式サイトで最新版を開く'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('利用規約'),
    content: const SizedBox(
      width: 700,
      child: SingleChildScrollView(
        child: SelectableText(
          '最終更新：2026年9月5日\n\n'
          '運営者：おかりん研究室\nお問い合わせ：okarin.novelab@gmail.com\n\n'
          'NoveLibは、利用者が正当に利用できるゲームを整理・起動・記録するための管理ソフトウェアです。ゲーム本体や作品画像等の権利は各権利者に帰属します。\n\n'
          '公開コメントでは、個人情報、嫌がらせ、差別、違法行為の助長、スパム、権利侵害となる内容を投稿しないでください。重大なネタバレは通報対象となる場合があります。運営者は通報その他の事情によりコメントを非表示にできます。\n\n'
          'R18作品の表示は18歳以上で、居住地域の法令により閲覧可能な利用者だけが使用してください。\n\n'
          '本ソフトウェアはプレビュー版であり、完全な作品検出、画像取得、データ保全、継続的なオンライン提供を保証しません。重要な記録は設定から定期的にバックアップしてください。\n\n本規約は日本法に準拠します。',
          style: TextStyle(height: 1.6),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}

class LicenseTextDialog extends StatefulWidget {
  const LicenseTextDialog({super.key, required this.name});
  final String name;
  @override
  State<LicenseTextDialog> createState() => _LicenseTextState();
}

class _LicenseTextState extends State<LicenseTextDialog> {
  late final text = rootBundle.loadString(
    'assets/catalog/LICENSE-${widget.name}.txt',
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.name} ライセンス全文'),
    content: SizedBox(
      width: 760,
      height: responsiveDialogHeight(context, 500),
      child: FutureBuilder<String>(
        future: text,
        builder: (c, s) => s.hasError
            ? const Text('同梱ライセンスを読み込めませんでした。')
            : !s.hasData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: SelectableText(s.data!)),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}
