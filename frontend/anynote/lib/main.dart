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
import 'package:anynote/widgets/QuickNoteInput.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'MainController.dart';
import 'app_snackbar.dart';
import 'note_api_service.dart';
import 'route_observer.dart';
import 'views/WideView/windowManger.dart';
import 'views/WideView/windows_home.dart';

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
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorObservers: [routeObserver],
      home: GlobalConfig.isLoggedIn ? const HomePage() : const LoginPage(),
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!GlobalConfig.isLoggedIn) {
          return const LoginPage();
        }
        final bool isWindowsWide =
            !kIsWeb && Platform.isWindows && constraints.maxWidth >= 1000;
        if (isWindowsWide) {
          resizeableHome ??= WindowsWideHome();
          return resizeableHome!;
        }

        return NerrowHome();
      },
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
                  SizedBox(width: 10),
                  SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(),
                  ),
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
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                c.exitSelectionMode();
                Get.to(() => Archiveview());
              },
              child: const Icon(Icons.search, color: Colors.black87),
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
                colors: [Color(0xFFF8F4ED), Color(0xFFEFF4F6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuickNoteInput(),
                Expanded(child: const ArchiveList()),
              ],
            ),
          ),
        ),
        floatingActionButton: Obx(() {
          if (c.isSelectionMode.value) {
            return const SizedBox.shrink();
          }
          return Builder(
            builder: (context) {
              return FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1F6E5D),
                foregroundColor: Colors.white,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const EditNotePage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("New Note"),
              );
            },
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
          .then(
            (_) => _animateTo(
              targetPosition + 30,
              const Duration(milliseconds: 1000),
              Curves.easeInOut,
            ),
          )
          .then(
            (_) => _animateTo(
              targetPosition,
              const Duration(milliseconds: 500),
              Curves.easeOutBack,
            ),
          );
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
    const drawerBackground = Color(0xFFF9F6F1);
    const cardColor = Colors.white;
    const accentColor = Color(0xFF2D6B6A);
    const textColor = Color(0xFF3E3A34);
    const mutedTextColor = Color(0xFF8B8378);

    return Drawer(
      backgroundColor: drawerBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E3DA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AnyNote',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'A calm space for your notes',
                        style: TextStyle(fontSize: 12, color: mutedTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAE3D8)),
                    ),
                    child: Scrollbar(
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
                              height: 7 * 10 + GithubHeatmap.weekLabelHeight + 12,
                              width: 550,
                              padding: const EdgeInsets.all(6),
                              child: const RepaintBoundary(
                                child: GithubHeatmap(cellSize: 10),
                              ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionLabel('Library'),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    title: 'Search',
                    onTap: () async {
                      Get.back();
                      Get.to(() => Archiveview());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.date_range,
                    title: 'Browse by date',
                    onTap: () async {
                      Get.back();
                      Get.to(() => const Browser());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.casino,
                    title: 'Random',
                    onTap: () async {
                      Get.back();
                      Get.to(() => RandomView());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.tag_sharp,
                    title: 'Tags',
                    onTap: () async {
                      Get.back();
                      Get.to(() => TagList());
                    },
                  ),
                  Obx(() {
                    if (c.tags.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE7E0D6)),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(c.tags.length, (index) {
                          return ActionChip(
                            label: Text(
                              c.tags[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            pressElevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE0D8CC)),
                            ),
                            onPressed: () async {
                              Get.back();
                              Get.to(() => NoteTagListView(tag: c.tags[index]));
                            },
                          );
                        }),
                      ),
                    );
                  }),
                  _buildSectionLabel('Tools'),
                  _buildDrawerItem(
                    icon: Icons.camera,
                    title: 'Help you recall',
                    onTap: () async {
                      Get.back();
                      Get.to(() => const Aimemo());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_added_outlined,
                    title: 'Tagging notes',
                    onTap: () async {
                      Get.back();
                      Get.to(() => const AddTagListView());
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSectionLabel('Settings'),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Setting',
                    onTap: () async {
                      Get.back();
                      Get.to(() => const SettingView());
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9A9083),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EEE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF2D6B6A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E3A34),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFB0A79C),
                ),
              ],
            ),
          ),
        ),
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
