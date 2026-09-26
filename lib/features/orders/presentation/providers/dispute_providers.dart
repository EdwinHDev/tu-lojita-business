import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import '../../domain/entities/order_dispute.dart';
import '../../domain/repositories/dispute_repository.dart';
import '../../data/datasources/dispute_remote_data_source.dart';
import '../../data/repositories/dispute_repository_impl.dart';

final disputeRemoteDataSourceProvider = Provider<DisputeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DisputeRemoteDataSource(dio);
});

final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  final remoteDataSource = ref.watch(disputeRemoteDataSourceProvider);
  final imageDataSource = ref.watch(imageRemoteDataSourceProvider);
  return DisputeRepositoryImpl(
    disputeRemoteDataSource: remoteDataSource,
    imageRemoteDataSource: imageDataSource,
  );
});

final storeDisputesByOrderProvider =
    FutureProvider.family.autoDispose<List<OrderDispute>, String>((ref, orderId) async {
  final repository = ref.watch(disputeRepositoryProvider);
  return await repository.getDisputesByOrder(orderId);
});

final activeStoreDisputeProvider =
    Provider.family.autoDispose<OrderDispute?, String>((ref, orderId) {
  final disputesAsync = ref.watch(storeDisputesByOrderProvider(orderId));
  return disputesAsync.when(
    data: (disputes) {
      if (disputes.isEmpty) return null;
      for (final dispute in disputes) {
        if (dispute.status.isActive) return dispute;
      }
      return disputes.first;
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});

class StoreDisputeActionState {
  final bool isLoading;
  final String? error;
  final OrderDispute? updatedDispute;

  const StoreDisputeActionState({
    this.isLoading = false,
    this.error,
    this.updatedDispute,
  });

  StoreDisputeActionState copyWith({
    bool? isLoading,
    String? error,
    OrderDispute? updatedDispute,
  }) {
    return StoreDisputeActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatedDispute: updatedDispute ?? this.updatedDispute,
    );
  }
}

class StoreDisputeActionNotifier extends Notifier<StoreDisputeActionState> {
  @override
  StoreDisputeActionState build() {
    return const StoreDisputeActionState();
  }

  Future<bool> respondDispute({
    required String disputeId,
    required String orderId,
    required String response,
    List<File> evidenceFiles = const [],
    bool acceptDispute = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(disputeRepositoryProvider);
      final dispute = await repository.respondDispute(
        disputeId: disputeId,
        response: response,
        evidenceFiles: evidenceFiles,
        acceptDispute: acceptDispute,
      );

      ref.invalidate(storeDisputesByOrderProvider(orderId));

      state = state.copyWith(
        isLoading: false,
        updatedDispute: dispute,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatDisputeError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> markResolved({
    required String disputeId,
    required String orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(disputeRepositoryProvider);
      await repository.markResolved(disputeId);
      ref.invalidate(storeDisputesByOrderProvider(orderId));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatDisputeError(e),
      );
      return false;
    }
  }

  Future<bool> escalate({
    required String disputeId,
    required String orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(disputeRepositoryProvider);
      await repository.escalate(disputeId);
      ref.invalidate(storeDisputesByOrderProvider(orderId));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatDisputeError(e),
      );
      return false;
    }
  }

  String _formatDisputeError(dynamic error) {
    final raw = error.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '').trim();
    if (raw.contains('No se puede responder') || raw.contains('no se encuentra activa')) {
      return 'Este reclamo ya no se encuentra en estado pendiente de respuesta.';
    }
    if (raw.contains('10 caracteres') || raw.contains('descripción') || raw.contains('respuesta')) {
      return 'Por favor ingresa una respuesta de al menos 10 caracteres.';
    }
    if (raw.contains('SocketException') || raw.contains('connection') || raw.contains('Timeout')) {
      return 'Problema de conexión. Verifica tu internet e intenta nuevamente.';
    }
    if (raw.contains('property') || raw.contains('should not exist')) {
      return 'Hubo un error al procesar los datos de respuesta. Por favor intenta de nuevo.';
    }
    return raw.isNotEmpty ? raw : 'No se pudo enviar la respuesta. Por favor intenta de nuevo.';
  }
}

final storeDisputeActionNotifierProvider =
    NotifierProvider<StoreDisputeActionNotifier, StoreDisputeActionState>(
  () => StoreDisputeActionNotifier(),
);
