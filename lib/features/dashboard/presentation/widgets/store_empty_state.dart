import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class StoreEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const StoreEmptyState({
    super.key,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: Color(0xFF4F46E5),
                size: 56,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No tienes tiendas aún',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu primera sucursal para empezar a vender tus productos en la plataforma de manera profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Crear mi primera tienda',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
