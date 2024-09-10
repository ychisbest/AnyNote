import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_brotli_transformer/dio_brotli_transformer.dart';

class NoteItem {
  int? id;
  bool isTopMost;
  String? content;
  DateTime createTime;
  DateTime? lastUpdateTime;
  DateTime? archiveTime;
  bool isArchived;
  int? color;
  int index;

  NoteItem({
    this.id,
    this.isTopMost = false,
    this.content,
    required this.createTime,
    this.lastUpdateTime,
    this.archiveTime,
    this.isArchived = false,
    this.color,
    required this.index,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'],
      isTopMost: json['isTopMost'],
      content: json['content'],
      createTime: DateTime.parse(json['createTime']).toLocal(),
      lastUpdateTime: json['lastUpdateTime'] != null
          ? DateTime.parse(json['lastUpdateTime']).toLocal()
          : null,
      archiveTime: json['archiveTime'] != null
          ? DateTime.parse(json['archiveTime']).toLocal()
          : null,
      isArchived: json['isArchived'],
      color: json['color'],
      index: json['index'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isTopMost': isTopMost,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'lastUpdateTime': lastUpdateTime?.toIso8601String(),
      'archiveTime': archiveTime?.toIso8601String(),
      'isArchived': isArchived,
      'color': color,
      'index': index,
    };
  }
}

class NotesApi {
  String baseUrl;
  String secret;
  late Dio _dio;
  String? signalrID;

  NotesApi(this.baseUrl, this.secret) {
    _initializeDio();
  }

  void _initializeDio() {
    try {
      _dio = Dio(BaseOptions(
        followRedirects:
            true, // Ensure that Dio follows redirects automatically
        baseUrl: baseUrl,
        headers: {
          'Accept-Encoding': 'gzip br',
        },
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 5),
      ));
      _dio.transformer = DioBrotliTransformer();
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers["SignalR-ConnectionId"] = signalrID;
            options.headers["x-secret"] = secret;
            return handler.next(options);
          },
        ),
      );
    } catch (e) {
      print('Failed to initialize Dio: $e');
    }
  }

  void updateBaseUrl(String newBaseUrl, String newSecret) {
    baseUrl = newBaseUrl;
    secret = newSecret;
    _initializeDio();
  }

  Future<List<NoteItem>> getNotes() async {
    try {
      final response = await _dio.get('/api/Notes');
      List jsonResponse = response.data;
      return jsonResponse.map((item) => NoteItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  Future<int> login() async {
    try {
      final response = await _dio.get('/api/Notes');
      return response.statusCode ?? 0;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        return 401;
      }
      print('Failed to load notes: $e');
      rethrow;
    }
  }

  Future<NoteItem> putNoteItem(int id, NoteItem noteItem) async {
    try {
      print(_dio.options.baseUrl);
      final response = await _dio.put(
        '/api/Notes/$id',
        data: noteItem.toJson(),
      );
      return NoteItem.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return NoteItem(createTime: DateTime.now(), index: 0);
      }
      throw Exception('Failed to update note: $e');
    }
  }

  Future<NoteItem> addNote() async {
    try {
      final response = await _dio.post('/api/Notes/add');
      return NoteItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  Future<void> archiveItem(int id) async {
    try {
      await _dio.post('/api/Notes/Archieve', queryParameters: {'id': id});
    } catch (e) {
      throw Exception('Failed to archive note: $e');
    }
  }

  Future<void> updateIndex(List<int> ids, List<int> indices) async {
    if (ids.length != indices.length) {
      throw ArgumentError(
          'The lists of ids and indices must have the same length.');
    }

    try {
      await _dio.post('/api/Notes/UpdateIndex', data: {
        'ids': ids,
        'indices': indices,
      });
    } catch (e) {
      throw Exception('Failed to update indices: $e');
    }
  }

  Future<void> unarchiveItem(int id) async {
    try {
      await _dio.post('/api/Notes/UnArchieve', queryParameters: {'id': id});
    } catch (e) {
      throw Exception('Failed to unarchive note: $e');
    }
  }

  Future<NoteItem> postNoteItem(NoteItem noteItem) async {
    try {
      final response = await _dio.post(
        '/api/Notes',
        data: noteItem.toJson(),
      );
      return NoteItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Future<NoteItem> addNoteItem(String content) async {
    try {
      final response = await _dio.post(
        '/',
        data: {'content': content},
      );
      return NoteItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> deleteNoteItem(int id) async {
    try {
      await _dio.delete('/api/Notes/$id');
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}
