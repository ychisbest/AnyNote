import 'package:anynote/note_api_service.dart';

class UploadFailedNote {
  final NoteItem failedNote;
  final NoteItem oldNote;
  UploadFailedNote({required this.failedNote, required this.oldNote});

  factory UploadFailedNote.fromJson(Map<String, dynamic> json) {
    return UploadFailedNote(
      failedNote: NoteItem.fromJson(json['faildNote']),
      oldNote: NoteItem.fromJson(json['oldNote']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faildNote': failedNote.toJson(),
      'oldNote': oldNote.toJson(),
    };
  }
}
