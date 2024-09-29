import 'dart:async';
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
    return LayoutBuilder(builder: (context, constraints) {
      if (Get.width <= 560) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          controller: sc,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemCount: archivedNotes.length,
          itemBuilder: (BuildContext context, int index) {
            final item = archivedNotes[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: NoteItemWidget(
                key: ValueKey(item.id),
                controller: controller,
                item: item,
                isArchive: isArchive,
              ),
            );
          },
        );
      } else {
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
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
      child: TextField(
        style: const TextStyle(fontSize: 12),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(0.6),
          filled: true,
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
         focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 1,color: Colors.black54),
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 1,color: Colors.black12),
            borderRadius: BorderRadius.circular(15),
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
  bool _isHovered = false;
  final ScrollController _scrollController = ScrollController();
  final MainController c = Get.find<MainController>();
  @override
  void initState() {
    super.initState();
    _checkOverflow();
  }

  @override
  void didUpdateWidget(NoteItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkOverflow();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isOverflow = _scrollController.position.maxScrollExtent > 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.item.id),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isHovered
              ? darkenColor(widget.item.color.toFullARGB(), 0.3)
              : darkenColor(widget.item.color.toFullARGB(), 0.1),
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
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            await Get.to(() => EditNotePage(item: widget.item));
          },
          onTapDown: (_) => setState(() => _isHovered = true),
          onTapUp: (_) => setState(() => _isHovered = false),
          onTapCancel: () => setState(() => _isHovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              AnimatedSwitcher(
                duration: Duration(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return _buildContent(constraints);
                    },
                  ),
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
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Obx(() {
                    return MarkdownRenderer(
                      fontsize: c.fontSize.value,
                      data: widget.item.content?.trimRight() ?? "",
                    );
                  }),
                ),
              ),
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
              if (_isOverflow)
                Positioned(
                  bottom: -5,
                  left: 1 / 2,
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
