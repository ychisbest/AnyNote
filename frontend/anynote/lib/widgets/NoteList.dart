import 'package:anynote/Extension.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../views/markdown_render/markdown_render.dart';

double maxNoteItemHeight = 180; // Maximum height for note items
const double _noteFadeHeight = 44;

class NoteItemWidget extends StatefulWidget {
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
  State<NoteItemWidget> createState() => _NoteItemWidgetState();
}

class _NoteItemWidgetState extends State<NoteItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = darkenColor(widget.item.color.toFullARGB(), 0.18);

    return Obx(() {
      final controller = widget.controller;
      final item = widget.item;
      final isArchive = widget.isArchive;
      final isSelectionMode = controller.isSelectionMode.value;
      final isSelected =
          item.id != null && controller.selectedNoteIds.contains(item.id);
      final baseRowColor = isSelected
          ? darkenColor(item.color.toFullARGB(),0.05)
          : item.color.toFullARGB();
      final rowColor =
          _isHovered ? darkenColor(baseRowColor, 0.03) : baseRowColor;
      const horizontalPadding = 12.0;

      final content = Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Table(
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            TableRow(
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.fill,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: dividerColor, width: 2),
                      ),
                    ),
                    margin: const EdgeInsets.only(right:horizontalPadding),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Text(
                        intl.DateFormat('HH:mm').format(item.createTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (controller.fontSize.value / 16) * 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => NoteContentPreview(
                    content: item.content?.trimRight() ?? "",
                    fontSize: controller.fontSize.value.toDouble(),
                    maxHeight: maxNoteItemHeight,
                    fadeHeight: _noteFadeHeight,
                    fadeColor: rowColor,
                    iconColor:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final selectionIndicator = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.circle_outlined,
          size: 12,
          color: isSelected ? Colors.white : theme.colorScheme.outlineVariant,
        ),
      );

      final contentWithIndicator = isSelectionMode
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: content),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: selectionIndicator,
                ),
              ],
            )
          : content;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: rowColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.transparent,
            highlightColor: darkenColor(rowColor, 0.06).withOpacity(0.12),
            splashColor: darkenColor(rowColor, 0.1).withOpacity(0.25),
            splashFactory: InkRipple.splashFactory,
            enableFeedback: true,
            onHover: (hovering) {
              if (_isHovered != hovering) {
                setState(() {
                  _isHovered = hovering;
                });
              }
            },
            onTap: () async {
              if (controller.isSelectionMode.value) {
                if (item.id != null) {
                  controller.toggleSelection(item.id!);
                }
                return;
              }
              await Get.to(() => EditNotePage(item: item));
            },
            onLongPress: () async {
              if (controller.isSelectionMode.value) {
                if (item.id != null) {
                  controller.toggleSelection(item.id!);
                }
                return;
              }
              var res = await _showOptionsDialog(
                context,
                item,
                controller,
                isArchive,
              );
              if (res != null) _handleOption(res, item, controller, isArchive);
            },
            child: contentWithIndicator,
          ),
        ),
      );
    });
  }

  Future<String?> _showOptionsDialog(
    BuildContext context,
    NoteItem item,
    MainController controller,
    bool isArchive,
  ) {
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
                leading: const Icon(Icons.checklist),
                title: const Text(
                  'Multi-select',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop('multiSelect'),
              ),
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
                  title: const Text(
                    "Move Down",
                    style: TextStyle(fontSize: 16),
                  ),
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

  void _handleOption(
    String action,
    NoteItem item,
    MainController controller,
    bool isArchive,
  ) {
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
      case 'multiSelect':
        controller.enterSelectionMode(initialId: item.id);
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

class NoteContentPreview extends StatefulWidget {
  final String content;
  final double fontSize;
  final double maxHeight;
  final double fadeHeight;
  final Color fadeColor;
  final Color iconColor;

  const NoteContentPreview({
    super.key,
    required this.content,
    required this.fontSize,
    required this.maxHeight,
    required this.fadeHeight,
    required this.fadeColor,
    required this.iconColor,
  });

  @override
  State<NoteContentPreview> createState() => _NoteContentPreviewState();
}

class _NoteContentPreviewState extends State<NoteContentPreview> {
  double _contentHeight = 0;

  void _handleSizeChanged(Size size) {
    if (!mounted) return;
    if (size.height != _contentHeight) {
      setState(() {
        _contentHeight = size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildContent() {
      return MarkdownRenderer(
        fontsize: widget.fontSize.toInt(),
        data: widget.content,
      );
    }

    final isOverflowing = _contentHeight > widget.maxHeight + 0.5;

    return Stack(
      children: [
        if (isOverflowing)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                child: buildContent(),
              ),
            ),
          )
        else
          buildContent(),
        if (isOverflowing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: widget.fadeHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.fadeColor.withOpacity(0),
                      widget.fadeColor.withOpacity(0.65),
                      widget.fadeColor,
                    ],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          ),
        Offstage(
          offstage: true,
          child: MeasureSize(
            onChange: _handleSizeChanged,
            child: buildContent(),
          ),
        ),
      ],
    );
  }
}

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final size = renderObject.size;
        if (size != _oldSize) {
          _oldSize = size;
          widget.onChange(size);
        }
      }
    });
    return widget.child;
  }
}


Widget BuildNoteList(
  List<NoteItem> archivedNotes,
  bool isArchive, {
  ScrollController? sc,
}) {
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
      entries.add(
        _NoteListEntry.header(intl.DateFormat('yyyy-MM-dd').format(dateKey)),
      );
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

  Widget buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: title == "Pinned"
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
      ),
    );
  }

  Widget buildItem(NoteItem item) {
    final MainController controller = Get.find<MainController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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

  final MainController controller = Get.find<MainController>();

  List<NoteItem> getSelectedNotes() {
    // Touch length so GetX tracks changes on selection updates.
    controller.selectedNoteIds.length;
    return archivedNotes
        .where(
          (note) =>
              note.id != null && controller.selectedNoteIds.contains(note.id),
        )
        .toList();
  }

  Future<void> handleBatchCopy() async {
    final selectedNotes = getSelectedNotes();
    final text = buildBatchCopyText(selectedNotes);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    controller.exitSelectionMode();
  }

  Future<void> handleBatchArchive(BuildContext context) async {
    final selectedNotes = getSelectedNotes();
    if (selectedNotes.isEmpty) return;
    for (final note in selectedNotes) {
      if (note.id == null) continue;
      if (isArchive) {
        await controller.unarchiveNote(note.id!);
      } else {
        await controller.archiveNote(note.id!);
      }
    }
    controller.exitSelectionMode();
  }

  Future<void> handleBatchDelete(BuildContext context) async {
    final selectedNotes = getSelectedNotes();
    if (selectedNotes.isEmpty) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text('Delete ${selectedNotes.length} notes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;
    for (final note in selectedNotes) {
      if (note.id == null) continue;
      await controller.deleteNoteWithoutPrompt(note.id!);
    }
    controller.exitSelectionMode();
  }

  Widget buildSelectionBar(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = isArchive ? 'Unarchive' : 'Archive';
    final actionIcon = isArchive ? Icons.unarchive : Icons.archive;

    return Obx(() {
      final selectedCount = getSelectedNotes().length;
      return Material(
        elevation: 6,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: controller.exitSelectionMode,
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
              ),
              Text(
                '$selectedCount selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: handleBatchCopy,
                tooltip: 'Copy',
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                onPressed: () => handleBatchArchive(context),
                tooltip: actionLabel,
                icon: Icon(actionIcon),
              ),
              IconButton(
                onPressed: () => handleBatchDelete(context),
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
              ),
            ],
          ),
        ),
      );
    });
  }

  return Obx(() {
    final isSelectionMode = controller.isSelectionMode.value;
    final bottomSpacer = isSelectionMode ? 0.0 : 50.0;

    return Builder(
      builder: (context) {
        final listView = CustomScrollView(
          controller: sc,
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (topmostItems.isNotEmpty)
              SliverToBoxAdapter(child: buildHeader(context, "Pinned")),
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
                  return buildHeader(context, entry.title ?? "");
                }
                return buildItem(entry.item!);
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
          ],
        );

        final selectionBar = SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: buildSelectionBar(context),
        );

        return Column(
          children: [
            Expanded(child: listView),
            if (isSelectionMode) selectionBar,
          ],
        );
      },
    );
  });
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

String buildBatchCopyText(List<NoteItem> notes) {
  if (notes.isEmpty) return '';
  final sorted = List<NoteItem>.from(notes)
    ..sort((a, b) => b.createTime.compareTo(a.createTime));
  final formatter = intl.DateFormat('yyyy-MM-dd');
  final buffer = StringBuffer();
  DateTime? currentDate;

  for (final note in sorted) {
    final dateKey = DateTime(
      note.createTime.year,
      note.createTime.month,
      note.createTime.day,
    );
    if (currentDate == null || currentDate != dateKey) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln(formatter.format(dateKey));
      currentDate = dateKey;
    }
    buffer.writeln((note.content ?? '').trimRight());
  }

  return buffer.toString().trimRight();
}
