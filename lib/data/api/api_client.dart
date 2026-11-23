import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitopia/presentation/resources/index_manager.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);

  Uri _uri(String path) {
    if (AppStrings.appBaseUrl.isEmpty) {
      throw ApiException(
        'The API base URL is not configured. '
        'Run the app with --dart-define=APP_BASE_URL=...',
      );
    }

    return Uri.parse(AppStrings.appBaseUrl).resolve(path);
  }

  Future<Map<String, dynamic>> postData(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(path);

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decodedBody = _decodeErrorBody(response);
        if (response.statusCode == 401) {
          await _clearExpiredSession();
        }
        throw ApiException(
          _messageFromResponse(
            response.statusCode,
            decodedBody,
            'The request failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      return _decodeBody(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the API. Check that the backend is running.',
      );
    }
  }

  Future<Map<String, dynamic>> getData(String path) async {
    final uri = _uri(path);
    final headers = _authenticatedHeaders();

    try {
      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decodedBody = _decodeErrorBody(response);
        if (response.statusCode == 401) {
          await _clearExpiredSession();
        }
        throw ApiException(
          _messageFromResponse(
            response.statusCode,
            decodedBody,
            'The request failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      return _decodeBody(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the API. Check that the backend is running.',
      );
    }
  }

  Future<Map<String, dynamic>> postAuthenticatedData(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(path);
    final headers = _authenticatedHeaders();

    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      final decodedBody = _decodeBody(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _clearExpiredSession();
        }
        throw ApiException(
          _messageFromResponse(
            response.statusCode,
            decodedBody,
            'The request failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      return decodedBody;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the API. Check that the backend is running.',
      );
    }
  }

  Future<Map<String, dynamic>> postAuthenticatedMultipart(
    String path, {
    required File file,
    required String fieldName,
  }) async {
    final headers = _authenticatedHeaders()..remove('Content-Type');
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    try {
      final response = await http.Response.fromStream(
        await request.send().timeout(_timeout),
      );
      final decodedBody = _decodeBody(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _clearExpiredSession();
        }
        throw ApiException(
          _messageFromResponse(
            response.statusCode,
            decodedBody,
            'The request failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      return decodedBody;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the API. Check that the backend is running.',
      );
    }
  }

  Future<List<int>> getAuthenticatedBytes(String path) async {
    try {
      final response = await http
          .get(_uri(path), headers: _authenticatedHeaders())
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _clearExpiredSession();
        }
        throw ApiException(
          'The export request failed.',
          statusCode: response.statusCode,
        );
      }
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the API. Check that the backend is running.',
      );
    }
  }

  Map<String, String> _authenticatedHeaders() {
    final token = GetStorage().read<String>('api_token');
    if (token == null || token.isEmpty) {
      throw ApiException('You must be logged in to make this request.');
    }

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Timezone-Offset': DateTime.now().timeZoneOffset.inMinutes.toString(),
    };
  }

  Future<void> _clearExpiredSession() async {
    final storage = GetStorage();
    await storage.remove('api_token');
    await storage.remove('refresh_token');
    await storage.remove('user_data');
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Fall through to the explicit API error below.
    }

    throw ApiException(
      'The API returned an invalid response.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeErrorBody(http.Response response) {
    try {
      return _decodeBody(response);
    } on ApiException {
      return <String, dynamic>{};
    }
  }

  String _messageFrom(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is String && error.isNotEmpty) {
      return error;
    }

    final message = body['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }

  String _messageFromResponse(
    int statusCode,
    Map<String, dynamic> body,
    String fallback,
  ) {
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    return _messageFrom(body, fallback);
  }
}
