import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

setwindow() async {
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setSize(const Size(1280, 800));
    windowManager.center();
    // //windowManager.setAlwaysOnTop(true);

    windowManager.setTitle('AnyNote');
  }
}
