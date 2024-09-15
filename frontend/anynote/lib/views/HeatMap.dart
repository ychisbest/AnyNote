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
  final double cellSize; // 新增参数来控制每个热力点的大小

  const GithubHeatmap({Key? key, required this.cellSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    RxList<NoteItem> items = Get.find<MainController>().notes;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) =>
              _handleTap(context, details, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter:
                HeatmapPainter(items: items, cellSize: cellSize), // 传入 cellSize
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, TapUpDetails details, double width) {
    final weekIndex = (details.localPosition.dx / cellSize).floor();
    final dayIndex = (details.localPosition.dy / cellSize).floor();

    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final tappedDate = oneYearAgo.add(Duration(days: weekIndex * 7 + dayIndex));

    // 如果点击的日期大于今天，直接返回
    if (tappedDate.isAfter(now)) {
      return;
    }

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
  final double cellSize; // 新增参数来控制每个热力点的大小

  HeatmapPainter({required this.items, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
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

        // 绘制每个方块的热力图颜色
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(5)),
          Paint()..color = color,
        );

        // 如果当前日期是今天，绘制一个标记
        if (isSameDay(date, now)) {
          final borderPaint = Paint()
            ..color = Colors.orange // 你可以使用任何颜色来标记今天
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1; // 边框宽度

          // 绘制今天的边框
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(5)),
            borderPaint,
          );
        }
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
