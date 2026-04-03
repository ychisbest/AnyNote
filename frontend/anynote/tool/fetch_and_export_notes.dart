import 'dart:convert';
import 'dart:io';

import 'package:anynote/note_api_service.dart';

String normalizeBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

Map<String, dynamic> noteToUtcJson(NoteItem note) {
  String? toUtcString(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }

  return {
    'id': note.id,
    'isTopMost': note.isTopMost,
    'content': note.content,
    'createTime': toUtcString(note.createTime),
    'lastUpdateTime': toUtcString(note.lastUpdateTime),
    'archiveTime': toUtcString(note.archiveTime),
    'isArchived': note.isArchived,
    'color': note.color,
    'index': note.index,
  };
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: fvm dart run tool/fetch_and_export_notes.dart <base-url> [output.json] [secret]',
    );
    exitCode = 64;
    return;
  }

  final baseUrl = normalizeBaseUrl(args[0]);
  final outputPath = args.length >= 2 ? args[1] : 'notes.utc.json';
  final secret = args.length >= 3 ? args[2] : '';

  final api = NotesApi(baseUrl, secret);
  final notes = await api.getNotes();
  final normalized = notes.map(noteToUtcJson).toList();

  const encoder = JsonEncoder.withIndent('  ');
  await File(outputPath).writeAsString('${encoder.convert(normalized)}\n');

  stdout.writeln(
    'Exported ${normalized.length} notes to $outputPath from $baseUrl',
  );
}
