import 'dart:ui';
import 'package:anynote/views/markdown_render/markdown_render.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/Extension.dart';
import 'package:intl/intl.dart' as intl;

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
        shrinkWrap: false,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 270),
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

class NoteItemWidget extends StatefulWidget {
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
  State<NoteItemWidget> createState() => _NoteItemWidgetState();
}

class _NoteItemWidgetState extends State<NoteItemWidget> {
  bool _isOverflow = false;
  bool _isHovered=false;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.item.id),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isHovered?darkenColor(widget.item.color.toFullARGB(), 0.5):darkenColor(widget.item.color.toFullARGB(), 0.1),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
        color: widget.item.color.toFullARGB(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onTap: () async {
            await Get.to(() => EditNotePage(item: widget.item));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return _buildContent(constraints);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.item.content?.trimRight() ?? ""),
          maxLines: 9,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth-8);

        _isOverflow = textPainter.didExceedMaxLines;

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Stack(
            children: [
              MarkdownRenderer(data: widget.item.content?.trimRight() ?? ""),
              if (_isOverflow)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.item.color.toFullARGB().withOpacity(0),
                          widget.item.color.toFullARGB(),
                        ],
                      ),
                    ),
                  ),
                ),
              if(_isOverflow)
                Positioned(
                  bottom: -5,
                  left: 1/2,
                  right: 0,
                  child: Icon(
                    Icons.more_horiz,
                    color: darkenColor(widget.item.color.toFullARGB(), 0.55),
                    size: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkenColor(widget.item.color.toFullARGB(), 0.04),
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
          if (widget.item.isTopMost)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.star,
                color: Colors.orange,
                size: 15,
              ),
            ),
          Text(
            timeAgo(widget.item.createTime),
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
                  widget.item.isTopMost = !widget.item.isTopMost;
                  widget.controller.updateNote(widget.item.id!, widget.item);
                  break;
                case 'toggleArchive':
                  if (widget.isArchive) {
                    widget.controller.unarchiveNote(widget.item.id!);
                  } else {
                    widget.controller.archiveNote(widget.item.id!);
                  }
                  break;
                case 'delete':
                  widget.controller.deleteNote(widget.item.id!);
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                _buildPopupMenuItems(widget.item, widget.isArchive),
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
    return intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}
