import 'package:chys/app/widget/business/business_products_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows add button and empty grid when products list is empty',
      (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const BusinessProductsAddButton(),
              Expanded(
                child: BusinessProductsGrid(
                  products: const [],
                  scrollController: scrollController,
                  emptyState: const Center(child: Text('No products yet')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BusinessProductsAddButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(StaggeredGridView), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
  });
}
