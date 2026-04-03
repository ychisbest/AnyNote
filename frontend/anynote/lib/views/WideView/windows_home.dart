import 'dart:ui';

import 'package:anynote/MainController.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/HeatMap.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/date_view.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:anynote/widgets/QuickNoteInput.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WindowsWideHome extends StatelessWidget {
  WindowsWideHome({super.key});

  final RxInt currentPageIndex = 0.obs;
  final MainController c = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    const scaffoldBackground = Color(0xFFF6F3EE);
    return Scaffold(
      backgroundColor: scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const EditNotePage());
        },
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
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
              child: Obx(() {
                if (c.isLoading.isTrue) {
                  return const Center(child: CircularProgressIndicator());
                }
                return IndexedStack(
                  index: currentPageIndex.value,
                  children: [
                    _buildNotesWide(),
                    _buildMainContent(const Browser()),
                    const ArchiveList(isArchive: true),
                    _buildMainContent(TagList()),
                    _buildMainContent(const SettingView()),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0),
            child: Text(
              "AnyNote",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(Icons.today_outlined, "Today", 0),
                _buildMenuItem(Icons.calendar_today_outlined, "Dates", 1),
                _buildMenuItem(Icons.search, "Search", 2),
                _buildMenuItem(Icons.local_offer_outlined, "Tags", 3),
                _buildMenuItem(Icons.settings_outlined, "Settings", 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    return Obx(() => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: Icon(
            icon,
            color: currentPageIndex.value == index
                ? Colors.black87
                : Colors.black54,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: currentPageIndex.value == index
                  ? Colors.black87
                  : Colors.black54,
              fontWeight: currentPageIndex.value == index
                  ? FontWeight.w600
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          selected: currentPageIndex.value == index,
          onTap: () => currentPageIndex.value = index,
        ));
  }

  Widget _buildNotesWide() {
    const double activityCellSize = 14;
    final double activityHeight =
        activityCellSize * 7 + GithubHeatmap.weekLabelHeight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: const ArchiveList(),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 360,
            child: Column(
              children: [
                Expanded(

                    child: const QuickNoteInput(expand: true),

                
                ),
                const SizedBox(height: 16),
                _buildPanelCard(
                  title: "Activity",
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: activityHeight,
                      child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          scrollbars: true,
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 820,
                            height: activityHeight,
                            child: const GithubHeatmap(
                              cellSize: activityCellSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SizedBox(
            height: constraints.maxHeight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildPanelCard(
                  child: child,
                  expandChild: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelCard({
    required Widget child,
    String? title,
    bool expandChild = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E0D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            if (title != null) const SizedBox(height: 10),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
