import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'GlobalConfig.dart';
import 'models/upload_faild.dart';
import 'note_api_service.dart';

typedef UpdateEditTextCallback = void Function(String id, String text);

class MainController extends GetxController {
  static String baseurl = GlobalConfig.baseUrl;
  static String secret = GlobalConfig.secretStr;
  final NotesApi _api = NotesApi(baseurl, secret);
  final RxList<NoteItem> notes = <NoteItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterText = ''.obs;
  HubConnection? hubConnection;
  UpdateEditTextCallback? updateEditTextCallback;

  RxInt fontSize = GlobalConfig.fontSize.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void initData() {
    fetchNotes(readlocalfirst: true);
    initSignalR();
  }

  void updateBaseUrl(String url, String newsecret) {
    baseurl = url;
    secret = newsecret;
    _api.updateBaseUrl(url, secret);
    initSignalR();
  }

  Future<void> initSignalR() async {
    hubConnection?.stop();

    hubConnection = HubConnectionBuilder()
        .withUrl(
          '$baseurl/notehub',
        )
        .withAutomaticReconnect()
        .build();

    hubConnection?.on("ReceiveNoteUpdate", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final updatedNote =
            NoteItem.fromJson(arguments[0] as Map<String, dynamic>);
        updateEditTextCallback?.call(
            updatedNote.id.toString(), updatedNote.content.toString());
        updateNoteLocally(updatedNote);
      }
    });

    hubConnection?.on("ReceiveNoteArchive", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final noteId = arguments[0] as int;
        archiveNoteLocally(noteId);
      }
    });

    hubConnection?.on("ReceiveNoteUnarchive", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final noteId = arguments[0] as int;
        unarchiveNoteLocally(noteId);
      }
    });

    hubConnection?.on("ReceiveNoteDelete", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final noteId = arguments[0] as int;
        deleteNoteLocally(noteId);
      }
    });

    hubConnection?.on("ReceiveNewNote", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final newNote = NoteItem.fromJson(arguments[0] as Map<String, dynamic>);
        addNoteLocally(newNote);
      }
    });

    hubConnection?.on("ReceiveNoteIndicesUpdate", (arguments) {
      if (arguments != null && arguments.length == 2) {
        final ids = (arguments[0] as List<dynamic>).cast<int>().toList();
        final indices = (arguments[1] as List<dynamic>).cast<int>().toList();
        updateIndicesLocally(ids, indices);
      }
    });

    try {
      await hubConnection?.start();
      _api.signalrID = hubConnection?.connectionId;
      print("SignalR Connected!" +
          "id=" +
          hubConnection!.connectionId.toString());
    } catch (e) {
      print("Error connecting to SignalR: $e");
    }
  }

  void updateNoteLocally(NoteItem updatedNote) {
    final index = notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      notes.refresh();
    }
  }

  void archiveNoteLocally(int noteId) {
    final index = notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      notes[index].isArchived = true;
      notes.refresh();
    }
  }

  void unarchiveNoteLocally(int noteId) {
    final index = notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      notes[index].isArchived = false;
      notes.refresh();
    }
  }

  void deleteNoteLocally(int noteId) {
    notes.removeWhere((note) => note.id == noteId);
  }

  void addNoteLocally(NoteItem newNote) {
    notes.add(newNote);
    //notes.refresh();
  }

  void updateIndicesLocally(List<int> ids, List<int> indices) {
    for (int i = 0; i < ids.length; i++) {
      final index = notes.indexWhere((note) => note.id == ids[i]);
      if (index != -1) {
        notes[index].index = indices[i];
      }
    }
    notes.refresh();
  }

  Future<void> saveNotesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString('offline_notes', notesJson);
  }

  Future<void> loadNotesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('offline_notes');
    if (notesJson != null) {
      final List<dynamic> decodedNotes = jsonDecode(notesJson);
      notes.assignAll(
          decodedNotes.map((json) => NoteItem.fromJson(json)).toList());
    }
  }

  Future<bool> fetchNotes({bool readlocalfirst = false}) async {
    isLoading.value = true;
    try {
      if (readlocalfirst) {
        await loadNotesFromLocal();
        isLoading.value = false;
      }
      final fetchedNotes = await _api.getNotes();

      notes.assignAll(fetchedNotes);

      var map = await GlobalConfig.getUpdateFailedNotes();
      List<String> ids = [];
      for (var key in map.keys) {
        var item = map[key];
        if (item!.oldNote.content == item!.faildNote.content) {
          updateNote(item.faildNote.id!, item.faildNote);
          map.remove(key);
        } else {
          var content = "# Conflict content\n" + item.faildNote.content!;
          var note = await _api.addNoteItem(content);
          notes.add(note);
          ids.add(item.faildNote.id.toString());
        }
      }
      map.removeWhere((key, value) => ids.contains(key));
      await GlobalConfig.setUpdateFailedNotes(map);

      for (var note in notes) {
        updateEditTextCallback?.call(
            note.id.toString(), note.content.toString());
      }

      saveNotesToLocal();

      return true;
    } catch (e) {
      print(e);
      Get.snackbar('Network Error', 'offline mode');
      loadNotesFromLocal();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> login() async {
    try {
      int statusCode = await _api.login();
      if (statusCode >= 200 && statusCode < 300) {
        return {
          'isLoginSuccess': true,
          'errorContent': null,
        };
      } else if (statusCode == 401) {
        return {
          'isLoginSuccess': false,
          'errorContent': 'Secret is incorrect',
        };
      } else {
        return {
          'isLoginSuccess': false,
          'errorContent': 'Login Failed',
        };
      }
    } catch (e) {
      return {
        'isLoginSuccess': false,
        'errorContent': e.toString(),
      };
    }
  }

  void logout() {
    hubConnection?.stop();
    notes.clear();
    saveNotesToLocal();
  }

  Future<bool> updateNote(int id, NoteItem noteItem) async {
    try {
      final updatedNote = await _api.putNoteItem(id, noteItem);
      updateNoteLocally(updatedNote);
      saveNotesToLocal();

      var map = await GlobalConfig.getUpdateFailedNotes();
      map.remove(id.toString());
      await GlobalConfig.setUpdateFailedNotes(map);

      return true;
    } catch (e) {
      print(e);

      var map = await GlobalConfig.getUpdateFailedNotes();
      if (map[id.toString()]?.oldNote != null) {
        map[id.toString()] = UploadFailedNote(
            faildNote: noteItem, oldNote: map[id.toString()]!.oldNote);
      } else {
        map[id.toString()] =
            UploadFailedNote(faildNote: noteItem, oldNote: noteItem);
      }
      await GlobalConfig.setUpdateFailedNotes(map);
      updateNoteLocally(noteItem);
      saveNotesToLocal();

      return false;
    }
  }

  Future<NoteItem> addNote() async {
    try {
      final newNote = await _api.addNote();
      addNoteLocally(newNote);
      return newNote;
    } catch (e) {
      Get.snackbar('错误', '添加笔记失败: $e');
      throw Exception("add error");
    }
  }

  Future<void> archiveNote(int id) async {
    try {
      await _api.archiveItem(id);
      archiveNoteLocally(id);
    } catch (e) {
      Get.snackbar('错误', '归档笔记失败: $e');
    }
  }

  Future<void> unarchiveNote(int id) async {
    try {
      await _api.unarchiveItem(id);
      unarchiveNoteLocally(id);
    } catch (e) {
      Get.snackbar('错误', '取消归档笔记失败: $e');
    }
  }

  Future<void> deleteNote(int id) async {
    bool confirm = await Get.dialog<bool>(
          AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this note?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Get.back(result: false),
              ),
              TextButton(
                child: Text('Delete'),
                onPressed: () => Get.back(result: true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        deleteNoteLocally(id);
        await _api.deleteNoteItem(id);
      } catch (e) {
        Get.snackbar('错误', '删除笔记失败: $e');
      }
    }
  }

  Future<void> deleteNoteWithoutPrompt(int id) async {
    try {
      deleteNoteLocally(id);
      await _api.deleteNoteItem(id);
    } catch (e) {
      //Get.snackbar('错误', '删除空笔记失败: $e');
    }
  }

  Future<void> updateIndex(List<NoteItem> items) async {
    try {
      List<int> ids = items.map((item) => item.id!).toList();
      List<int> indices = items.map((item) => item.index).toList();
      updateIndicesLocally(ids, indices);
      await _api.updateIndex(ids, indices);
    } catch (e) {
      Get.snackbar('错误', '更新笔记顺序失败: $e');
    }
  }

  void updateFilter(String value) {
    filterText.value = value;
  }

  List<NoteItem> get filteredNotes {
    final filter = filterText.value;
    List<NoteItem> res = notes.toList();

    if (filter.isNotEmpty) {
      res = res.where((item) {
        List<String> words = filter.split(' ');
        return words.every((word) {
          bool contentMatches =
              (item.content ?? "").toLowerCase().contains(word.toLowerCase());
          String dateString = item.createTime.toString().replaceAll("-", "");
          bool dateMatches = dateString.contains(word);
          return contentMatches || dateMatches;
        });
      }).toList();
    }

    sortNotes(res, false);
    return res;
  }

  void sortNotes(List<NoteItem> res, bool withIndex) {
    res.sort((a, b) {
      if (a.isTopMost != b.isTopMost) {
        return b.isTopMost ? 1 : -1;
      }

      if (withIndex) {
        if (a.index != b.index) {
          return a.index.compareTo(b.index);
        }
      }
      return b.createTime.compareTo(a.createTime);
    });
  }

  List<NoteItem> get filteredArchivedNotes {
    return filteredNotes.where((note) => note.isArchived).toList();
  }

  List<NoteItem> get filteredUnarchivedNotes {
    var res = notes.where((note) => !note.isArchived).toList();
    sortNotes(res, true);
    return res;
  }

  Map<String, List<NoteItem>> get extractTagsWithNotes {
    final RegExp tagRegExp = RegExp(r'#([0-9a-zA-Z\u4e00-\u9fa5]+)');
    Map<String, List<NoteItem>> tagMap = {};

    for (var obj in notes) {
      final matches = tagRegExp.allMatches(obj.content ?? "");
      for (var match in matches) {
        String tag = match.group(1)!;
        if (!tagMap.containsKey(tag)) {
          tagMap[tag] = [];
        }
        tagMap[tag]!.add(obj);
      }
    }

    return tagMap;
  }

  List<String> get tags {
    final RegExp tagRegExp = RegExp(r'#([0-9a-zA-Z\u4e00-\u9fa5]+)');
    Set<String> tags = {};

    var copynotes = notes.toList();

    sortNotes(copynotes, true);

    for (var obj in copynotes) {
      final matches = tagRegExp.allMatches(obj.content ?? "");
      for (var match in matches) {
        String tag = match.group(1)!;
        tags.add(tag);
      }
    }

    return tags.toList();
  }

  List<NoteItem> get notesWithoutTag {
    final RegExp tagRegExp = RegExp(r'#([0-9a-zA-Z\u4e00-\u9fa5]+)');

    var res = filteredArchivedNotes.where((item) {
      return !tagRegExp.hasMatch(item.content ?? "");
    }).toList();

    return res;
  }

  @override
  void onClose() {
    hubConnection?.stop();
    super.onClose();
  }
}
