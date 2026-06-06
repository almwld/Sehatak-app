import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FirestoreRest {
  static const String _projectId = 'sehatak-platform';
  static const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  static Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>?> getDocument(String path) async {
    final token = await _getToken();
    if (token == null) return null;
    final res = await http.get(Uri.parse('$_baseUrl/$path'), headers: _headers(token));
    if (res.statusCode == 200) return _parseDocument(jsonDecode(res.body));
    return null;
  }

  static Future<bool> setDocument(String path, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return false;
    final res = await http.patch(Uri.parse('$_baseUrl/$path'), headers: _headers(token), body: jsonEncode({'fields': _encodeFields(data)}));
    return res.statusCode == 200;
  }

  static Future<String?> addDocument(String collectionPath, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return null;
    final res = await http.post(Uri.parse('$_baseUrl/$collectionPath'), headers: _headers(token), body: jsonEncode({'fields': _encodeFields(data)}));
    if (res.statusCode == 200) { final body = jsonDecode(res.body); return (body['name'] as String).split('/').last; }
    return null;
  }

  static Future<List<Map<String, dynamic>>> query({
    required String collectionPath,
    List<Map<String, dynamic>> filters = const [],
    String? orderBy,
    int? limit,
  }) async {
    final token = await _getToken();
    if (token == null) return [];
    final body = {
      'structuredQuery': {
        'from': [{'collectionId': collectionPath.split('/').last}],
        if (filters.isNotEmpty) 'where': filters.length == 1 ? filters.first : {'compositeFilter': {'op': 'AND', 'filters': filters}},
        if (orderBy != null) 'orderBy': [{'field': {'fieldPath': orderBy}}],
        if (limit != null) 'limit': limit,
      }
    };
    final parent = collectionPath.contains('/') ? '$_baseUrl/${collectionPath.substring(0, collectionPath.lastIndexOf('/'))}' : _baseUrl.replaceAll('/documents', '/documents');
    final res = await http.post(Uri.parse('https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:runQuery'), headers: _headers(token), body: jsonEncode(body));
    if (res.statusCode == 200) {
      final List results = jsonDecode(res.body);
      return results.where((r) => r['document'] != null).map<Map<String, dynamic>>((r) => _parseDocument(r['document'])).toList();
    }
    return [];
  }

  static Future<bool> deleteDocument(String path) async {
    final token = await _getToken();
    if (token == null) return false;
    final res = await http.delete(Uri.parse('$_baseUrl/$path'), headers: _headers(token));
    return res.statusCode == 200;
  }

  static Map<String, dynamic> _encodeFields(Map<String, dynamic> data) => data.map((k, v) => MapEntry(k, _encodeValue(v)));
  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is List) return {'arrayValue': {'values': value.map(_encodeValue).toList()}};
    if (value is Map<String, dynamic>) return {'mapValue': {'fields': _encodeFields(value)}};
    return {'stringValue': value.toString()};
  }

  static Map<String, dynamic> _parseDocument(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final parsed = fields.map((k, v) => MapEntry(k, _decodeValue(v)));
    if (doc['name'] != null) parsed['id'] = (doc['name'] as String).split('/').last;
    return parsed;
  }

  static dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) return int.parse(value['integerValue']);
    if (value.containsKey('doubleValue')) return value['doubleValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('timestampValue')) return DateTime.parse(value['timestampValue']);
    if (value.containsKey('arrayValue')) { final vals = value['arrayValue']['values'] as List? ?? []; return vals.map(_decodeValue).toList(); }
    if (value.containsKey('mapValue')) { final f = value['mapValue']['fields'] as Map<String, dynamic>? ?? {}; return f.map((k, v) => MapEntry(k, _decodeValue(v))); }
    return null;
  }

  static Map<String, dynamic> whereEquals(String field, dynamic value) => {'fieldFilter': {'field': {'fieldPath': field}, 'op': 'EQUAL', 'value': _encodeValue(value)}};
}
