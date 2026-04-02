import '../../domain/entities/onboarding_item.dart';

abstract class OnboardingLocalDataSource {
  List<OnboardingItem> getOnboardingItems();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  @override
  List<OnboardingItem> getOnboardingItems() {
    return const [
      OnboardingItem(
        title: 'Gestiona tu negocio',
        description: 'Controla tu inventario, ventas y clientes desde un solo lugar',
        imagePath: 'assets/images/onboarding_1.png',
      ),
      OnboardingItem(
        title: 'Aumenta tus ventas',
        description: 'Herramientas inteligentes para hacer crecer tu negocio',
        imagePath: 'assets/images/onboarding_2.png',
      ),
      OnboardingItem(
        title: 'Reportes en tiempo real',
        description: 'Toma decisiones informadas con análisis detallados',
        imagePath: 'assets/images/onboarding_3.png',
      ),
    ];
  }
}
