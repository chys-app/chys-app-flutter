import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../modules/map/controllers/map_controller.dart';

class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _updateSelectedFeature(String? routeName) {
    final mapController = Get.isRegistered<MapController>() ? Get.find<MapController>() : null;
    if (mapController == null) return;

    // Map your route names to features
    switch (routeName) {
      case '/home':
        mapController.selectedFeature.value = 'user';
        break;
      case '/podcast':
        mapController.selectedFeature.value = 'podcast';
        break;
      case '/chat':
        mapController.selectedFeature.value = 'chat';
        break;
      case '/addPost':
        mapController.selectedFeature.value = 'add';
        break;
      case '/map':
        mapController.selectedFeature.value = 'map';
        break;
      // Add more as needed
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _updateSelectedFeature(previousRoute?.settings.name);
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _updateSelectedFeature(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _updateSelectedFeature(newRoute?.settings.name);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
} 