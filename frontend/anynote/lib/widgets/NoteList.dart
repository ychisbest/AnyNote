import 'package:anynote/Extension.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../views/markdown_render/markdown_render.dart';

double maxNoteItemHeight = 300; // Maximum height for note items

class NoteItemWidget extends StatelessWidget {
  final MainController controller;
  final NoteItem item;
  final bool isArchive;

  const NoteItemWidget({
    super.key,
    required this.controller,
    required this.item,
    required this.isArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isHovered = false.obs;
    final theme = Theme.of(context);
    final accentBase = darkenColor(item.color.toFullARGB(), 0.06);
    final accentStrong = darkenColor(item.color.toFullARGB(), 0.2);
    final outlineColor = theme.colorScheme.outlineVariant.withOpacity(0.6);
    
    return Listener(
      onPointerDown: (_) => isHovered.value = true,
      onPointerUp: (_) => isHovered.value = false,
      onPointerCancel: (_) => isHovered.value = false,
      child: Obx(() => Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: outlineColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isHovered.value ? 6 : 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentStrong,
                      accentBase,
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
            ),
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onTap: () async {
                await Get.to(() => EditNotePage(item: item));
              },
              onLongPress: () async {
                var res = await _showOptionsDialog(context, item, controller, isArchive);
                if (res != null) _handleOption(res, item, controller, isArchive);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              intl.DateFormat('HH:mm').format(item.createTime),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LimitedBox(
                          maxHeight: maxNoteItemHeight,
                          child: Obx(() => MarkdownRenderer(
                            fontsize: controller.fontSize.value,
                            data: item.content?.trimRight() ?? "",
                          )),
                        ),
                      ],
                    ),
                    if (item.isTopMost && !isArchive)
                      PositionedDirectional(
                        end: 0,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 12,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Future<String?> _showOptionsDialog(BuildContext context, NoteItem item, MainController controller, bool isArchive) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Options',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  item.isTopMost ? Icons.star : Icons.star_border,
                  color: item.isTopMost ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  item.isTopMost ? 'Remove from Top' : 'Add to Top',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop('toggleTopMost'),
              ),
              if (!isArchive)
                ListTile(
                  leading: const Icon(Icons.arrow_upward),
                  title: const Text("Move Up", style: TextStyle(fontSize: 16)),
                  onTap: () => Navigator.of(context).pop('up'),
                ),
              if (!isArchive)
                ListTile(
                  leading: const Icon(Icons.arrow_downward),
                  title: const Text("Move Down", style: TextStyle(fontSize: 16)),
                  onTap: () => Navigator.of(context).pop('down'),
                ),
              ListTile(
                leading: Icon(
                  item.isArchived ? Icons.unarchive : Icons.archive,
                  color: Colors.blue,
                ),
                title: Text(
                  item.isArchived ? 'Unarchive' : 'Archive',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop('toggleArchive'),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('Copy', style: TextStyle(fontSize: 16)),
                onTap: () => Navigator.of(context).pop('copy'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(fontSize: 16)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleOption(String action, NoteItem item, MainController controller, bool isArchive) {
    switch (action) {
      case 'toggleTopMost':
        item.isTopMost = !item.isTopMost;
        controller.updateNote(item.id!, item);
        break;
      case 'toggleArchive':
        if (isArchive) {
          controller.unarchiveNote(item.id!);
        } else {
          controller.archiveNote(item.id!);
        }
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: item.content ?? ""));
        break;
      case 'delete':
        controller.deleteNote(item.id!);
        break;
      case 'up':
        var list = controller.filteredUnarchivedNotes;
        int index = list.indexWhere((obj) => obj.id == item.id);
        if (index > 0) {
          var temp = list[index - 1];
          list[index - 1] = list[index];
          list[index] = temp;
        }
        controller.updateIndex(list);
        break;
      case 'down':
        var list = controller.filteredUnarchivedNotes;
        int index = list.indexWhere((obj) => obj.id == item.id);
        if (index > -1 && index < list.length - 1) {
          var temp = list[index + 1];
          list[index + 1] = list[index];
          list[index] = temp;
        }
        controller.updateIndex(list);
        break;
    }
  }
}

Widget BuildNoteList(List<NoteItem> archivedNotes, bool isArchive,
    {ScrollController? sc}) {
  List<NoteItem> sortNotesByDateDesc(List<NoteItem> items) {
    final sorted = List<NoteItem>.from(items);
    sorted.sort((a, b) => b.createTime.compareTo(a.createTime));
    return sorted;
  }

  DateTime normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  List<_NoteListEntry> buildGroupedEntries(List<NoteItem> items) {
    final entries = <_NoteListEntry>[];
    if (items.isEmpty) {
      return entries;
    }

    DateTime? currentDate;
    final buffer = <NoteItem>[];

    void flushGroup(DateTime dateKey, List<NoteItem> notes) {
      entries.add(_NoteListEntry.header(
          intl.DateFormat('yyyy-MM-dd').format(dateKey)));
      for (final note in notes) {
        entries.add(_NoteListEntry.item(note));
      }
    }

    for (final note in items) {
      final dateKey = normalizeDate(note.createTime);
      if (currentDate == null || currentDate != dateKey) {
        if (currentDate != null && buffer.isNotEmpty) {
          flushGroup(currentDate, List<NoteItem>.from(buffer));
          buffer.clear();
        }
        currentDate = dateKey;
      }
      buffer.add(note);
    }

    if (currentDate != null && buffer.isNotEmpty) {
      flushGroup(currentDate, List<NoteItem>.from(buffer));
    }

    return entries;
  }

  Widget buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 18, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(NoteItem item) {
    final MainController controller = Get.find<MainController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: NoteItemWidget(
        key: ValueKey(item.id),
        controller: controller,
        item: item,
        isArchive: isArchive,
      ),
    );
  }

  final topmostItems = archivedNotes.where((item) => item.isTopMost).toList();
  final normalItems = archivedNotes.where((item) => !item.isTopMost).toList();
  final groupedEntries = buildGroupedEntries(sortNotesByDateDesc(normalItems));

  return CustomScrollView(
    controller: sc,
    physics: const BouncingScrollPhysics(),
    slivers: [
  if (topmostItems.isNotEmpty)
        SliverToBoxAdapter(child: buildHeader("Pinned")),
      SliverList.builder(
        addAutomaticKeepAlives: false,
        itemCount: topmostItems.length,
        itemBuilder: (context, index) {
          return buildItem(topmostItems[index]);
        },
      ),
      SliverList.builder(
        addAutomaticKeepAlives: false,
        itemCount: groupedEntries.length,
        itemBuilder: (context, index) {
          final entry = groupedEntries[index];
          if (entry.isHeader) {
            return buildHeader(entry.title ?? "");
          }
          return buildItem(entry.item!);
        },
      ),
      const SliverToBoxAdapter(
          child: SizedBox(
        height: 50,
      ))
    ],
  );
}

class _NoteListEntry {
  final bool isHeader;
  final String? title;
  final NoteItem? item;

  const _NoteListEntry._({required this.isHeader, this.title, this.item});

  factory _NoteListEntry.header(String title) {
    return _NoteListEntry._(isHeader: true, title: title);
  }

  factory _NoteListEntry.item(NoteItem item) {
    return _NoteListEntry._(isHeader: false, item: item);
  }
}
