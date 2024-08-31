import 'package:anynote/MainController.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/archiveView.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WideHome extends StatelessWidget {
  WideHome({Key? key}) : super(key: key);

  final RxInt currentPageIndex = 0.obs;

  ArchieveList archivedNotes = ArchieveList(isArchive: true);
  ArchieveList unarchivedNotes = ArchieveList(isArchive: false);

  @override
  Widget build(BuildContext context) {
    Get.find<MainController>().initData();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "AnyNote",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(Icons.note, "Notes", 0),
                      _buildMenuItem(Icons.archive, "Archived", 1),
                      _buildMenuItem(Icons.tag, "Tags", 2),
                      _buildMenuItem(Icons.settings, "Settings", 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Obx(() => IndexedStack(
                  index: currentPageIndex.value,
                  children: [
                    _buildMainContent('Notes'),
                    _buildMainContent('Archived'),
                    _buildMainContent('Tags'),
                    _buildMainContent('Settings'),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: currentPageIndex.value == index
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(icon,
                color: currentPageIndex.value == index ? Colors.blue : null),
            title: Text(title,
                style: TextStyle(
                    color:
                        currentPageIndex.value == index ? Colors.blue : null)),
            selected: currentPageIndex.value == index,
            onTap: () => currentPageIndex.value = index,
          ),
        ));
  }

  Widget _buildMainContent(String pageName) {
    switch (pageName) {
      case 'Notes':
        return Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ArchieveList()),
        );
      case 'Archived':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ArchieveList(isArchive: true),
            ),
          ),
        );
      case 'Tags':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TagList(),
            ),
          ),
        );
      case 'Settings':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const SettingView(),
            ),
          ),
        );
      default:
        return const Center(
            child: Text('Unknown Page', key: ValueKey('Unknown')));
    }
  }
}
