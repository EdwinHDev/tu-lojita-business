import '../entities/onboarding_item.dart';
import '../repositories/onboarding_repository.dart';

class GetOnboardingItems {
  final OnboardingRepository repository;

  GetOnboardingItems({required this.repository});

  List<OnboardingItem> call() {
    return repository.getOnboardingItems();
  }
}
