import 'dart:convert';
import 'dart:io';

import 'package:anynote/date_parsing.dart';

Map<String, dynamic> normalizeNote(Map<String, dynamic> json) {
  String? normalizeDateField(String key) {
    final parsed = parseAppApiDate(json[key]);
    return parsed?.toUtc().toIso8601String();
  }

  return {
    'id': json['id'],
    'isTopMost': json['isTopMost'] ?? false,
    'content': json['content'],
    'createTime': normalizeDateField('createTime'),
    'lastUpdateTime': normalizeDateField('lastUpdateTime'),
    'archiveTime': normalizeDateField('archiveTime'),
    'isArchived': json['isArchived'] ?? false,
    'color': json['color'],
    'index': json['index'] ?? 0,
  };
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/export_notes.dart <input.json> <output.json>',
    );
    exitCode = 64;
    return;
  }

  final inputFile = File(args[0]);
  final outputFile = File(args[1]);

  final rawText = await inputFile.readAsString();
  final decoded = jsonDecode(rawText);

  if (decoded is! List) {
    stderr.writeln('Input JSON must be an array.');
    exitCode = 65;
    return;
  }

  final normalized = decoded
      .map((item) => normalizeNote(Map<String, dynamic>.from(item as Map)))
      .toList();

  const encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString('${encoder.convert(normalized)}\n');
}
