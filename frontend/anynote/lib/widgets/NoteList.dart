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
          boxShadow: [
            BoxShadow(
                color: darkenColor(widget.item.color.toFullARGB()),
                blurRadius: 2)
          ],
          border: Border.all(
            color: _isHovered
                ? darkenColor(widget.item.color.toFullARGB(), 0.3)
                : darkenColor(widget.item.color.toFullARGB(), 0.1),
            width: 1,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: widget.item.color.toFullARGB(),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            //behavior: HitTestBehavior.translucent,
            onTap: () async {
              await Get.to(() => EditNotePage(item: widget.item));
            },
            onTapDown: (_) => setState(() => _isHovered = true),
            onTapUp: (_) => setState(() => _isHovered = false),
            onTapCancel: () => setState(() => _isHovered = false),
            onLongPress: () async {
              var res = await _showOptionsDialog(widget.item);
              switch (res) {
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
                case 'copy':
                  Clipboard.setData(
                      ClipboardData(text: widget.item.content ?? ""));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  break;
                case 'delete':
                  widget.controller.deleteNote(widget.item.id!);
                  break;
                case 'up':
                  var list = widget.controller.filteredUnarchivedNotes;
                  int index =
                      list.indexWhere((obj) => obj.id == widget.item.id);
                  // 如果找到了且该元素不是第一个元素
                  if (index > 0) {
                    // 交换当前元素和它前面的一个元素的位置
                    var temp = list[index - 1];
                    list[index - 1] = list[index];
                    list[index] = temp;
                  }

                  widget.controller.updateIndex(list);

                  break;
                case 'down':
                  var list = widget.controller.filteredUnarchivedNotes;
                  int index =
                      list.indexWhere((obj) => obj.id == widget.item.id);

                  if (index == list.length - 1) break;

                  // 如果找到了且该元素不是第一个元素
                  if (index > -1) {
                    // 交换当前元素和它前面的一个元素的位置
                    var temp = list[index + 1];
                    list[index + 1] = list[index];
                    list[index] = temp;
                  }
                  widget.controller.updateIndex(list);
                  break;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                //_buildHeader(context),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return _buildContent(constraints);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    var content = ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        scrollbars: false,
      ),
      child: SingleChildScrollView(
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: widget.item.isTopMost
              ? BoxConstraints(maxHeight: maxNoteItemHeight)
              : BoxConstraints(
                  maxHeight: maxNoteItemHeight - 50,
                  minHeight: maxNoteItemHeight - 50),
          child: Stack(
            children: [
              if (widget.item.isTopMost)
                const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.vertical_align_top,
                      size: 20,
                      color: Colors.orange,
                    )),
              _isOverflow
                  ? ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent
                          ],
                          stops: [0.0, 0.6, 1],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: content,
                    )
                  : content,
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

  Future<String?> _showOptionsDialog(NoteItem item) {
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
              // 显示创建时间和最后更新时间
              // Text(
              //   'Created: ${timeAgo(item.createTime!)}',
              //   style: TextStyle(color: Colors.grey[600], fontSize: 10),
              // ),

              const SizedBox(
                height: 10,
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

              if (!widget.isArchive)
                ListTile(
                  leading: const Icon(Icons.arrow_upward),
                  title: const Text(
                    "Move Up",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => Navigator.of(context).pop('up'),
                ),

              if (!widget.isArchive)
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
                leading: const Icon(
                  Icons.copy,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Copy',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop('copy'),
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget BuildNoteList(List<NoteItem> archivedNotes, bool isArchive,
    {ScrollController? sc}) {
  Widget buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 20, bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget buildItem(NoteItem item) {
    final MainController controller = Get.find<MainController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
  final groupedEntries = Get.find<MainController>().groupMemosByDate(normalItems);
  final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisExtent: maxNoteItemHeight, // Use the maximum height defined
  );

  final dateFormatter = intl.DateFormat('yyyy-MM-dd');

  return CustomScrollView(
    controller: sc,
    physics: const BouncingScrollPhysics(),
    slivers: [
      if (topmostItems.isNotEmpty)
        SliverToBoxAdapter(child: buildHeader("📌 Topmost")),
      SliverList.builder(
        itemCount: topmostItems.length,
        itemBuilder: (context, index) {
          return buildItem(topmostItems[index]);
        },
      ),
      if (normalItems.isNotEmpty)
        SliverToBoxAdapter(
          child: buildHeader("🗒️ Notes"),
        ),
      for (final entry in groupedEntries) ...[
        SliverToBoxAdapter(
          child: buildHeader(dateFormatter.format(entry.key)),
        ),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => buildItem(entry.value[index]),
            childCount: entry.value.length,
          ),
          gridDelegate: gridDelegate,
        ),
      ],
      const SliverToBoxAdapter(
          child: SizedBox(
        height: 50,
      ))
    ],
  );
}
