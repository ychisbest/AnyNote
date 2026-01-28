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
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isArchive) _buildSearchBar(),
        if (widget.isArchive) _buildTagFilters(),
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
        controller: _searchController,
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

  Widget _buildTagFilters() {
    return Obx(() {
      final tags = controller.tags;
      if (tags.isEmpty) {
        return const SizedBox.shrink();
      }

      final query = _searchController.text;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              FilterChip(
                label: Text(
                  '#$tag',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: _queryHasTag(query, tag),
                onSelected: (_) => _toggleTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                visualDensity:
                    const VisualDensity(horizontal: -1, vertical: -2),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                selectedColor: Colors.blue.withOpacity(0.15),
                checkmarkColor: Colors.blue,
              ),
          ],
        ),
      );
    });
  }

  void _onSearchChanged(String query) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      controller.updateFilter(query);
    });
  }

  void _toggleTag(String tag) {
    final query = _searchController.text;
    final nextQuery = _queryHasTag(query, tag)
        ? _removeTagFromQuery(query, tag)
        : _addTagToQuery(query, tag);
    _setSearchQuery(nextQuery);
  }

  bool _queryHasTag(String query, String tag) {
    final reg = RegExp(r'(^|\s)#' + RegExp.escape(tag) + r'(?=\s|$)');
    return reg.hasMatch(query);
  }

  String _addTagToQuery(String query, String tag) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return '#$tag ';
    }
    return '$normalized #$tag ';
  }

  String _removeTagFromQuery(String query, String tag) {
    final reg = RegExp(r'(^|\s)#' + RegExp.escape(tag) + r'(?=\s|$)');
    final cleaned = query.replaceAll(reg, ' ');
    final normalized = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? '' : '$normalized ';
  }

  void _setSearchQuery(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _onSearchChanged(query);
  }
}
