import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

abstract class NeonTransport {
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params});
  Future<void> close();
}

class _NativeTransport implements NeonTransport {
  Connection? _conn;

  Future<Connection> _connect() async {
    if (_conn != null && _conn!.isOpen) return _conn!;
    final host = dotenv.env['NEON_HOST']!;
    final db = dotenv.env['NEON_DB']!;
    final user = dotenv.env['NEON_USER']!;
    final pass = dotenv.env['NEON_PASSWORD']!;
    _conn = await Connection.open(
      Endpoint(host: host, database: db, username: user, password: pass, port: 5432),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    return _conn!;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) async {
    final c = await _connect();
    final result = await c.execute(Sql.named(sql), parameters: params ?? {});
    return result.map((r) => r.toColumnMap()).toList();
  }

  @override
  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }
}

class _WebTransport implements NeonTransport {
  late final String _endpoint;
  late final String _token;

  _WebTransport() {
    _endpoint = dotenv.env['API_ENDPOINT'] ?? '/api/sql';
    _token = dotenv.env['API_TOKEN'] ?? '';
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'sql': sql,
        'params': _serializeParams(params ?? const {}),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Proxy ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rows = (body['rows'] as List).cast<Map<String, dynamic>>();
    return rows.map(_deserializeRow).toList();
  }

  Map<String, dynamic> _serializeParams(Map<String, dynamic> p) {
    return p.map((k, v) {
      if (v is DateTime) return MapEntry(k, v.toUtc().toIso8601String());
      return MapEntry(k, v);
    });
  }

  Map<String, dynamic> _deserializeRow(Map<String, dynamic> row) {
    final out = <String, dynamic>{};
    row.forEach((k, v) {
      if (v is String && _looksLikeTimestamp(v)) {
        final parsed = DateTime.tryParse(v);
        out[k] = parsed ?? v;
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  bool _looksLikeTimestamp(String v) {
    if (v.length < 19) return false;
    return RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}').hasMatch(v);
  }

  @override
  Future<void> close() async {}
}

class NeonClient {
  static NeonClient? _instance;
  late final NeonTransport _transport;

  NeonClient._() {
    _transport = kIsWeb ? _WebTransport() : _NativeTransport();
  }

  static NeonClient get instance => _instance ??= NeonClient._();

  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) {
    return _transport.query(sql, params: params);
  }

  Future<void> close() => _transport.close();

  bool get webUnsupported => false;
}
