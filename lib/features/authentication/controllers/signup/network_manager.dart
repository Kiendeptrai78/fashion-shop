import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/utils/device/device_utility.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;
  Timer? _offlineDebounce;

  @override
  void onInit() {
    super.onInit();
    if (kIsWeb) return;
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Debounce transient `none` events (common on iOS cold start / simulator)
  /// and double-check actual reachability before alerting the user.
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    _connectionStatus.value = result;
    _offlineDebounce?.cancel();

    if (result == ConnectivityResult.none) {
      _offlineDebounce = Timer(const Duration(milliseconds: 900), () async {
        final hasInternet = await TDeviceUtils.hasInternetConnection();
        if (!hasInternet && _connectionStatus.value == ConnectivityResult.none) {
          TLoaders.warningSnackBar(title: 'No Internet connection');
        }
      });
    }
  }

  /// Check the internet connection status.
  /// Returns `true` if connected, `false` otherwise.
  Future<bool> isConnected() async {
    if (kIsWeb) return true;
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        return await TDeviceUtils.hasInternetConnection();
      }
      return true;
    } on PlatformException catch (_) {
      return await TDeviceUtils.hasInternetConnection();
    }
  }

  @override
  void onClose() {
    _offlineDebounce?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
