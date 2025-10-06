import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chys/app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class ApiEndPoints {
  static const String petProfile = "/pet-profile";
  static const String allUsers = "/users/allUsers";
  static const String sendVerificationOtp = "/users/send-verification-otp";
  static const String verifyEmail = "/users/verify";
  static const String nearbyPet = "$petProfile/nearby-pets";
  static const String podcast = "/podcast";
  static const String editProfile = "/users/profile";
  static const String getDonations = "/users/getDonations";
  static const String updateDonation = "/users/updateAmount";
  static const String bankDetails = "/users/bank-details";
  static const String withdraw = "/users/withdraw";
  static const String sharePost = "/posts/share";
  static const String fundRaise = "/posts/fundRaise";
  static const String getFunds = "/posts/fund/podcast";
  static const String uploadMedia = "/chat/upload-media";
  static const String editPost = "/posts";
  static const String transactions = "/users/transaction-history";
  static const String sendOtp = "/users/send-reset-otp";
  static const String verifyOtp = "/users/verify-reset-otp";
  static const String resetPassword = "/users/reset-password";
  static const String followUnfollow = "/users/follow-toggle";
  static const String deleteAccount = "/users/account";
  static const String verificationStatus = "/users/verification-status";
  static const String resendVerificationEmail =
      "/users/resend-verification-email";
}

class ApiClient {
  static const String _defaultBaseUrl = "https://api.chys.app/api";
  final String baseUrl;
  Map<String, String> get headers => _getHeaders();

  ApiClient({this.baseUrl = _defaultBaseUrl});

  Map<String, String> _getHeaders() {
    final token = StorageService.getToken();
    print('token here : $token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  MediaType? _getMimeType(File file) {
    final ext = file.path.toLowerCase();
    if (ext.endsWith(".jpg") || ext.endsWith(".jpeg")) {
      return MediaType('image', 'jpeg');
    } else if (ext.endsWith(".png")) {
      return MediaType('image', 'png');
    } else if (ext.endsWith(".mp4")) {
      return MediaType('video', 'mp4');
    }
    return null;
  }

  Future<dynamic> _processResponse(http.Response response) async {
    log("Response: ${response.body}, Status Code: ${response.statusCode}");
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorResponse = jsonDecode(response.body);
        log("Error: Status Code: ${response.statusCode}, Body: $errorResponse");
        throw Exception(errorResponse['message'] ??
            errorResponse["msg"] ??
            "An unknown error occurred");
      }
    } on FormatException {
      log("Invalid response format ${response.body}");
      throw Exception("Invalid response format");
    }
  }

  Future<dynamic> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;
      return await _processResponse(response);
    } on SocketException {
      throw Exception("No internet connection");
    } on HttpException {
      throw Exception("Server error");
    } on FormatException {
      throw Exception("Invalid response format");
    } catch (e, stacktrace) {
      log("Error $e,$stacktrace");
      throw Exception("$e");
    }
  }


  Future<dynamic> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    log("GET Request: $url");
    return _handleRequest(http.get(Uri.parse(url), headers: headers));
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {Map<String, String>? customHeaders}) async {
    final url = '$baseUrl$endpoint';
    final requestHeaders = customHeaders ?? headers;

    log("POST Request: $url, Data: $data, Headers: $requestHeaders");

    return _handleRequest(http.post(
      Uri.parse(url),
      headers: requestHeaders,
      body: jsonEncode(data),
    ));
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    log("PUT Request: $url, Data: $data");
    return _handleRequest(http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ));
  }

  Future<dynamic> delete(String endpoint, [Map<String, dynamic>? data]) async {
    final url = '$baseUrl$endpoint';
    log("DELETE Request: $url, Data: $data");
    
    if (data != null) {
      return _handleRequest(http.delete(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ));
    } else {
      return _handleRequest(http.delete(
        Uri.parse(url),
        headers: headers,
      ));
    }
  }

  Future<dynamic> postFormData(String endpoint, Map<String, dynamic> data,
      {String requestMethod = "PUT"}) async {
    var request =
        http.MultipartRequest(requestMethod, Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll(headers);

    for (var key in data.keys) {
      var value = data[key];

      if (value is List<File>) {
        if (value.isEmpty) {
          log("⚠️ media list is json.");
        } else {
          log("📁 Found ${value.length} media files for key: $key");
        }

        for (var file in value) {
          final mime = _getMimeType(file);
          if (mime != null) {
            final fileStream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              key,
              fileStream,
              length,
              filename: basename(file.path),
              contentType: mime,
            );
            request.files.add(multipartFile);
            log("✅ Added file: ${file.path} (${mime.mimeType})");
          } else {
            log("❌ Skipping invalid file type: ${file.path}");
          }
        }
      } else if (value is File) {
        final mime = _getMimeType(value);
        if (mime != null) {
          final fileStream = http.ByteStream(value.openRead());
          final length = await value.length();
          final multipartFile = http.MultipartFile(
            key,
            fileStream,
            length,
            filename: basename(value.path),
            contentType: mime,
          );
          request.files.add(multipartFile);
        } else {
          log("❌ Invalid file type for key '$key': ${value.path}");
        }
      } else if (value is List<String>) {
        for (var id in value) {
          final part = await http.MultipartFile.fromString(
            key,
            id,
            filename: null,
          );
          request.files.add(part);
        }
      } else {
        request.fields[key] = value.toString();
      }
    }

    log("📤 Sending multipart form data to: $baseUrl$endpoint");
    log("🧾 Request fields: ${request.fields.keys.map((k) => '$k: ${request.fields[k]}').join(', ')}");

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    log("✅ Response Status: ${responseBody.statusCode}");
    log("📨 Response Body: ${responseBody.body}");

    return _processResponse(responseBody);
  }

  Future<dynamic> favoritePost(String postId) async {
    final url = '$baseUrl/posts/favorite/$postId';
    return _handleRequest(http.post(
      Uri.parse(url),
      headers: headers,
    ));
  }
}
