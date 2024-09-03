import 'dart:math';

import 'package:anynote/MainController.dart';
import 'package:anynote/views/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../Extension.dart';
import 'archieve_list.dart';

class Archiveview extends StatelessWidget {
  Archiveview({super.key});

  final MainController c = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Archived"),
          actions: [
            TextButton(
              onPressed: () {
                var ri = Random().nextInt(c.filteredArchivedNotes.length - 1);
                Get.to(() {
                  return Scaffold(
                      appBar: AppBar(
                          title: Text(DateFormat('yyyy-MM-dd HH:mm')
                              .format(c.filteredArchivedNotes[ri].createTime))),
                      body: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SizedBox(
                              width: double.infinity,
                              child: CustomMarkdownDisplay(
                                  text: c.filteredArchivedNotes[ri].content ??
                                      "")),
                        ),
                      ));
                });
              },
              child: const Icon(Icons.casino),
            ),
            TextButton(
                onPressed: () {
                  Get.to(() => TagList());
                },
                child: const Icon(Icons.tag_sharp)),
          ],
        ),
        body: ArchieveList(
          isArchive: true,
        ));
  }
}
