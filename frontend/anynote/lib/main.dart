import 'dart:io';
import 'dart:async';

import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/WideView/wideHome.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/archiveView.dart';
import 'package:anynote/views/login.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'MainController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setSize(const Size(1200, 900));
    windowManager.center();
    //windowManager.setAlwaysOnTop(true);
    windowManager.setTitle('记事本');
  }

  await GlobalConfig.init();
  Get.put(MainController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  WideHome? wideHome;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'AnyNote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
          fontFamily: "MyCustomfont",
        ),
        home: LayoutBuilder(builder: (context, constraints) {
          if (!GlobalConfig.isLoggedIn) {
            return LoginPage();
          }
          if (Get.width > 600) {
            wideHome ??= WideHome();
            return KeepAliveWrapper(child: wideHome!);
          }

          return const HomePage();
        }));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final MainController c = Get.put(MainController());
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    c.initData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: scaffoldBackgroundColor,
        systemNavigationBarColor: scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AnyNote"),
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(() => const SettingView());
                },
                icon: const Icon(Icons.settings)),
            IconButton(
                onPressed: () {
                  Get.to(() => Archiveview());
                },
                icon: const Icon(Icons.archive_outlined))
          ],
        ),
        body: SafeArea(
          child: Obx(() => c.isLoading.isTrue
              ? const Center(child: CircularProgressIndicator())
              : ArchieveList()),
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                  context, MaterialPageRoute(builder: (c) => EditNotePage()));
            },
            child: const Icon(Icons.add),
          );
        }),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null) {
        final timeDifference = DateTime.now().difference(_lastPausedTime!);
        if (timeDifference.inMinutes >= 2) {
          final MainController c = Get.find<MainController>();
          c.fetchNotes();
        }
      }
    }
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
