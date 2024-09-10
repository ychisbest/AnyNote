import 'package:anynote/note_api_service.dart';

class UploadFailedNote {
  final NoteItem faildNote;
  final NoteItem oldNote;
  UploadFailedNote({required this.faildNote, required this.oldNote});

  factory UploadFailedNote.fromJson(Map<String, dynamic> json) {
    return UploadFailedNote(
      faildNote: NoteItem.fromJson(json['faildNote']),
      oldNote: NoteItem.fromJson(json['oldNote']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faildNote': faildNote.toJson(),
      'oldNote': oldNote.toJson(),
    };
  }
}
