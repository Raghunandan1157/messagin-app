import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AttachmentResult {
  final String id;
  final String url;
  final String kind;
  final String mime;
  final int size;
  const AttachmentResult({
    required this.id,
    required this.url,
    required this.kind,
    required this.mime,
    required this.size,
  });
}

class UploadService {
  String _baseUrl() {
    final endpoint = (dotenv.env['API_ENDPOINT'] ?? '/api/sql').trim();
    final parsed = Uri.parse(endpoint);
    final absolute = parsed.hasScheme
        ? parsed
        : (kIsWeb ? Uri.base.resolve(endpoint) : parsed);
    var path = absolute.path;
    if (path.endsWith('/api/sql')) {
      path = path.substring(0, path.length - '/api/sql'.length);
    } else if (path.endsWith('/api')) {
      path = path.substring(0, path.length - '/api'.length);
    }
    path = path.replaceFirst(RegExp(r'/$'), '');
    final port = absolute.hasPort ? ':${absolute.port}' : '';
    final origin = absolute.host.isEmpty
        ? Uri.base.origin
        : '${absolute.scheme}://${absolute.host}$port';
    return '$origin$path';
  }

  Future<AttachmentResult> upload({
    required Uint8List bytes,
    required String name,
    required String mime,
    required String kind,
    required String chatId,
    required String uploaderId,
  }) async {
    final token = dotenv.env['API_TOKEN'] ?? '';
    final base = _baseUrl();
    final qp = Uri(queryParameters: {
      'chatId': chatId,
      'uploaderId': uploaderId,
      'kind': kind,
      'name': name,
    }).query;
    final uri = Uri.parse('$base/api/upload?$qp');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': mime,
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: bytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Upload ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return AttachmentResult(
      id: body['id'].toString(),
      url: body['url'] as String,
      kind: body['kind'] as String,
      mime: body['mime'] as String? ?? mime,
      size: (body['size'] as num?)?.toInt() ?? bytes.length,
    );
  }
}
