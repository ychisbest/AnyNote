import 'dart:collection';
import 'dart:core';

import 'package:anynote/Extension.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class NoteList extends StatefulWidget {
  const NoteList({super.key});


  @override
  State<NoteList> createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {

  final MainController c = Get.find<MainController>();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Obx(
            () {
          // 过滤出未归档的笔记
          var unarchivedNotes = c.notes.where((note) => !note.isArchived).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(unarchivedNotes.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1)
                ),
                child: InkWell(
                  onTap: () async {
                    await Get.to(() => EditNotePage(item: unarchivedNotes[index]));
                  },
                  child: Ink(
                    color: unarchivedNotes[index].color.toFullARGB(),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(child: CustomMarkdownDisplay(text: unarchivedNotes[index].content ?? "")),
                          TextButton(
                              onPressed: () {
                                c.archiveNote(unarchivedNotes[index].id!);
                              },
                              child: const Icon(Icons.archive_outlined)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
