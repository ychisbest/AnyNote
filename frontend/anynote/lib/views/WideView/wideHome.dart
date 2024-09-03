import 'package:anynote/MainController.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:anynote/views/setting_view.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WideHome extends StatelessWidget {
  WideHome({Key? key}) : super(key: key);

  final RxInt currentPageIndex = 0.obs;
  final MainController c = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Get.to(()=>EditNotePage());
        },
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    "AnyNote",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildMenuItem(Icons.note_outlined, "Notes", 0),
                      _buildMenuItem(Icons.archive_outlined, "Archived", 1),
                      _buildMenuItem(Icons.local_offer_outlined, "Tags", 2),
                      _buildMenuItem(Icons.settings_outlined, "Settings", 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Builder(
              builder: (context) {
                return Obx(() =>c.isLoading.isTrue?const Center(child: CircularProgressIndicator()):
                IndexedStack(
                  index: currentPageIndex.value,
                  children: [
                    _buildMainContent('Notes'),
                    _buildMainContent('Archived'),
                    _buildMainContent('Tags'),
                    _buildMainContent('Settings'),
                  ],
                ));
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    return Obx(() => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(icon,
              color: currentPageIndex.value == index
                  ? Colors.black87
                  : Colors.black54,
              size: 20),
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

  Widget _buildMainContent(String pageName) {
    switch (pageName) {
      case 'Notes':
        return Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
