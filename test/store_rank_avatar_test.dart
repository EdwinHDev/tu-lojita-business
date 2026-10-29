import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/ranking/presentation/widgets/store_rank_avatar.dart';

void main() {
  group('StoreRankAvatar Division Normalization', () {
    test('normalizes primary divisions correctly', () {
      expect(StoreRankAvatar.normalizeDivision('PUESTO_AMBULANTE'), 'puesto_ambulante');
      expect(StoreRankAvatar.normalizeDivision('CARRITO_VENTAS'), 'carrito_ventas');
      expect(StoreRankAvatar.normalizeDivision('TIENDITA_BARRIO'), 'tiendita_barrio');
      expect(StoreRankAvatar.normalizeDivision('LOCAL_ESTABLECIDO'), 'local_establecido');
      expect(StoreRankAvatar.normalizeDivision('TIENDA_MARCA'), 'tienda_marca');
      expect(StoreRankAvatar.normalizeDivision('GRAN_DISTRIBUIDOR'), 'gran_distribuidor');
      expect(StoreRankAvatar.normalizeDivision('IMPERIO_COMERCIAL'), 'imperio_comercial');
      expect(StoreRankAvatar.normalizeDivision('MAGNATE_MERCADO'), 'magnate_mercado');
    });

    test('normalizes legacy aliases correctly', () {
      expect(StoreRankAvatar.normalizeDivision('HIERRO'), 'puesto_ambulante');
      expect(StoreRankAvatar.normalizeDivision('BRONCE'), 'carrito_ventas');
      expect(StoreRankAvatar.normalizeDivision('PLATA'), 'tiendita_barrio');
      expect(StoreRankAvatar.normalizeDivision('ORO'), 'local_establecido');
      expect(StoreRankAvatar.normalizeDivision('PLATINO'), 'tienda_marca');
      expect(StoreRankAvatar.normalizeDivision('ESMERALDA'), 'gran_distribuidor');
      expect(StoreRankAvatar.normalizeDivision('DIAMANTE'), 'imperio_comercial');
      expect(StoreRankAvatar.normalizeDivision('MAESTRO'), 'magnate_mercado');
    });

    test('handles null or empty fallback gracefully', () {
      expect(StoreRankAvatar.normalizeDivision(null), 'puesto_ambulante');
      expect(StoreRankAvatar.normalizeDivision(''), 'puesto_ambulante');
      expect(StoreRankAvatar.normalizeDivision('   '), 'puesto_ambulante');
    });
  });

  group('StoreRankAvatar Widget Rendering', () {
    testWidgets('renders StoreRankAvatar with fallback frame without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoreRankAvatar(
              logoUrl: null,
              division: 'LOCAL_ESTABLECIDO',
              divisionFrameUrl: null,
              size: 80.0,
            ),
          ),
        ),
      );

      expect(find.byType(StoreRankAvatar), findsOneWidget);
    });
  });
}
