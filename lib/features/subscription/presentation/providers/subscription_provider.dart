import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/platform_payment_method.dart';

class SubscriptionState {
  final bool isLoading;
  final String? errorMessage;
  final CompanySubscription? subscription;
  final List<PlatformPaymentMethod> paymentMethods;
  final bool isReportingPayment;

  const SubscriptionState({
    this.isLoading = false,
    this.errorMessage,
    this.subscription,
    this.paymentMethods = const [],
    this.isReportingPayment = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? errorMessage,
    CompanySubscription? subscription,
    List<PlatformPaymentMethod>? paymentMethods,
    bool? isReportingPayment,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      subscription: subscription ?? this.subscription,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isReportingPayment: isReportingPayment ?? this.isReportingPayment,
    );
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  () => SubscriptionNotifier(),
);

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    return const SubscriptionState();
  }

  Dio get _dio => ref.read(dioProvider);

  Future<void> loadSubscriptionAndMethods() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final subRes = await _dio.get('/subscriptions/my-subscription');
      final methodsRes = await _dio.get('/platform-payment-methods');

      final subData = subRes.data['subscription'] as Map<String, dynamic>;
      final subscription = CompanySubscription.fromJson(subData);

      final methodsList = (methodsRes.data as List)
          .map((m) => PlatformPaymentMethod.fromJson(m))
          .toList();

      state = state.copyWith(
        isLoading: false,
        subscription: subscription,
        paymentMethods: methodsList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al consultar información de suscripción',
      );
    }
  }

  Future<bool> reportSubscriptionPayment({
    required double amount,
    required String paymentMethodId,
    required String referenceNumber,
    required File receiptFile,
  }) async {
    state = state.copyWith(isReportingPayment: true, errorMessage: null);
    try {
      // 1. Subir imagen del comprobante
      final imageDataSource = ref.read(imageRemoteDataSourceProvider);
      final receiptUrl = await imageDataSource.uploadImage(receiptFile);

      // 2. Registrar reporte de pago
      await _dio.post(
        '/subscriptions/report-payment',
        data: {
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'referenceNumber': referenceNumber,
          'receiptImageUrl': receiptUrl,
        },
      );

      // 3. Recargar suscripción
      await loadSubscriptionAndMethods();
      state = state.copyWith(isReportingPayment: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isReportingPayment: false,
        errorMessage: 'Error al enviar comprobante de pago',
      );
      return false;
    }
  }
}
