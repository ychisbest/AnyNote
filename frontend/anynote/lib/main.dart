import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:anynote/GlobalConfig.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/HeatMap.dart';
import 'package:anynote/views/aiMemo.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/archiveView.dart';
import 'package:anynote/views/date_view.dart';
import 'package:anynote/views/login.dart';
import 'package:anynote/views/random_view.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'MainController.dart';
import 'note_api_service.dart';
import 'views/WideView/windowManger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    setwindow();
  }

  // 初始化 Hive
  await Hive.initFlutter();

  // 注册 NoteItem 的适配器
  Hive.registerAdapter(NoteItemAdapter());

  await Hive.openBox<NoteItem>('offline_notes').catchError((e) {
    print("file locked");
    exit(0);
  });

  await GlobalConfig.init();

  Get.put(MainController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        home: GlobalConfig.isLoggedIn ? const HomePage() : const LoginPage());
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
        return const LoginPage();
      }
      // if (Get.width > 600) {
      //   resizeableHome ??= WideHome();
      //   return resizeableHome!;
      // }

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
    const scaffoldBackgroundColor = Color(0xFFF6F3EE);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: scaffoldBackgroundColor,
        systemNavigationBarColor: scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Obx(() {
            if (c.isLoading.value) {
              return const Row(
                children: [
                  Text("AnyNote"),
                  SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                      height: 15, width: 15, child: CircularProgressIndicator())
                ],
              );
            } else {
              return const Text(
                "AnyNote",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              );
            }
          }),
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
                Get.to(() => Archiveview());
              },
              child: const Icon(
                Icons.archive_outlined,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        drawer: const BuildDrawer(),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F4ED),
                  Color(0xFFEFF4F6),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14D7C6B2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -40,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1A98B7A8),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white70),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: const ArchiveList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1F6E5D),
            foregroundColor: Colors.white,
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const EditNotePage()));
            },
            icon: const Icon(Icons.add),
            label: const Text("New Note"),
          );
        }),
      ),
    );
  }
}

class SafeScrollAnimation {
  final ScrollController scrollController;
  bool _isMounted = true;

  SafeScrollAnimation(this.scrollController);

  void dispose() {
    _isMounted = false;
  }

  void animateWithBounce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted || !scrollController.hasClients) return;

      final targetPosition = scrollController.position.maxScrollExtent;

      _animateTo(0 - 30, const Duration(milliseconds: 500), Curves.easeInOut)
          .then((_) => _animateTo(targetPosition + 30,
              const Duration(milliseconds: 1000), Curves.easeInOut))
          .then((_) => _animateTo(targetPosition,
              const Duration(milliseconds: 500), Curves.easeOutBack));
    });
  }

  Future<void> _animateTo(double offset, Duration duration, Curve curve) async {
    if (!_isMounted || !scrollController.hasClients) return;
    return scrollController.animateTo(offset, duration: duration, curve: curve);
  }
}

class BuildDrawer extends StatefulWidget {
  const BuildDrawer({super.key});

  @override
  _BuildDrawerState createState() => _BuildDrawerState();
}

class _BuildDrawerState extends State<BuildDrawer> {
  late ScrollController _scrollController;
  late SafeScrollAnimation _scrollAnimation;

  MainController c = Get.find<MainController>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollAnimation = SafeScrollAnimation(_scrollController);
    _scrollAnimation.animateWithBounce();
  }

  @override
  void dispose() {
    _scrollAnimation.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _scrollController,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                scrollbars: false,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                child: Container(
                  height: 100,
                  width: 550,
                  padding: const EdgeInsets.all(10),
                  child: const RepaintBoundary(
                      child: GithubHeatmap(
                    cellSize: 10,
                  )),
                ),
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
            leading: const Icon(Icons.date_range),
            title: const Text('Browse by date'),
            onTap: () async {
              Get.back();
              Get.to(() => const Browser());
            },
          ),
          ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('Random'),
            onTap: () async {
              Get.back();
              Get.to(() => RandomView());
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
          Obx(() {
            if (c.tags.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(c.tags.length, (index) {
                  return ActionChip(
                    label: Text(c.tags[index], style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    pressElevation: 0,
                    onPressed: () async {
                      Get.back();
                      Get.to(() => NoteTagListView(tag: c.tags[index]));
                    },
                  );
                }),
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Help you recall'),
            onTap: () async {
              Get.back();
              Get.to(() => const Aimemo());
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
