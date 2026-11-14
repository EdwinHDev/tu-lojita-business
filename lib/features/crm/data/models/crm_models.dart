import '../../domain/entities/crm_entities.dart';

double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class CrmModels {
  static CrmSummary summaryFromJson(Map<String, dynamic> json) {
    final storesRaw = (json['authorizedStores'] as List? ?? [])
        .map((e) => _storeRefFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final offerCfg = json['crmOfferConfig'] is Map
        ? Map<String, dynamic>.from(json['crmOfferConfig'] as Map)
        : const <String, dynamic>{};

    return CrmSummary(
      totalCustomers: _toInt(json['totalCustomers']),
      vipCount: _toInt(json['vipCount']),
      frequentCount: _toInt(json['frequentCount']),
      newCount: _toInt(json['newCount']),
      atRiskCount: _toInt(json['atRiskCount']),
      wishlistOnlyCount: _toInt(json['wishlistOnlyCount']),
      withDebtCount: _toInt(json['withDebtCount']),
      blockedCount: _toInt(json['blockedCount']),
      totalLtvUsd: _toDouble(json['totalLtvUsd']),
      totalPendingDebtUsd: _toDouble(json['totalPendingDebtUsd']),
      totalFavoritesCount: _toInt(json['totalFavoritesCount']),
      activeTargetedOffersCount: _toInt(json['activeTargetedOffersCount']),
      pendingFollowUpsCount: _toInt(json['pendingFollowUpsCount']),
      overdueFollowUpsCount: _toInt(json['overdueFollowUpsCount']),
      authorizedStores: storesRaw,
      crmOfferEnabled: offerCfg['enabled'] != false,
      crmOfferFeePerCampaign: _toDouble(offerCfg['feePerCampaign'], 1.0),
    );
  }

  static CrmStoreRef _storeRefFromJson(Map<String, dynamic> json) {
    return CrmStoreRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchName: json['branchName']?.toString(),
    );
  }

  static CrmAddress _addressFromJson(Map<String, dynamic> json) {
    return CrmAddress(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Dirección',
      fullAddress: json['fullAddress']?.toString() ?? '',
      reference: json['reference']?.toString(),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _toDouble(json['longitude']) : null,
      isActive: json['isActive'] == true,
    );
  }

  static CrmTargetedOfferSummary offerFromJson(Map<String, dynamic> json) {
    return CrmTargetedOfferSummary(
      id: json['id']?.toString() ?? '',
      offerCode: json['offerCode']?.toString() ?? '',
      itemId: json['itemId']?.toString(),
      itemTitle: json['itemTitle']?.toString(),
      itemMainImage: json['itemMainImage']?.toString(),
      storeId: json['storeId']?.toString(),
      storeName: json['storeName']?.toString(),
      originalPrice: _toDouble(json['originalPrice']),
      offerPrice: _toDouble(json['offerPrice']),
      discountPercent: _toDouble(json['discountPercent']),
      durationHours: _toInt(json['durationHours'], 24),
      expiresAt: _toDate(json['expiresAt']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'ACTIVE',
      serviceFeeUsd: _toDouble(json['serviceFeeUsd']),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      deepLinkUrl: json['deepLinkUrl']?.toString() ?? '',
      whatsappShareText: json['whatsappShareText']?.toString() ?? '',
      messageToCustomer: json['messageToCustomer']?.toString(),
      createdAt: _toDate(json['createdAt']),
    );
  }

  static CrmFavoriteItem _favoriteFromJson(Map<String, dynamic> json) {
    return CrmFavoriteItem(
      favoriteId: json['favoriteId']?.toString(),
      itemId: json['itemId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: _toDouble(json['price']),
      discountPrice: json['discountPrice'] != null
          ? _toDouble(json['discountPrice'])
          : null,
      priceWhenAdded: json['priceWhenAdded'] != null
          ? _toDouble(json['priceWhenAdded'])
          : null,
      mainImage: json['mainImage']?.toString() ?? '',
      stockQuantity: _toDouble(json['stockQuantity']),
      trackInventory: json['trackInventory'] != false,
      isActive: json['isActive'] != false,
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      favoritedAt: _toDate(json['favoritedAt']),
      activeOffer: json['activeOffer'] is Map
          ? offerFromJson(Map<String, dynamic>.from(json['activeOffer'] as Map))
          : null,
    );
  }

  static CrmCustomer customerFromJson(Map<String, dynamic> json) {
    final affiliated = (json['affiliatedStores'] as List? ?? [])
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return CrmAffiliatedStore(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            branchName: m['branchName']?.toString(),
            ordersCount: _toInt(m['ordersCount']),
            ltvUsd: _toDouble(m['ltvUsd']),
            favoritesCount: _toInt(m['favoritesCount']),
            isBlocked: m['isBlocked'] == true,
          );
        })
        .toList();

    final topFavs = (json['topFavoriteItems'] as List? ?? [])
        .map((e) => _favoriteFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return CrmCustomer(
      customerId: json['customerId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Cliente',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      identification: json['identification']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      averageBuyerRating: _toDouble(json['averageBuyerRating']),
      totalBuyerReviews: _toInt(json['totalBuyerReviews']),
      isAccountSuspended: json['isAccountSuspended'] == true,
      isChatBanned: json['isChatBanned'] == true,
      primaryAddress: json['primaryAddress'] is Map
          ? _addressFromJson(
              Map<String, dynamic>.from(json['primaryAddress'] as Map),
            )
          : null,
      primaryStore: json['primaryStore'] is Map
          ? _storeRefFromJson(
              Map<String, dynamic>.from(json['primaryStore'] as Map),
            )
          : null,
      affiliatedStores: affiliated,
      ltvUsd: _toDouble(json['ltvUsd']),
      ordersCount: _toInt(json['ordersCount']),
      completedOrdersCount: _toInt(json['completedOrdersCount']),
      averageTicketUsd: _toDouble(json['averageTicketUsd']),
      lastOrderAt: _toDate(json['lastOrderAt']),
      firstOrderAt: _toDate(json['firstOrderAt']),
      pendingDebtUsd: _toDouble(json['pendingDebtUsd']),
      overdueInstallmentsCount: _toInt(json['overdueInstallmentsCount']),
      nextDueDate: _toDate(json['nextDueDate']),
      favoritesCount: _toInt(json['favoritesCount']),
      topFavoriteItems: topFavs,
      activeOffersCount: _toInt(json['activeOffersCount']),
      disputesCount: _toInt(json['disputesCount']),
      isBlocked: json['isBlocked'] == true,
      segment: json['segment']?.toString() ?? 'NEW',
      segments: (json['segments'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      preferredChannel: json['preferredChannel']?.toString() ?? 'WHATSAPP',
      lastContactAt: _toDate(json['lastContactAt']),
      nextFollowUpAt: _toDate(json['nextFollowUpAt']),
      nextFollowUpNote: json['nextFollowUpNote']?.toString(),
      isFollowUpCompleted: json['isFollowUpCompleted'] == true,
      hasOverdueFollowUp: json['hasOverdueFollowUp'] == true,
    );
  }

  static CrmCustomerDetail customerDetailFromJson(Map<String, dynamic> json) {
    final offerCfg = json['crmOfferConfig'] is Map
        ? Map<String, dynamic>.from(json['crmOfferConfig'] as Map)
        : const <String, dynamic>{};
    final rep = json['reputation'] is Map
        ? Map<String, dynamic>.from(json['reputation'] as Map)
        : const <String, dynamic>{};

    return CrmCustomerDetail(
      customer: customerFromJson(
        Map<String, dynamic>.from(json['customer'] as Map),
      ),
      addresses: (json['addresses'] as List? ?? [])
          .map((e) => _addressFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      notes: (json['notes'] as List? ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return CrmCustomerNote(
          id: m['id']?.toString() ?? '',
          authorId: m['authorId']?.toString(),
          authorName: m['authorName']?.toString() ?? 'Equipo',
          content: m['content']?.toString() ?? '',
          category: m['category']?.toString() ?? 'GENERAL',
          createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
        );
      }).toList(),
      favoriteItems: (json['favoriteItems'] as List? ?? [])
          .map((e) => _favoriteFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      targetedOffers: (json['targetedOffers'] as List? ?? [])
          .map((e) => offerFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      orders: (json['orders'] as List? ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return CrmOrderSummary(
          id: m['id']?.toString() ?? '',
          storeId: m['storeId']?.toString() ?? '',
          storeName: m['storeName']?.toString() ?? '',
          status: m['status']?.toString() ?? '',
          totalAmount: _toDouble(m['totalAmount']),
          finalAmount: _toDouble(m['finalAmount']),
          totalPaidAmount: _toDouble(m['totalPaidAmount']),
          remainingBalance: _toDouble(m['remainingBalance']),
          isPartialPayment: m['isPartialPayment'] == true,
          isFullyPaid: m['isFullyPaid'] == true,
          nextDueDate: _toDate(m['nextDueDate']),
          exchangeRate:
              m['exchangeRate'] != null ? _toDouble(m['exchangeRate']) : null,
          preOrderStatus: m['preOrderStatus']?.toString(),
          createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
          items: (m['items'] as List? ?? [])
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
          installments: (m['installments'] as List? ?? [])
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
          payments: (m['payments'] as List? ?? [])
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
        );
      }).toList(),
      slotBookings: (json['slotBookings'] as List? ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return CrmSlotBookingSummary(
          id: m['id']?.toString() ?? '',
          orderId: m['orderId']?.toString() ?? '',
          storeId: m['storeId']?.toString() ?? '',
          storeName: m['storeName']?.toString() ?? '',
          bookingDate: m['bookingDate']?.toString() ?? '',
          slotStartTime: m['slotStartTime']?.toString() ?? '',
          slotEndTime: m['slotEndTime']?.toString() ?? '',
          slotLabel: m['slotLabel']?.toString(),
          status: m['status']?.toString() ?? '',
        );
      }).toList(),
      buyerReviews: (rep['buyerReviews'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      orderReviewsWritten: (rep['orderReviewsWritten'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      disputes: (rep['disputes'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      blocks: (rep['blocks'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      crmOfferEnabled: offerCfg['enabled'] != false,
      crmOfferFeePerCampaign: _toDouble(offerCfg['feePerCampaign'], 1.0),
    );
  }

  static CrmOffersConfig offersConfigFromJson(Map<String, dynamic> json) {
    final methods = (json['platformPaymentMethods'] as List? ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return CrmPlatformPaymentMethod(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? m['name']?.toString() ?? 'Método',
        type: m['type']?.toString() ?? '',
        accountDetails: m['accountDetails'] is Map
            ? Map<String, dynamic>.from(m['accountDetails'] as Map)
            : const <String, dynamic>{},
        instructions: m['instructions']?.toString(),
      );
    }).toList();

    return CrmOffersConfig(
      enabled: json['enabled'] != false,
      feePerCampaign: _toDouble(json['feePerCampaign'], 1.0),
      platformPaymentMethods: methods,
    );
  }
}
