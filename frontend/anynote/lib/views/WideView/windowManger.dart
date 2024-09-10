import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

setwindow() async {
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setSize(const Size(500, 900));
    windowManager.center();
    // //windowManager.setAlwaysOnTop(true);

    windowManager.setTitle('AnyNote');
  }
}
