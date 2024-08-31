import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagList extends StatelessWidget {
  TagList({super.key});
  final MainController c = Get.find<MainController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("标签列表"),
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(() => const AddTagListView());
                },
                icon: const Icon(Icons.bookmark_added_outlined))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Obx(() {
            var map = c.extractTagsWithNotes;
            var tags = map.keys.toList();
            return ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      Get.to(() => NoteTagListView(tag: tags[index]));
                    },
                    title: Text(tags[index]),
                  );
                });
          }),
        ));
  }
}

class NoteTagListView extends StatelessWidget {
  NoteTagListView({super.key, required this.tag});
  final String tag;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tag),
        ),
        body: GetX<MainController>(builder: (c) {
          var items = c.extractTagsWithNotes[tag] ?? [];

          return ListView.builder(
              itemCount: items?.length,
              itemBuilder: (cc, ci) {
                return BuildNoteItem(c, items[ci], ci, true);
              });
        }));
  }
}

class AddTagListView extends StatelessWidget {
  const AddTagListView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("标记无标签内容"),
        ),
        body: GetX<MainController>(builder: (c) {
          var items = c.notesWithoutTag;

          return ListView.builder(
              itemCount: items?.length,
              itemBuilder: (cc, ci) {
                return Column(
                  children: [
                    BuildNoteItem(c, items[ci], ci, true),
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        ...List.generate(c.tags.length, (tagIndex) {
                          return TextButton(
                              child: Text(c.tags[tagIndex]),
                              onPressed: () {
                                items[ci].content =
                                    "#${c.tags[tagIndex]}\n${items[ci].content ?? ""}";
                                c.updateNote(items[ci].id!, items[ci]);
                              });
                        }),
                        const SizedBox(
                          height: 50,
                        )
                      ],
                    )
                  ],
                );
              });
        }));
  }
}
