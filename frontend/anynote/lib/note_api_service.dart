import 'dart:io';
import 'dart:typed_data';

import 'package:brotli/brotli.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:zstandard/zstandard.dart';
import 'date_parsing.dart';

part 'note_api_service.g.dart'; // 用于代码生成

class EncodingAwareTransformer extends BackgroundTransformer {
  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    final contentEncodingValues =
        responseBody.headers[Headers.contentEncodingHeader] ?? const [];

    if (contentEncodingValues.isEmpty) {
      return super.transformResponse(options, responseBody);
    }

    final encodings = contentEncodingValues
        .expand((value) => value.split(','))
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty && value != 'identity')
        .toList();

    if (encodings.isEmpty) {
      return super.transformResponse(options, responseBody);
    }

    var bytes = await _readAllBytes(responseBody.stream);

    for (final encoding in encodings.reversed) {
      switch (encoding) {
        case 'zstd':
          final decompressed = await Zstandard().decompress(bytes);
          if (decompressed == null) {
            throw DioException(
              requestOptions: options,
              message: 'Failed to decompress zstd response.',
            );
          }
          bytes = decompressed;
          break;
        case 'br':
          bytes = Uint8List.fromList(brotli.decode(bytes));
          break;
        case 'gzip':
          bytes = Uint8List.fromList(gzip.decode(bytes));
          break;
      }
    }

    final headers = Map<String, List<String>>.from(responseBody.headers);
    headers.remove(Headers.contentEncodingHeader);

    final decodedBody = ResponseBody.fromBytes(
      bytes,
      responseBody.statusCode,
      statusMessage: responseBody.statusMessage,
      isRedirect: responseBody.isRedirect,
      headers: headers,
      onClose: responseBody.close,
    )..extra.addAll(responseBody.extra);

    return super.transformResponse(options, decodedBody);
  }

  Future<Uint8List> _readAllBytes(Stream<Uint8List> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

@HiveType(typeId: 0) // 每个适配器需要唯一的 typeId
class NoteItem {
  @HiveField(0)
  int? id;

  @HiveField(1)
  bool isTopMost;

  @HiveField(2)
  String? content;

  @HiveField(3)
  DateTime createTime;

  @HiveField(4)
  DateTime? lastUpdateTime;

  @HiveField(5)
  DateTime? archiveTime;

  @HiveField(6)
  bool isArchived;

  @HiveField(7)
  int? color;

  @HiveField(8)
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
      isTopMost: json['pinned'] ?? false,
      content: json['content'],
      createTime:
          parseAppApiDate(json['create_time']) ?? DateTime.now().toUtc(),
      lastUpdateTime: parseAppApiDate(json['update_time']),
      archiveTime: parseAppApiDate(json['archive_time']),
      isArchived: json['is_archived'] ?? false,
      color: null,
      index: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'is_archived': isArchived,
      'pinned': isTopMost,
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
            false, // Ensure that Dio follows redirects automatically
        baseUrl: baseUrl,
        headers: {
          'Accept-Encoding': 'zstd, br, gzip',
        },
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 5),
      ));
      _dio.transformer = EncodingAwareTransformer();
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (signalrID?.isNotEmpty ?? false) {
              options.headers["SignalR-ConnectionId"] = signalrID;
            }
            if (secret.isNotEmpty) {
              options.headers["X-Auth-Token"] = secret;
            }
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
      final response = await _dio.get('/api/notes');
      List jsonResponse = response.data;
      return jsonResponse.map((item) => NoteItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  Future<int> login() async {
    try {
      final response = await _dio.get('/api/healthz');
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
      final response = await _dio.put(
        '/api/notes/$id',
        data: noteItem.toJson(),
      );
      return NoteItem.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return NoteItem(createTime: DateTime.now().toUtc(), index: 0);
      }
      throw Exception('Failed to update note: $e');
    }
  }

  Future<NoteItem> postNoteItem(NoteItem noteItem) async {
    try {
      final response = await _dio.post(
        '/api/notes',
        data: noteItem.toJson(),
      );
      return NoteItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> deleteNoteItem(int id) async {
    try {
      await _dio.delete('/api/notes/$id');
    } catch (e) {
      if ((e as DioException).response?.statusCode != 404) {
        print("not found");
        throw Exception('Failed to delete note: $e');
      }
    }
  }
}
