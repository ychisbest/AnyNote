import 'dart:math';

import 'package:anynote/widgets/NoteList.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../MainController.dart';

class RandomView extends StatelessWidget {
  RandomView({super.key});

  final c = Get.find<MainController>();
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  void _pickRandomDate() {
    if (c.notes.isEmpty) return;
    final dates = c.notes.map((n) => DateTime(n.createTime.year, n.createTime.month, n.createTime.day)).toSet().toList();
    dates.sort();
    selectedDate.value = dates[Random().nextInt(dates.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDate.value == null) {
      _pickRandomDate();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final date = selectedDate.value;
          return date != null 
              ? Text(DateFormat('yyyy-MM-dd').format(date))
              : const Text('Random Day');
        }),
        actions: [
          TextButton(
            onPressed: () {
              _pickRandomDate();
            },
            child: const Icon(Icons.casino),
          ),
        ],
      ),
      body: Obx(() {
        final date = selectedDate.value;
        if (date == null) return const Center(child: Text('No notes'));
        
        final dayNotes = c.notes.where((n) => 
          DateTime(n.createTime.year, n.createTime.month, n.createTime.day) == date
        ).toList()
          ..sort((a, b) => a.createTime.compareTo(b.createTime));
        
        if (dayNotes.isEmpty) return const Center(child: Text('No notes'));
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black12.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...dayNotes.map((note) => NoteItemWidget(
                  controller: c,
                  item: note,
                )),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      }),
    );
  }
}
