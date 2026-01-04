import 'dart:async';
import 'dart:ui';
import 'package:anynote/widgets/NoteList.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anynote/MainController.dart';

class ArchiveList extends StatefulWidget {
  const ArchiveList({super.key, this.isArchive = false});

  final bool isArchive;

  @override
  // ignore: library_private_types_in_public_api
  _ArchiveListState createState() => _ArchiveListState();
}

class _ArchiveListState extends State<ArchiveList> {
  final MainController controller = Get.find<MainController>();
  final ScrollController sc = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller.updateFilter('');
  }

  @override
  void dispose() {
    //controller.updateFilter('');
    sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(widget.isArchive)_buildSearchBar(),
        Expanded(
          child: Obx(() {
            var archivedNotes = widget.isArchive
                ? controller.filteredArchivedNotes
                : controller.filteredUnarchivedNotes;
            return Scrollbar(
              controller: sc,
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  scrollbars: false,
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    try {
                      await controller.fetchNotes();
                    } catch (e) {
                      // Handle error, e.g., show a SnackBar
                    }
                  },
                  child: BuildNoteList(archivedNotes, widget.isArchive,sc:sc),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        style: const TextStyle(fontSize: 13),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(0.85),
          filled: true,
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderSide: const BorderSide(width: 1, color: Colors.black12),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 1, color: Colors.black38),
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 1, color: Colors.black12),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      controller.updateFilter(query);
    });
  }
}
