import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'dart:async';

class NetworkService extends GetxService {
  final _connectivity = Connectivity();
  final isConnected = true.obs;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<NetworkService> init() async {
    try {
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          print('Connectivity error: $error');
          isConnected.value = false;
        },
      );

      // Get initial connection status
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('NetworkService initialization error: $e');
      isConnected.value = false;
    }

    return this;
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    try {
      isConnected.value = result != ConnectivityResult.none;
    } catch (e) {
      print('Error updating connection status: $e');
      isConnected.value = false;
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
