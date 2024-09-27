import 'package:anynote/MainController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'archieve_list.dart';

class Archiveview extends StatelessWidget {
  Archiveview({super.key});

  final MainController c = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Archived"),
        ),
        body: ArchiveList(
          isArchive: true,
        ));
  }
}
