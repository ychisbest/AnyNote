import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/HeatMap.dart';
import 'package:anynote/views/WideView/wideHome.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/archiveView.dart';
import 'package:anynote/views/login.dart';
import 'package:anynote/views/random_view.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'Extension.dart';
import 'MainController.dart';
import 'views/WideView/windowManger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    setwindow();
  }

  await GlobalConfig.init();
  Get.put(MainController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'AnyNote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: kIsWeb ? "" : "MyCustomfont",
        ),
        home: GlobalConfig.isLoggedIn ? const HomePage() : LoginPage());
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
  Widget? resizeableHome;

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
    return LayoutBuilder(builder: (context, constraints) {
      if (!GlobalConfig.isLoggedIn) {
        return LoginPage();
      }
      if (Get.width > 600) {
        resizeableHome ??= WideHome();
        return resizeableHome!;
      }

      return NerrowHome();
    });
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

class NerrowHome extends StatelessWidget {
  NerrowHome({super.key});
  final MainController c = Get.put(MainController());
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
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Get.to(()=>RandomView());

              },
              child: const Icon(Icons.casino),
            ),
          ],
        ),
        drawer: const _buildDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Obx(() => c.isLoading.isTrue
                    ? const Center(child: CircularProgressIndicator())
                    : ArchieveList()),
              ),
            ],
          ),
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
}

class _buildDrawer extends StatelessWidget {
  const _buildDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();

    // 使用 addPostFrameCallback 确保滚动操作在 widget 构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });

    return Drawer(
      child: Column(
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
                child: Text(
              'AnyNote',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            )),
          ),


          Scrollbar(
            controller: scrollController,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                scrollbars: false,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Container(height: 90,
                  width: 500,
                  padding: const EdgeInsets.all(10),
                  child: GithubHeatmap(),),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('Archived & Search'),
            onTap: () async {
              Get.back();
              Get.to(() => Archiveview());
            },
          ),
          ListTile(
            leading: const Icon(Icons.tag_sharp),
            title: const Text('Tags'),
            onTap: () async {
              Get.back();
              Get.to(() => TagList());
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_added_outlined),
            title: const Text('Tagging notes'),
            onTap: () async {
              Get.back();
              Get.to(() => const AddTagListView());
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Setting'),
            onTap: () async {
              Get.back();
              Get.to(() => const SettingView());
            },
          ),
        ],
      ),
    );
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
