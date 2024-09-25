import 'dart:ui';

import 'package:anynote/views/markdown_render/markdown_render.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/Extension.dart';

class ArchiveList extends StatefulWidget {
  ArchiveList({Key? key, this.isArchive = false}) : super(key: key);

  final bool isArchive;

  @override
  _ArchiveListState createState() => _ArchiveListState();
}

class _ArchiveListState extends State<ArchiveList> {
  final MainController controller = Get.find<MainController>();
  final ScrollController sc = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.updateFilter('');
  }

  @override
  void dispose() {
    controller.updateFilter('');
    sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isArchive) _buildSearchBar(),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildList(archivedNotes, widget.isArchive),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildList(List<NoteItem> archivedNotes, bool isArchive) {
    return GridView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 280),
        controller: sc,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: archivedNotes.length,
        itemBuilder: (BuildContext context, int index) {
          final item = archivedNotes[index];
          return NoteItemWidget(
            key: ValueKey(item.id),
            controller: controller,
            item: item,
            isArchive: isArchive,
          );
        });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: TextField(
        style: const TextStyle(fontSize: 12),
        onChanged: (value) {
          controller.updateFilter(value);
        },
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class NoteItemWidget extends StatelessWidget {
  final MainController controller;
  final NoteItem item;
  final bool isArchive;

  const NoteItemWidget({
    Key? key,
    required this.controller,
    required this.item,
    required this.isArchive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool overflow = (item.content ?? "").trim().split("\n").length > 3;

    final Widget content = ClipRect(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: MarkdownRenderer(data: item.content?.trimRight() ?? ""),
      ),
    );

    final Widget shadowContent = Stack(
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
          child: content,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Icon(
            Icons.more_horiz,
            color: darkenColor(item.color.toFullARGB(), 0.55),
            size: 20,
          ),
        ),
      ],
    );

    return Container(
      key: ValueKey(item.id),
      decoration: BoxDecoration(
        border: Border.all(
          color: darkenColor(item.color.toFullARGB(), 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
        color: item.color.toFullARGB(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            await Get.to(() => EditNotePage(item: item));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: overflow ? shadowContent : content,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkenColor(item.color.toFullARGB(), 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // const Icon(
          //   Icons.event_note,
          //   size: 18,
          //   color: Colors.grey,
          // ),
          if (item.isTopMost)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.star,
                color: Colors.orange,
                size: 15,
              ),
            ),
          Text(
            timeAgo(item.createTime),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          // IconButton(
          //     onPressed: () {
          //       if (isArchive) {
          //         controller.unarchiveNote(item.id!);
          //       } else {
          //         controller.archiveNote(item.id!);
          //       }
          //     },
          //     icon: Icon(
          //       item.isArchived
          //           ? Icons.unarchive_outlined
          //           : Icons.archive_outlined,
          //       size: 15,
          //     )),

          PopupMenuButton<String>(
            icon: const Icon(
              size: 15,
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
                _buildPopupMenuItems(item, isArchive),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(
      NoteItem item, bool isArchive) {
    return [
      PopupMenuItem<String>(
        value: 'toggleTopMost',
        child: ListTile(
          leading: Icon(
            item.isTopMost ? Icons.star : Icons.star_border,
            color: item.isTopMost ? Colors.amber : Colors.grey,
          ),
          title: Text(item.isTopMost ? 'Remove from Top' : 'Add to Top'),
        ),
      ),
      PopupMenuItem<String>(
        value: 'toggleArchive',
        child: ListTile(
          leading: Icon(
            isArchive ? Icons.unarchive : Icons.archive,
            color: Colors.blue,
          ),
          title: Text(isArchive ? 'Unarchive' : 'Archive'),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: ListTile(
          leading: Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          title: Text('Delete'),
        ),
      ),
    ];
  }
}

String timeAgo(DateTime dateTime) {
  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()} weeks ago';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()} months ago';
  } else {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}
