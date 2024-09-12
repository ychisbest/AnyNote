import 'dart:io';

import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Item {
  final DateTime date;
  Item(this.date);
}

class GithubHeatmap extends StatelessWidget {
  const GithubHeatmap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    RxList<NoteItem> items = Get.find<MainController>().notes;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Platform.isAndroid || Platform.isIOS) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: HeatmapPainter(items: items),
          );

        } else {
          return GestureDetector(
            onTapUp: (details) =>
                _handleTap(context, details, constraints.maxWidth),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: HeatmapPainter(items: items),
            ),
          );
        }
      },
    );
  }

  void _handleTap(BuildContext context, TapUpDetails details, double width) {
    final cellSize = width / 53;
    final weekIndex = (details.localPosition.dx / cellSize).floor();
    final dayIndex = (details.localPosition.dy / cellSize).floor();

    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final tappedDate = oneYearAgo.add(Duration(days: weekIndex * 7 + dayIndex));

    final MainController c = Get.find<MainController>();
    final count = c.notes
        .where((item) => HeatmapPainter.isSameDay(item.createTime, tappedDate))
        .length;

    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(tappedDate);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('notes'),
          content: Text('Date: $formattedDate\nCount: $count'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<NoteItem> items;

  HeatmapPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 53; // 52 weeks + 1 for padding
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));

    for (int week = 0; week < 53; week++) {
      for (int day = 0; day < 7; day++) {
        final date = oneYearAgo.add(Duration(days: week * 7 + day));
        if (date.isAfter(now)) continue;

        final count =
            items.where((item) => isSameDay(item.createTime, date)).length;
        final color = getColorForCount(count);

        final rect = Rect.fromLTWH(
          week * cellSize,
          day * cellSize,
          cellSize - 2, // -2 for gap
          cellSize - 2,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(2)),
          Paint()..color = color,
        );
      }
    }
  }

  Color getColorForCount(int count) {
    if (count == 0) return const Color(0xFFe0e0f0);
    if (count <= 2) return const Color(0xFF9be9a8);
    if (count <= 4) return const Color(0xFF40c463);
    if (count <= 6) return const Color(0xFF30a14e);
    return const Color(0xFF216e39);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
