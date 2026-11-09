import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/features/records/data_transfer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('匿名評価トークンはバックアップに含めず復元先の値を保持する', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final destination = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(destination.close);
    await source.writeSetting('appearance.theme', 'light');
    await source.writeSetting('cloud.reviewAnonymousToken', 'source-secret');
    await destination.writeSetting(
      'cloud.reviewAnonymousToken',
      'destination-secret',
    );

    final backup = await LibraryBackup.capture(source);
    final encoded = backup.encode();
    expect(encoded, isNot(contains('source-secret')));
    expect(encoded, isNot(contains('cloud.reviewAnonymousToken')));

    await backup.restore(destination);
    expect(await destination.readSetting('appearance.theme'), 'light');
    expect(
      await destination.readSetting('cloud.reviewAnonymousToken'),
      'destination-secret',
    );
  });
}
