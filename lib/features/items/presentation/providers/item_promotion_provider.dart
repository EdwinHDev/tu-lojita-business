import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/subscription/domain/entities/platform_payment_method.dart';

class PromotionConfig {
  final bool enabled;
  final String title;
  final int carouselSeconds;
  final int maxItems;
  final bool fillWithBestSellers;
  final double pricePerDay;

  const PromotionConfig({
    this.enabled = true,
    this.title = 'Artículos Destacados',
    this.carouselSeconds = 5,
    this.maxItems = 10,
    this.fillWithBestSellers = true,
    this.pricePerDay = 2.0,
  });

  factory PromotionConfig.fromJson(Map<String, dynamic> json) {
    return PromotionConfig(
      enabled: json['enabled'] != false,
      title: json['title'] ?? 'Artículos Destacados',
      carouselSeconds: json['carouselSeconds'] ?? 5,
      maxItems: json['maxItems'] ?? 10,
      fillWithBestSellers: json['fillWithBestSellers'] != false,
      pricePerDay: (json['pricePerDay'] != null)
          ? (json['pricePerDay'] as num).toDouble()
          : 2.0,
    );
  }
}

class ItemPromotionInfo {
  final bool hasActivePromotion;
  final Map<String, dynamic>? activePromotion;
  final Map<String, dynamic>? pendingPromotion;

  const ItemPromotionInfo({
    required this.hasActivePromotion,
    this.activePromotion,
    this.pendingPromotion,
  });

  factory ItemPromotionInfo.fromJson(Map<String, dynamic> json) {
    return ItemPromotionInfo(
      hasActivePromotion: json['hasActivePromotion'] == true,
      activePromotion: json['activePromotion'],
      pendingPromotion: json['pendingPromotion'],
    );
  }
}

class ItemPromotionState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final PromotionConfig config;
  final List<PlatformPaymentMethod> paymentMethods;
  final ItemPromotionInfo? currentItemPromotion;

  const ItemPromotionState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.config = const PromotionConfig(),
    this.paymentMethods = const [],
    this.currentItemPromotion,
  });

  ItemPromotionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    PromotionConfig? config,
    List<PlatformPaymentMethod>? paymentMethods,
    ItemPromotionInfo? currentItemPromotion,
  }) {
    return ItemPromotionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      config: config ?? this.config,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      currentItemPromotion: currentItemPromotion ?? this.currentItemPromotion,
    );
  }
}

final itemPromotionProvider =
    NotifierProvider<ItemPromotionNotifier, ItemPromotionState>(
  () => ItemPromotionNotifier(),
);

class ItemPromotionNotifier extends Notifier<ItemPromotionState> {
  @override
  ItemPromotionState build() {
    return const ItemPromotionState();
  }

  Dio get _dio => ref.read(dioProvider);

  Future<void> loadConfigAndMethods(String? itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Cargar configuración de vitrina
      PromotionConfig cfg = const PromotionConfig();
      try {
        final cfgRes = await _dio.get('/platform-settings/featured-showcase-config');
        if (cfgRes.data != null) {
          cfg = PromotionConfig.fromJson(cfgRes.data);
        }
      } catch (_) {}

      // 2. Cargar métodos de pago oficiales de la plataforma
      List<PlatformPaymentMethod> methods = [];
      try {
        final methodsRes = await _dio.get('/platform-payment-methods');
        if (methodsRes.data != null && methodsRes.data is List) {
          methods = (methodsRes.data as List)
              .map((m) => PlatformPaymentMethod.fromJson(m))
              .where((m) => m.isActive)
              .toList();
        }
      } catch (_) {}

      // 3. Si se pasa itemId, cargar estado de promoción
      ItemPromotionInfo? promoInfo;
      if (itemId != null && itemId.isNotEmpty) {
        try {
          final promoRes = await _dio.get('/items/$itemId/promotion-status');
          if (promoRes.data != null) {
            promoInfo = ItemPromotionInfo.fromJson(promoRes.data);
          }
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        config: cfg,
        paymentMethods: methods,
        currentItemPromotion: promoInfo,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar datos de promoción',
      );
    }
  }

  Future<bool> submitPromotionRequest({
    required String itemId,
    required int durationDays,
    required double amountPaid,
    required String paymentReference,
    required File receiptFile,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      // 1. Subir captura de comprobante
      final imageDataSource = ref.read(imageRemoteDataSourceProvider);
      final receiptUrl = await imageDataSource.uploadImage(receiptFile);

      // 2. Enviar solicitud de promoción
      await _dio.post(
        '/items/$itemId/promote',
        data: {
          'durationDays': durationDays,
          'amountPaid': amountPaid,
          'paymentReference': paymentReference,
          'paymentProofUrl': receiptUrl,
        },
      );

      // 3. Recargar estado de promoción
      await loadConfigAndMethods(itemId);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error al enviar la solicitud de promoción',
      );
      return false;
    }
  }
}
