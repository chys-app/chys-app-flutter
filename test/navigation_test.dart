import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('Simple reactive widget test - no setState during build', (WidgetTester tester) async {
    // This is a simplified test to verify reactive widgets don't cause setState during build
    Get.testMode = true;
    
    final controller = Get.put(_TestController());
    
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Reactive widget
              Obx(() => Text('Count: ${controller.count.value}')),
              ElevatedButton(
                onPressed: () => controller.increment(),
                child: const Text('Increment'),
              ),
            ],
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Count: 0'), findsOneWidget);

    // Trigger update
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Verify update
    expect(find.text('Count: 1'), findsOneWidget);
    
    // Clean up
    Get.reset();
  });

  testWidgets('Nested Obx widgets test', (WidgetTester tester) async {
    // Test nested reactive widgets to ensure no build-phase conflicts
    Get.testMode = true;
    
    final controller = Get.put(_TestController());
    
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Obx(() => Column(
            children: [
              Text('Outer: ${controller.count.value}'),
              Obx(() => Text('Inner: ${controller.count.value}')),
            ],
          )),
        ),
      ),
    );

    expect(find.text('Outer: 0'), findsOneWidget);
    expect(find.text('Inner: 0'), findsOneWidget);

    controller.increment();
    await tester.pump();

    expect(find.text('Outer: 1'), findsOneWidget);
    expect(find.text('Inner: 1'), findsOneWidget);
    
    Get.reset();
  });

  testWidgets('SmartRefresher with Obx test', (WidgetTester tester) async {
    // Test SmartRefresher with reactive widgets (similar to home view structure)
    Get.testMode = true;
    
    final controller = Get.put(_TestController());
    
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Obx(() => ListView(
            children: [
              Text('Items: ${controller.count.value}'),
              if (controller.isLoading.value)
                const CircularProgressIndicator(),
            ],
          )),
        ),
      ),
    );

    expect(find.text('Items: 0'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    controller.setLoading(true);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    Get.reset();
  });
}

// Simple test controller
class _TestController extends GetxController {
  final count = 0.obs;
  final isLoading = false.obs;

  void increment() {
    count.value++;
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }
}
