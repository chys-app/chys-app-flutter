import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chys/app/core/const/app_secrets.dart';
import 'package:chys/app/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CustomApiService extends GetxService {
  final String baseUrl = AppSecrets.apiBaseUrl;

  // You can store token here if using Auth
  String? token;

  Map<String, String> getHeaders({bool isJson = true}) {
    final token = StorageService.getToken();

    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return headers;
  }

  /// GET request
  Future<dynamic> getRequest(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    log("URI$uri");
    final response = await http.get(uri, headers: getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('GET failed: ${response.statusCode} → ${response.body}');
    }
  }

  /// POST request with JSON body
  Future<dynamic> postRequest(
      String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('POST failed: ${response.statusCode} → ${response.body}');
    }
  }

  /// Toggle follow status for a user
  Future<bool> toggleFollow(String userId) async {
    final response = await postRequest('users/follow-toggle/$userId', {});
    return response['isFollowing'] as bool;
  }

  /// PUT request with JSON body
  Future<dynamic> putRequest(
      String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.put(
      uri,
      headers: getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('PUT failed: ${response.statusCode} → ${response.body}');
    }
  }

  /// DELETE request
  Future<dynamic> deleteRequest(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.delete(uri, headers: getHeaders());

    if (response.statusCode == 200 || response.statusCode == 204) {
      return {'status': 'deleted'};
    } else {
      throw Exception(
          'DELETE failed: ${response.statusCode} → ${response.body}');
    }
  }

  /// Track story view
  Future<dynamic> trackStoryView(String storyId) async {
    try {
      // Use the same pattern as post view tracking
      return await postRequest('stories/$storyId/view', {});
    } catch (e) {
      log("❌ [STORY VIEW] Failed to track view using postRequest: $e");
      
      // Fallback to direct HTTP call with detailed logging
      final uri = Uri.parse('$baseUrl/stories/$storyId/view');
      log("📊 [STORY VIEW] Fallback - Tracking view for story: $storyId");
      log("📊 [STORY VIEW] Fallback - Full URL: $uri");
      log("📊 [STORY VIEW] Fallback - Headers: ${getHeaders()}");
      
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({}), // Empty body as per API spec
      );

      log("📊 [STORY VIEW] Fallback - Response status: ${response.statusCode}");
      log("📊 [STORY VIEW] Fallback - Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ [STORY VIEW] Successfully tracked view for story: $storyId");
        return jsonDecode(response.body);
      } else {
        log("❌ [STORY VIEW] Failed to track view: ${response.statusCode} → ${response.body}");
        throw Exception('STORY VIEW tracking failed: ${response.statusCode} → ${response.body}');
      }
    }
  }

  /// Upload image with additional fields (Multipart)
  Future<dynamic> uploadImage({
    required String endpoint,
    required List<File> imageFiles,
    Map<String, String>? fields,
    String imageField = 'media',
    String method = 'POST',
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    log("📤 [UPLOAD] Request URI: $uri");

    final request = http.MultipartRequest(method, uri);

    // Get token from storage and add headers
    final token = StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      log("🔐 [UPLOAD] Using token: Bearer $token");
    }

    // Attach image files with robust MIME detection (supports .temp filenames)
    for (File file in imageFiles) {
      String? mimeType = lookupMimeType(file.path);
      MediaType? contentType;

      // If extension-based detection failed, try sniffing header bytes
      if (mimeType == null) {
        try {
          final headerBytes = await file.openRead(0, 64).first;
          mimeType = lookupMimeType(file.path, headerBytes: headerBytes);
        } catch (e) {
          // Ignore and fallback below
          log("⚠️ [UPLOAD] Failed header sniff for ${file.path}: $e");
        }
      }

      if (mimeType != null) {
        final parts = mimeType.split('/');
        if (parts.length == 2) {
          contentType = MediaType(parts[0], parts[1]);
        }
      }

      log("📎 [UPLOAD] Adding file: ${file.path} with MIME: ${mimeType ?? 'unknown'}");

      // Do not throw on unknown; let server infer if possible
      request.files.add(
        await http.MultipartFile.fromPath(
          imageField,
          file.path,
          contentType: contentType, // may be null; http will omit header
        ),
      );
    }
    // Add any additional fields
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
      log("📝 [UPLOAD] Fields: ${jsonEncode(fields)}");
    }

    // Send the request
    log("🚀 [UPLOAD] Sending request...");
    final streamedResponse = await request.send();
    final responseString = await streamedResponse.stream.bytesToString();

    log("📩 [UPLOAD] Response Code: ${streamedResponse.statusCode}");
    log("📨 [UPLOAD] Response Body: $responseString");

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      return jsonDecode(responseString);
    } else {
      throw Exception(
        'UPLOAD failed: ${streamedResponse.statusCode} → $responseString',
      );
    }
  }

  /// Upload story with media and caption
  Future<dynamic> uploadStory({
    required File mediaFile,
    required String caption,
  }) async {
    final uri = Uri.parse('$baseUrl/story');
    log("📤 [STORY UPLOAD] Request URI: $uri");

    final request = http.MultipartRequest('POST', uri);

    // Get token from storage and add headers
    final token = StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      log("🔐 [UPLOAD] Using token: Bearer $token");
    }

    // Add media file
    final mimeType = lookupMimeType(mediaFile.path);
    final mediaType = mimeType?.split('/');

    if (mediaType == null || mediaType.length != 2) {
      throw Exception(
          "❌ Unable to detect MIME type of file: ${mediaFile.path}");
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'media',
        mediaFile.path,
        contentType: MediaType(mediaType[0], mediaType[1]),
      ),
    );

    // Add caption
    request.fields['caption'] = caption;

    // Send the request
    log("🚀 [STORY UPLOAD] Sending request...");
    final streamedResponse = await request.send();
    final responseString = await streamedResponse.stream.bytesToString();

    log("📩 [STORY UPLOAD] Response Code: ${streamedResponse.statusCode}");
    log("📨 [STORY UPLOAD] Response Body: $responseString");

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      return jsonDecode(responseString);
    } else {
      throw Exception(
        'STORY UPLOAD failed: ${streamedResponse.statusCode} → $responseString',
      );
    }
  }
}
