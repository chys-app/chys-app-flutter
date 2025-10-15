import 'dart:developer';
import 'http_service.dart';

class UserManagementService {
  static UserManagementService? _instance;
  static UserManagementService get instance =>
      _instance ??= UserManagementService._();

  UserManagementService._();

  final ApiClient _apiClient = ApiClient();

  /// Block a user
  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      log("🔄 Blocking user: $userId");

      final response = await _apiClient.post("/users/block/$userId", {});

      if (response != null && response['success'] == true) {
        log("✅ User blocked successfully: $userId");
        return {
          'success': true,
          'message': response['message'] ?? 'User blocked successfully',
          'data': response['data']
        };
      } else {
        log("❌ Failed to block user: ${response?['message']}");
        return {
          'success': false,
          'message': response?['message'] ?? 'Failed to block user'
        };
      }
    } catch (e) {
      log("❌ Error blocking user: $e");
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  /// Unblock a user
  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      log("🔄 Unblocking user: $userId");

      final response = await _apiClient.delete("/users/block/$userId");

      if (response != null && response['success'] == true) {
        log("✅ User unblocked successfully: $userId");
        return {
          'success': true,
          'message': response['message'] ?? 'User unblocked successfully',
          'data': response['data']
        };
      } else {
        log("❌ Failed to unblock user: ${response?['message']}");
        return {
          'success': false,
          'message': response?['message'] ?? 'Failed to unblock user'
        };
      }
    } catch (e) {
      log("❌ Error unblocking user: $e");
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  /// Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      log("🔄 Fetching blocked users");

      final response = await _apiClient.get("/users/blocked-users");

      if (response != null && response['success'] == true) {
        final List<dynamic> blockedUsers = response['blockedUsers'] ?? [];
        log("✅ Fetched ${blockedUsers.length} blocked users");
        return blockedUsers.cast<Map<String, dynamic>>();
      } else {
        log("❌ Failed to fetch blocked users: ${response?['message']}");
        return [];
      }
    } catch (e) {
      log("❌ Error fetching blocked users: $e");
      return [];
    }
  }

  /// Report a user
  Future<Map<String, dynamic>> reportUser({
    required String userId,
    required String reason,
    String? description,
    List<String>? evidence,
  }) async {
    try {
      log("🔄 Reporting user: $userId");

      final Map<String, dynamic> reportData = {
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (evidence != null && evidence.isNotEmpty) 'evidence': evidence,
      };

      final response =
          await _apiClient.post("/users/report/$userId", reportData);

      if (response != null && response['success'] == true) {
        log("✅ User reported successfully: $userId");
        return {
          'success': true,
          'message': response['message'] ?? 'User reported successfully',
          'data': response['data']
        };
      } else {
        log("❌ Failed to report user: ${response?['message']}");
        return {
          'success': false,
          'message': response?['message'] ?? 'Failed to report user'
        };
      }
    } catch (e) {
      log("❌ Error reporting user: $e");
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

    /// Get list of reported users
  Future<List<Map<String, dynamic>>> getReportedUsers() async {
    try {
      log("🔄 Fetching reported users");
      
      final response = await _apiClient.get("/users/reported-users");
      
      if (response != null && response['success'] == true) {
        final List<dynamic> reportedUsers = response['reportedUsers'] ?? [];
        log("✅ Fetched ${reportedUsers.length} reported users");
        return reportedUsers.cast<Map<String, dynamic>>();
      } else {
        log("❌ Failed to fetch reported users: ${response?['message']}");
        return [];
      }
    } catch (e) {
      log("❌ Error fetching reported users: $e");
      return [];
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers
          .any((user) => user['_id'] == userId || user['id'] == userId);
    } catch (e) {
      log("❌ Error checking if user is blocked: $e");
      return false;
    }
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedByUser(String userId) async {
    try {
      // This would require a different endpoint or checking the relationship
      // For now, we'll assume if we can't see their content, we're blocked
      return false;
    } catch (e) {
      log("❌ Error checking if blocked by user: $e");
      return false;
    }
  }

  /// Get report reasons for dropdown
  List<Map<String, String>> getReportReasons() {
    return [
      {'value': 'harassment', 'label': 'Harassment or Bullying'},
      {'value': 'spam', 'label': 'Spam or Misleading Content'},
      {'value': 'inappropriate', 'label': 'Inappropriate Content'},
      {'value': 'fake_profile', 'label': 'Fake Profile'},
      {'value': 'violence', 'label': 'Violence or Threats'},
      {'value': 'other', 'label': 'Other'},
    ];
  }
}
