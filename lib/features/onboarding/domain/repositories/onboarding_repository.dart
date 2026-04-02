import '../entities/onboarding_item.dart';

abstract class OnboardingRepository {
  List<OnboardingItem> getOnboardingItems();
}
