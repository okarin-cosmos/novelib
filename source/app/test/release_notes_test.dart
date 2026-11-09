import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/settings/release_notes_dialog.dart';

void main() {
  test('version and patch notes match the package version', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: $appReleaseVersion+'),
    );
    expect(
      File(releaseNotesAsset).readAsStringSync(),
      contains('NoveLib v$appReleaseVersion'),
    );
  });

  for (final width in [360.0, 1000.0]) {
    testWidgets('offline patch notes fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final notes = await tester.runAsync(
        () => rootBundle.loadString(releaseNotesAsset),
      );
      expect(notes, contains('NoveLib v$appReleaseVersion'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReleaseNotesDialog(loadNotes: () async => notes!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('変更履歴 — v$appReleaseVersion'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
