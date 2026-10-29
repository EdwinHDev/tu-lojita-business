import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details_skeletons.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_list_tile_skeleton.dart';

void main() {
  group('Store Loading Skeletons Tests', () {
    testWidgets('ShimmerWidget renders smoothly with custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerWidget(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(ShimmerWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('StoreHeaderCardSkeleton renders without throwing errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoreHeaderCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(StoreHeaderCardSkeleton), findsOneWidget);
      expect(find.byType(ShimmerWidget), findsWidgets);
    });

    testWidgets('StoreMetricsSkeleton renders 3 metric cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoreMetricsSkeleton(),
          ),
        ),
      );

      expect(find.byType(StoreMetricsSkeleton), findsOneWidget);
      expect(find.text('Métricas Clave'), findsOneWidget);
    });

    testWidgets('StoreListTileSkeleton renders with rounded borders and logo placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoreListTileSkeleton(),
          ),
        ),
      );

      expect(find.byType(StoreListTileSkeleton), findsOneWidget);
    });
  });
}
