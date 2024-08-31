import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/Extension.dart';

class ArchieveList extends StatefulWidget {
  ArchieveList({super.key, this.isArchive = false});

  bool isArchive = false;

  @override
  _ArchieveListState createState() => _ArchieveListState();
}

class _ArchieveListState extends State<ArchieveList> {
  final MainController controller = Get.find<MainController>();

  @override
  void dispose() {
    if (mounted) {
      controller.updateFilter('');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            var archivedNotes = widget.isArchive
                ? controller.filteredArchivedNotes
                : controller.filteredUnarchivedNotes;
            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                scrollbars: true,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: RefreshIndicator(
                  onRefresh: () => controller.fetchNotes(),
                  child: _buildList(archivedNotes, widget.isArchive)),
            );
          }),
        ),
        if (widget.isArchive) _buildSearchBar(),
      ],
    );
  }

  Widget _buildList(List<NoteItem> archivedNotes, bool isArchive) {
    if (isArchive) {
      return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: archivedNotes.length,
          itemBuilder: (BuildContext context, int index) {
            final item = archivedNotes[index];
            return BuildNoteItem(controller, item, index, widget.isArchive);
          });
    }

    return ReorderableListView(
        scrollDirection: Axis.vertical,
        children: List.generate(archivedNotes.length, (index) {
          return BuildNoteItem(
              controller, archivedNotes[index], index, widget.isArchive);
        }),
        onReorder: (oldindex, newindex) {
          if (newindex > oldindex) {
            newindex -= 1;
          }
          final item = archivedNotes.removeAt(oldindex);
          archivedNotes.insert(newindex, item);
          for (int i = 0; i < archivedNotes.length; i++) {
            archivedNotes[i].index = i;
          }
          controller.updateIndex(archivedNotes);
        });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        style: const TextStyle(fontSize: 12),
        onChanged: (value) {
          controller.updateFilter(value);
        },
        decoration: InputDecoration(
          hintText: "搜索...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

Widget BuildNoteItem(
    MainController controller, NoteItem item, int index, bool isArchive) {
  var overflow = (item.content ?? "").trim().split("\n").length > 5;

  var content = ClipRect(
    child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: CustomMarkdownDisplay(text: item.content?.trimRight() ?? "")),
  );

  var shadowContent = Stack(
    children: [
      ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent, Colors.transparent],
              stops: [0.3, 0.9, 1],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: content),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Icon(
            Icons.more_horiz_sharp,
            color: darkenColor(item.color.toFullARGB(), 0.55),
            size: 15,
          ))
    ],
  );

  return Container(
    key: ValueKey(item.id),
    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
    decoration: BoxDecoration(
      border: Border.all(color: darkenColor(item.color.toFullARGB()), width: 2),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      color: item.color.toFullARGB(),
      boxShadow: item.isTopMost
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(5, 10),
              ),
            ]
          : null,
    ),
    child: GestureDetector(
      onTap: () async {
        await Get.to(() => EditNotePage(item: item));
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkenColor(item.color.toFullARGB()),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    DateFormat('yyyy年MM月dd日 HH:mm').format(item.createTime),
                    style: TextStyle(color: Colors.grey[700], fontSize: 10),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.black54,
                    ),
                    onSelected: (String result) {
                      switch (result) {
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
                        case 'delete':
                          controller.deleteNote(item.id!);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggleTopMost',
                        child: ListTile(
                          leading: Icon(
                            item.isTopMost
                                ? Icons.star_outline_outlined
                                : Icons.star,
                            color: item.isTopMost ? Colors.grey : Colors.orange,
                          ),
                          title: Text(item.isTopMost
                              ? 'Remove from Top'
                              : 'Add to Top'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggleArchive',
                        child: ListTile(
                          leading: Icon(
                            isArchive
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            color: Colors.green,
                          ),
                          title: Text(isArchive ? 'Unarchive' : 'Archive'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: overflow ? shadowContent : content),
          ],
        ),
      ),
    ),
  );
}
