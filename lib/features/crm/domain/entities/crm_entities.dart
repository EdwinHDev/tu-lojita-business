class CrmStoreRef {
  final String id;
  final String name;
  final String? branchName;

  const CrmStoreRef({
    required this.id,
    required this.name,
    this.branchName,
  });

  String get displayName =>
      (branchName != null && branchName!.trim().isNotEmpty)
          ? '$name ($branchName)'
          : name;
}

class CrmAffiliatedStore {
  final String id;
  final String name;
  final String? branchName;
  final int ordersCount;
  final double ltvUsd;
  final int favoritesCount;
  final bool isBlocked;

  const CrmAffiliatedStore({
    required this.id,
    required this.name,
    this.branchName,
    required this.ordersCount,
    required this.ltvUsd,
    required this.favoritesCount,
    required this.isBlocked,
  });

  String get displayName =>
      (branchName != null && branchName!.trim().isNotEmpty)
          ? '$name ($branchName)'
          : name;
}

class CrmAddress {
  final String id;
  final String title;
  final String fullAddress;
  final String? reference;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const CrmAddress({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.reference,
    this.latitude,
    this.longitude,
    this.isActive = false,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

class CrmTargetedOfferSummary {
  final String id;
  final String offerCode;
  final String? itemId;
  final String? itemTitle;
  final String? itemMainImage;
  final String? storeId;
  final String? storeName;
  final double originalPrice;
  final double offerPrice;
  final double discountPercent;
  final int durationHours;
  final DateTime expiresAt;
  final String status;
  final double serviceFeeUsd;
  final String? paymentMethod;
  final String? paymentReference;
  final String deepLinkUrl;
  final String whatsappShareText;
  final String? messageToCustomer;
  final DateTime? createdAt;

  const CrmTargetedOfferSummary({
    required this.id,
    required this.offerCode,
    this.itemId,
    this.itemTitle,
    this.itemMainImage,
    this.storeId,
    this.storeName,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercent,
    required this.durationHours,
    required this.expiresAt,
    required this.status,
    required this.serviceFeeUsd,
    this.paymentMethod,
    this.paymentReference,
    required this.deepLinkUrl,
    required this.whatsappShareText,
    this.messageToCustomer,
    this.createdAt,
  });

  bool get isActive => status == 'ACTIVE' && expiresAt.isAfter(DateTime.now());
}

class CrmFavoriteItem {
  final String? favoriteId;
  final String itemId;
  final String title;
  final double price;
  final double? discountPrice;
  final double? priceWhenAdded;
  final String mainImage;
  final double stockQuantity;
  final bool trackInventory;
  final bool isActive;
  final String storeId;
  final String storeName;
  final DateTime? favoritedAt;
  final CrmTargetedOfferSummary? activeOffer;

  const CrmFavoriteItem({
    this.favoriteId,
    required this.itemId,
    required this.title,
    required this.price,
    this.discountPrice,
    this.priceWhenAdded,
    required this.mainImage,
    this.stockQuantity = 0,
    this.trackInventory = true,
    this.isActive = true,
    required this.storeId,
    required this.storeName,
    this.favoritedAt,
    this.activeOffer,
  });
}

class CrmCustomerNote {
  final String id;
  final String? authorId;
  final String authorName;
  final String content;
  final String category;
  final DateTime createdAt;

  const CrmCustomerNote({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.content,
    required this.category,
    required this.createdAt,
  });
}

class CrmCustomer {
  final String customerId;
  final String fullName;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String identification;
  final String? avatarUrl;
  final double averageBuyerRating;
  final int totalBuyerReviews;
  final bool isAccountSuspended;
  final bool isChatBanned;
  final CrmAddress? primaryAddress;
  final CrmStoreRef? primaryStore;
  final List<CrmAffiliatedStore> affiliatedStores;
  final double ltvUsd;
  final int ordersCount;
  final int completedOrdersCount;
  final double averageTicketUsd;
  final DateTime? lastOrderAt;
  final DateTime? firstOrderAt;
  final double pendingDebtUsd;
  final int overdueInstallmentsCount;
  final DateTime? nextDueDate;
  final int favoritesCount;
  final List<CrmFavoriteItem> topFavoriteItems;
  final int activeOffersCount;
  final int disputesCount;
  final bool isBlocked;
  final String segment;
  final List<String> segments;
  final List<String> tags;
  final String preferredChannel;
  final DateTime? lastContactAt;
  final DateTime? nextFollowUpAt;
  final String? nextFollowUpNote;
  final bool isFollowUpCompleted;
  final bool hasOverdueFollowUp;

  const CrmCustomer({
    required this.customerId,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.identification,
    this.avatarUrl,
    required this.averageBuyerRating,
    required this.totalBuyerReviews,
    required this.isAccountSuspended,
    required this.isChatBanned,
    this.primaryAddress,
    this.primaryStore,
    required this.affiliatedStores,
    required this.ltvUsd,
    required this.ordersCount,
    required this.completedOrdersCount,
    required this.averageTicketUsd,
    this.lastOrderAt,
    this.firstOrderAt,
    required this.pendingDebtUsd,
    required this.overdueInstallmentsCount,
    this.nextDueDate,
    required this.favoritesCount,
    required this.topFavoriteItems,
    required this.activeOffersCount,
    required this.disputesCount,
    required this.isBlocked,
    required this.segment,
    required this.segments,
    required this.tags,
    required this.preferredChannel,
    this.lastContactAt,
    this.nextFollowUpAt,
    this.nextFollowUpNote,
    required this.isFollowUpCompleted,
    required this.hasOverdueFollowUp,
  });
}

class CrmSummary {
  final int totalCustomers;
  final int vipCount;
  final int frequentCount;
  final int newCount;
  final int atRiskCount;
  final int wishlistOnlyCount;
  final int withDebtCount;
  final int blockedCount;
  final double totalLtvUsd;
  final double totalPendingDebtUsd;
  final int totalFavoritesCount;
  final int activeTargetedOffersCount;
  final int pendingFollowUpsCount;
  final int overdueFollowUpsCount;
  final List<CrmStoreRef> authorizedStores;
  final bool crmOfferEnabled;
  final double crmOfferFeePerCampaign;

  const CrmSummary({
    required this.totalCustomers,
    required this.vipCount,
    required this.frequentCount,
    required this.newCount,
    required this.atRiskCount,
    required this.wishlistOnlyCount,
    required this.withDebtCount,
    required this.blockedCount,
    required this.totalLtvUsd,
    required this.totalPendingDebtUsd,
    required this.totalFavoritesCount,
    required this.activeTargetedOffersCount,
    required this.pendingFollowUpsCount,
    required this.overdueFollowUpsCount,
    required this.authorizedStores,
    required this.crmOfferEnabled,
    required this.crmOfferFeePerCampaign,
  });
}

class CrmOrderSummary {
  final String id;
  final String storeId;
  final String storeName;
  final String status;
  final double totalAmount;
  final double finalAmount;
  final double totalPaidAmount;
  final double remainingBalance;
  final bool isPartialPayment;
  final bool isFullyPaid;
  final DateTime? nextDueDate;
  final double? exchangeRate;
  final String? preOrderStatus;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> installments;
  final List<Map<String, dynamic>> payments;

  const CrmOrderSummary({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.totalAmount,
    required this.finalAmount,
    required this.totalPaidAmount,
    required this.remainingBalance,
    required this.isPartialPayment,
    required this.isFullyPaid,
    this.nextDueDate,
    this.exchangeRate,
    this.preOrderStatus,
    required this.createdAt,
    required this.items,
    required this.installments,
    required this.payments,
  });
}

class CrmSlotBookingSummary {
  final String id;
  final String orderId;
  final String storeId;
  final String storeName;
  final String bookingDate;
  final String slotStartTime;
  final String slotEndTime;
  final String? slotLabel;
  final String status;

  const CrmSlotBookingSummary({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.bookingDate,
    required this.slotStartTime,
    required this.slotEndTime,
    this.slotLabel,
    required this.status,
  });
}

class CrmPlatformPaymentMethod {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> accountDetails;
  final String? instructions;

  const CrmPlatformPaymentMethod({
    required this.id,
    required this.title,
    required this.type,
    required this.accountDetails,
    this.instructions,
  });
}

class CrmOffersConfig {
  final bool enabled;
  final double feePerCampaign;
  final List<CrmPlatformPaymentMethod> platformPaymentMethods;

  const CrmOffersConfig({
    required this.enabled,
    required this.feePerCampaign,
    required this.platformPaymentMethods,
  });
}

class CrmCustomerDetail {
  final CrmCustomer customer;
  final List<CrmAddress> addresses;
  final List<CrmCustomerNote> notes;
  final List<CrmFavoriteItem> favoriteItems;
  final List<CrmTargetedOfferSummary> targetedOffers;
  final List<CrmOrderSummary> orders;
  final List<CrmSlotBookingSummary> slotBookings;
  final List<Map<String, dynamic>> buyerReviews;
  final List<Map<String, dynamic>> orderReviewsWritten;
  final List<Map<String, dynamic>> disputes;
  final List<Map<String, dynamic>> blocks;
  final bool crmOfferEnabled;
  final double crmOfferFeePerCampaign;

  const CrmCustomerDetail({
    required this.customer,
    required this.addresses,
    required this.notes,
    required this.favoriteItems,
    required this.targetedOffers,
    required this.orders,
    required this.slotBookings,
    required this.buyerReviews,
    required this.orderReviewsWritten,
    required this.disputes,
    required this.blocks,
    required this.crmOfferEnabled,
    required this.crmOfferFeePerCampaign,
  });
}
