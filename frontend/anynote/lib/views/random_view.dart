import 'dart:math';

import 'package:anynote/views/markdown_render/markdown_render.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../Extension.dart';
import '../MainController.dart';

class RandomView extends StatelessWidget {
  RandomView({super.key});

  // Finding the MainController instance
  final c = Get.find<MainController>();

  // Making `index` reactive using RxInt
  final RxInt index =
      RxInt(Random().nextInt(Get.find<MainController>().notes.length));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Wrapping with Obx to reactively update the title when index changes
        title: Obx(() => Text(
              DateFormat('yyyy-MM-dd HH:mm')
                  .format(c.notes[index.value].createTime),
            )),
        actions: [
          TextButton(
            onPressed: () {
              // Updating the reactive index value correctly
              index.value = Random().nextInt(c.notes.length);
            },
            child: const Icon(Icons.casino),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            // Wrapping with Obx to update the markdown content when index changes
              child: Obx(() => MarkdownRenderer(
                  data: c.notes[index.value].content ?? "",
                )),
          ),
        ),
      ),
    );
  }
}
