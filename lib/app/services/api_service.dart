import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../data/controllers/location_controller.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.chys.app/api';
  final _client = http.Client();
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 1);
  static const _maxImageSize = 1 * 1024 * 1024; // 1MB in bytes
  final controller = Get.find<LocationController>();
  // Get auth headers with token
  Map<String, String> get _headers {
    final token = StorageService.getToken();
    print('token here : ${token}');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper function to compress image
  Future<String> compressImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();

      // If image is already small enough, return original path
      if (bytes.length <= _maxImageSize) {
        return imagePath;
      }

      // Decode image
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Could not decode image');

      // Calculate new dimensions while maintaining aspect ratio
      int targetWidth = image.width;
      int targetHeight = image.height;
      double scale = 1.0;

      // Reduce size until the image is small enough
      while ((targetWidth * targetHeight * 4) > _maxImageSize) {
        scale *= 0.8;
        targetWidth = (image.width * scale).round();
        targetHeight = (image.height * scale).round();
      }

      // Resize image
      final img.Image resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String targetPath =
          '$tempPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Encode and save compressed image
      final File compressedFile = File(targetPath);
      await compressedFile
          .writeAsBytes(img.encodeJpg(resizedImage, quality: 85));

      print(
          'Original size: ${bytes.length}, Compressed size: ${await compressedFile.length()}');
      return targetPath;
    } catch (e) {
      print('Error compressing image: $e');
      return imagePath; // Return original path if compression fails
    }
  }

  Future<Map<String, dynamic>> _handleMultipartRequest(
    Future<http.StreamedResponse> Function() request,
  ) async {
    // if (!await _networkService.checkConnection()) {
    //   return {
    //     'success': false,
    //     'message': 'No internet connection',
    //   };
    // }

    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final response = await request();

        if (response.statusCode == 413) {
          return {
            'success': false,
            'message': 'Files are too large. Please use smaller images.',
          };
        }

        final responseBody = await response.stream.bytesToString();
        print('Response status code: ${response.statusCode}');
        print('Response body: $responseBody');

        if (responseBody.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Empty response from server',
          };
        }

        try {
          final data = jsonDecode(responseBody);
          if (response.statusCode == 200 || response.statusCode == 201) {
            return {
              'success': true,
              'data': data,
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'Request failed',
            };
          }
        } on FormatException catch (e) {
          print('Response is not JSON: $responseBody');
          return {
            'success': false,
            'message': 'Invalid server response: $responseBody',
          };
        }
      } on SocketException catch (e) {
        print('Socket Exception: $e');
        if (retryCount == _maxRetries - 1) {
          return {
            'success': false,
            'message': 'Unable to connect to server',
          };
        }
      } catch (e) {
        print('Unexpected error: $e');
        return {
          'success': false,
          'message': 'An unexpected error occurred',
        };
      }

      retryCount++;
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * retryCount);
      }
    }

    return {
      'success': false,
      'message': 'Request failed after multiple attempts',
    };
  }

  Future<Map<String, dynamic>> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    // if (!await _networkService.checkConnection()) {
    //   return {
    //     'success': false,
    //     'message': 'No internet connection',
    //   };
    // }

    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final response = await request();
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (data['user'] != null) {
            await StorageService.saveUser(data['user'] as Map<String, dynamic>);
          }

          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Request failed',
          };
        }
      } on SocketException catch (e) {
        print('Socket Exception: $e');
        if (retryCount == _maxRetries - 1) {
          return {
            'success': false,
            'message': 'Unable to connect to server',
          };
        }
      } on HttpException catch (e) {
        print('HTTP Exception: $e');
        return {
          'success': false,
          'message': 'Unable to complete request',
        };
      } on FormatException catch (e) {
        print('Format Exception: $e');
        return {
          'success': false,
          'message': 'Invalid response format',
        };
      } catch (e) {
        print('Unexpected error: $e');
        return {
          'success': false,
          'message': 'An unexpected error occurred',
        };
      }

      retryCount++;
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * retryCount);
      }
    }

    return {
      'success': false,
      'message': 'Request failed after multiple attempts',
    };
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? username,
  }) async {
    String token = await NotificationUtil().getToken();

    final result = await _handleRequest(() => _client.post(
          Uri.parse('$baseUrl/users/register'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
            'lat': controller.latitude.value,
            "lng": controller.longitude.value,
            "fcmToken": token,
            if (username != null) 'username': username,
          }),
        ));

    // Print token for debugging
    if (result['success']) {
      // final token = StorageService.saveToken(token);
      //print('DEBUG: Token after registration: $token');
    }

    return result;
  }

  // Method to check if user is authenticated
  bool isAuthenticated() {
    final token = StorageService.getToken();
    print('DEBUG: Current token: $token');
    return token != null;
  }

  // Method to get current user
  Map<String, dynamic>? getCurrentUser() {
    return StorageService.getUser();
  }

  // Method to logout
  Future<void> logout() async {
    await StorageService.clearStorage();
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    String token = await NotificationUtil().getToken();
    final data = {
      'email': email,
      'password': password,
      'lat': controller.latitude.value,
      "lng": controller.longitude.value,
      "fcmToken": token
    };
    log("Requested data is ${data}");
    final result = await _handleRequest(() => _client.post(
          Uri.parse('$baseUrl/users/login'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(data),
        ));
    log("Response is ${result}");

    // Print token for debugging
    if (result['success']) {
      final token = StorageService.getToken();
      print('DEBUG: Token after login: $token');
    }

    return result;
  }

  String formatDateForApi(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  Future<Map<String, dynamic>> createPetProfile(
      Map<String, dynamic> petData, bool isEdit) async {
    //log("Pet data is ${petData["dateOfBirth"]} ${petData["dateOfBirth"].runtimeType}");
    print(
        'DEBUG: Using token for pet profile creation: ${StorageService.getToken()}');

    final request = http.MultipartRequest(
      isEdit ? 'PUT' : 'POST',
      Uri.parse('$baseUrl/pet-profile'),
    );

    // Add headers
    request.headers.addAll(_headers);

    // Convert List to JSON string
    String formatArrayAsJsonString(List items) => jsonEncode(items);

    // Prepare basic form fields
    final fieldsToAdd = {
      'isHavePet': petData['isHavePet']?.toString() ?? 'true',
      'petType': petData['petType']?.toString() ?? '',
      'name': petData['name']?.toString() ?? '',
      'breed': petData['breed']?.toString() ?? '',
      'sex': petData['sex']?.toString()?.toLowerCase() ?? '',
      'dateOfBirth': (() {
        final dobRaw = petData['dateOfBirth']?.toString().trim();
        if (dobRaw == null || dobRaw.isEmpty) return '';
        if (isEdit) return dobRaw;

        // Try to parse manually since the input is like "01 / 07 / 2025"
        try {
          final parts = dobRaw.split('/').map((e) => e.trim()).toList();
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final parsedDate = DateTime(year, month, day);
            return formatDateForApi(parsedDate);
          }
        } catch (e) {
          print('❌ Invalid date format: $dobRaw');
        }

        return ''; // fallback
      })(),
      'bio': petData['bio']?.toString() ?? '',
      'color': petData['color']?.toString() ?? '',
      'size': petData['size']?.toString() ?? '',
      'weight': petData['weight']?.toString() ?? '',
      'marks': petData['marks']?.toString() ?? '',
      'microchipNumber': petData['microchipNumber']?.toString() ?? '',
      'tagId': petData['tagId']?.toString() ?? '',
      'lostStatus': petData['lostStatus']?.toString() ?? 'false',
      'vaccinationStatus': petData['vaccinationStatus']?.toString() ?? 'false',
      'vetName': petData['vetName']?.toString() ?? '',
      'vetContactNumber': petData['vetContactNumber']?.toString() ?? '',
      'personalityTraits': petData['personalityTraits'] != null
          ? formatArrayAsJsonString(petData['personalityTraits'] as List)
          : '[]',
      'allergies': petData['allergies'] != null
          ? formatArrayAsJsonString(petData['allergies'] as List)
          : '[]',
      'specialNeeds': petData['specialNeeds']?.toString() ?? '',
      'feedingInstructions': petData['feedingInstructions']?.toString() ?? '',
      'dailyRoutine': petData['dailyRoutine']?.toString() ?? '',
      'ownerContactNumber': petData['ownerContactNumber']?.toString() ?? '',
      'address': petData['address'] != null ? jsonEncode(petData['address']) : '{}',
      'petId': petData['petId']?.toString() ?? '',
      'removePhotos': petData['removePhotos'] != null
          ? formatArrayAsJsonString(petData['removePhotos'] as List)
          : '[]',
    };

    fieldsToAdd.forEach((key, value) {
      request.fields[key] = value;
    });

    // Helper: detect MIME type
    MediaType? getMimeType(String path) {
      final ext = path.toLowerCase();
      if (ext.endsWith('.jpg') || ext.endsWith('.jpeg'))
        return MediaType('image', 'jpeg');
      if (ext.endsWith('.png')) return MediaType('image', 'png');
      if (ext.endsWith('.mp4')) return MediaType('video', 'mp4');
      return null;
    }

    // Handle profilePic upload
    final profilePicPath = petData['profilePic']?.toString();
    if (profilePicPath != null && profilePicPath.isNotEmpty) {
      final isLocal =
          profilePicPath.startsWith('/') || profilePicPath.contains('file://');
      if (isLocal) {
        try {
          final compressedPath = await compressImage(profilePicPath);
          final mimeType = getMimeType(compressedPath);
          if (mimeType != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'profilePic',
              compressedPath,
              contentType: mimeType,
            ));
          } else {
            print('⚠️ Invalid profilePic file type: $profilePicPath');
          }
        } catch (e) {
          print('❌ Error adding profile picture: $e');
        }
      } else {
        print(
            '📸 Skipping profilePic upload (not a local file): $profilePicPath');
      }
    }

    // Handle multiple photo uploads (for both new pets and edit mode)
    if (petData['photos'] != null && petData['photos'] is List) {
      const photosFieldName = 'photos';
      print('🗂 Using field for additional photos: ' + photosFieldName);
      for (final photo in (petData['photos'] as List)) {
        if (photo == null || photo.toString().isEmpty) continue;

        // Check if this is a local file path (starts with /) or a URL
        if (photo.toString().startsWith('/') ||
            photo.toString().contains('file://')) {
          // This is a local file, upload it
          try {
            final compressedPath = await compressImage(photo.toString());
            final mimeType = getMimeType(compressedPath);
            if (mimeType != null) {
              request.files.add(await http.MultipartFile.fromPath(
                photosFieldName,
                compressedPath,
                contentType: mimeType,
              ));
            } else {
              print('⚠️ Invalid photo file type: $photo');
            }
          } catch (e) {
            print('❌ Error adding photo: $e');
          }
        } else {
          // This is a URL, don't upload it as a file
          print('📸 Skipping URL upload: $photo');
        }
      }
    }

    // Debug
    print('📦 Request fields: ${request.fields}');
    print(
        '🖼 Request files: ${request.files.map((f) => '${f.filename} (${f.contentType})').toList()}');

    // Send request
    return _handleMultipartRequest(() => request.send());
  }

  /// Upload pet profile image only - dedicated API for image upload
  Future<Map<String, dynamic>> uploadPetProfileImage(File imageFile) async {
    print(
        'DEBUG: Using token for pet profile image upload: ${StorageService.getToken()}');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/pet-profile'),
    );
    print('Request ${request}');
    // Add headers
    request.headers.addAll(_headers);

    // Helper: detect MIME type
    MediaType? getMimeType(String path) {
      final ext = path.toLowerCase();
      if (ext.endsWith('.jpg') || ext.endsWith('.jpeg'))
        return MediaType('image', 'jpeg');
      if (ext.endsWith('.png')) return MediaType('image', 'png');
      return null;
    }

    // Add the image file
    try {
      final compressedPath = await compressImage(imageFile.path);
      final mimeType = getMimeType(compressedPath);
      if (mimeType != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profilePic',
          compressedPath,
          contentType: mimeType,
        ));
        print('Request ${request}');
        print('📸 Added profile image: ${imageFile.path}');
      } else {
        print('⚠️ Invalid image file type: ${imageFile.path}');
        throw Exception('Invalid image file type');
      }
    } catch (e) {
      print('❌ Error adding profile image: $e');
      throw Exception('Failed to process image file');
    }


    return _handleMultipartRequest(() => request.send());
  }

  /// Remove pet photos - dedicated API for photo removal
  Future<Map<String, dynamic>> removePetPhotos(List<String> photoUrls) async {
    print(
        'DEBUG: Using token for pet photo removal: ${StorageService.getToken()}');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/pet-profile'),
    );

    // Add headers
    request.headers.addAll(_headers);

    request.fields['removePhotos'] = jsonEncode(photoUrls);

    // Send request
    return _handleMultipartRequest(() => request.send());
  }

  /// Upload additional pet photos - dedicated API for photo upload
  Future<Map<String, dynamic>> uploadPetPhotos(List<File> photoFiles) async {
    print(
        'DEBUG: Using token for pet photo upload: ${StorageService.getToken()}');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/pet-profile'),
    );

    // Add headers
    request.headers.addAll(_headers);

    // Helper: detect MIME type
    MediaType? getMimeType(String path) {
      final ext = path.toLowerCase();
      if (ext.endsWith('.jpg') || ext.endsWith('.jpeg'))
        return MediaType('image', 'jpeg');
      if (ext.endsWith('.png')) return MediaType('image', 'png');
      return null;
    }

    // Add photo files with 'photos' key
    for (final photoFile in photoFiles) {
      try {
        final compressedPath = await compressImage(photoFile.path);
        final mimeType = getMimeType(compressedPath);
        if (mimeType != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'photos',
            compressedPath,
            contentType: mimeType,
          ));
          print('📸 Added photo: ${photoFile.path}');
        } else {
          print('⚠️ Invalid photo file type: ${photoFile.path}');
        }
      } catch (e) {
        print('❌ Error adding photo: $e');
      }
    }

    // Debug
    print('📦 Photo upload - Request fields: ${request.fields}');
    print('🖼 Photo upload - Request files: ${request.files.map((f) => '${f.filename} (${f.contentType})').toList()}');

    // Send request
    return _handleMultipartRequest(() => request.send());
  }

  @override
  void onClose() {
    _client.close();
  }
}
