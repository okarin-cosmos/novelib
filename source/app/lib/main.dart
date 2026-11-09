import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'catalog/catalog_database.dart';
import 'database/app_database.dart';
import 'features/settings/help_dialogs.dart';
import 'services/cover_image_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final catalog = await CatalogDatabase.open();
  final database = AppDatabase.open();
  final showWelcome = await needsWelcome(database);
  await CoverImageCache.instance.loadFailureHistory();
  runApp(
    ChronovelApp(
      database: database,
      catalog: catalog,
      showWelcome: showWelcome,
      enableDesktopIntegration: true,
    ),
  );
}
