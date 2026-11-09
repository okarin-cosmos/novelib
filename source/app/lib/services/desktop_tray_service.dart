import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopTrayService with WindowListener, TrayListener {
  bool _enabled = false;
  bool _initialized = false;
  bool _exiting = false;

  bool get enabled => _enabled;

  Future<void> initialize({required bool enabled}) async {
    if (!Platform.isWindows) return;
    if (!_initialized) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initialized = true;
    }
    await setEnabled(enabled);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!Platform.isWindows) return;
    if (value) {
      final iconPath = p.join(
        p.dirname(Platform.resolvedExecutable),
        'data',
        'flutter_assets',
        'windows',
        'runner',
        'resources',
        'app_icon.ico',
      );
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('NoveLib');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show_window', label: 'NoveLibを表示'),
            MenuItem.separator(),
            MenuItem(key: 'exit_app', label: '終了'),
          ],
        ),
      );
      await windowManager.setPreventClose(true);
    } else {
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
    }
  }

  Future<void> showWindow() async {
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> exitApplication() async {
    _exiting = true;
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  void dispose() {
    if (!_initialized) return;
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onWindowClose() async {
    if (_exiting || !_enabled) return;
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  @override
  void onTrayIconMouseDown() async {
    await showWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      showWindow();
    } else if (menuItem.key == 'exit_app') {
      exitApplication();
    }
  }
}
