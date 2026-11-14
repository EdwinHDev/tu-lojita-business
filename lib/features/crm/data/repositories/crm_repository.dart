import 'package:dio/dio.dart';
import '../../domain/entities/crm_entities.dart';
import '../models/crm_models.dart';

class CrmRepository {
  final Dio _dio;

  CrmRepository(this._dio);

  Future<CrmSummary> getSummary(String companyId, {String? storeId}) async {
    final response = await _dio.get(
      '/companies/$companyId/crm/summary',
      queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
      },
    );
    return CrmModels.summaryFromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<CrmCustomer>> getCustomers(
    String companyId, {
    String? storeId,
    String? search,
    String? segment,
    String sortBy = 'ltv',
    String sortOrder = 'DESC',
  }) async {
    final response = await _dio.get(
      '/companies/$companyId/crm/customers',
      queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (segment != null && segment.isNotEmpty) 'segment': segment,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'limit': 100,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final list = data['customers'] as List? ?? [];
    return list
        .map((e) => CrmModels.customerFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CrmCustomerDetail> getCustomerDetail(
    String companyId,
    String customerId, {
    String? storeId,
  }) async {
    final response = await _dio.get(
      '/companies/$companyId/crm/customers/$customerId',
      queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
      },
    );
    return CrmModels.customerDetailFromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> updateCustomerProfile(
    String companyId,
    String customerId, {
    List<String>? tags,
    String? preferredChannel,
    DateTime? nextFollowUpAt,
    bool clearFollowUp = false,
    String? nextFollowUpNote,
    bool? isFollowUpCompleted,
    bool? markContactedNow,
  }) async {
    await _dio.patch(
      '/companies/$companyId/crm/customers/$customerId/profile',
      data: {
        'tags': ?tags,
        'preferredChannel': ?preferredChannel,
        if (clearFollowUp)
          'nextFollowUpAt': null
        else if (nextFollowUpAt != null)
          'nextFollowUpAt': nextFollowUpAt.toUtc().toIso8601String(),
        'nextFollowUpNote': ?nextFollowUpNote,
        'isFollowUpCompleted': ?isFollowUpCompleted,
        if (markContactedNow == true) 'markContactedNow': true,
      },
    );
  }

  Future<void> addCustomerNote(
    String companyId,
    String customerId, {
    required String content,
    String category = 'GENERAL',
  }) async {
    await _dio.post(
      '/companies/$companyId/crm/customers/$customerId/notes',
      data: {
        'content': content.trim(),
        'category': category,
      },
    );
  }

  Future<CrmOffersConfig> getOffersConfig(String companyId) async {
    final response = await _dio.get('/companies/$companyId/crm/offers/config');
    return CrmModels.offersConfigFromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CrmTargetedOfferSummary> createTargetedOffer(
    String companyId,
    String customerId, {
    required String itemId,
    required double offerPrice,
    required int durationHours,
    String? paymentMethod,
    String? paymentReference,
    String? messageToCustomer,
  }) async {
    final response = await _dio.post(
      '/companies/$companyId/crm/customers/$customerId/offers',
      data: {
        'itemId': itemId,
        'offerPrice': offerPrice,
        'durationHours': durationHours,
        if (paymentMethod != null && paymentMethod.trim().isNotEmpty)
          'paymentMethod': paymentMethod.trim(),
        if (paymentReference != null && paymentReference.trim().isNotEmpty)
          'paymentReference': paymentReference.trim(),
        if (messageToCustomer != null && messageToCustomer.trim().isNotEmpty)
          'messageToCustomer': messageToCustomer.trim(),
      },
    );
    return CrmModels.offerFromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> cancelOffer(String companyId, String offerId) async {
    await _dio.patch('/companies/$companyId/crm/offers/$offerId/cancel');
  }
}
