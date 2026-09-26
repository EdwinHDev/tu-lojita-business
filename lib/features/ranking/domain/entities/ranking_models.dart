class StoreRankingData {
  final String storeId;
  final String division;
  final String divisionTitle;
  final String? divisionEmblemUrl;
  final int currentLp;
  final int currentPR;
  final int lifetimeLp;
  final int ordersCompletedCount;
  final bool inCalibration;
  final bool flaggedForReview;
  final String? flagReason;
  final int position;
  final int consecutiveSalesDays;
  final double streakMultiplier;
  final bool isShieldActive;
  final DateTime? rankShieldExpiresAt;
  final bool inDangerZone;
  final DateTime? dangerZoneExpiresAt;
  final String? nextDivision;
  final String? nextDivisionTitle;
  final int pointsToNextTier;
  final int? nextTierThreshold;
  final List<AchievementItem> showcase;

  StoreRankingData({
    required this.storeId,
    required this.division,
    required this.divisionTitle,
    this.divisionEmblemUrl,
    required this.currentLp,
    required this.currentPR,
    required this.lifetimeLp,
    required this.ordersCompletedCount,
    required this.inCalibration,
    required this.flaggedForReview,
    this.flagReason,
    required this.position,
    this.consecutiveSalesDays = 0,
    this.streakMultiplier = 1.0,
    this.isShieldActive = false,
    this.rankShieldExpiresAt,
    this.inDangerZone = false,
    this.dangerZoneExpiresAt,
    this.nextDivision,
    this.nextDivisionTitle,
    this.pointsToNextTier = 0,
    this.nextTierThreshold,
    required this.showcase,
  });

  factory StoreRankingData.fromJson(Map<String, dynamic> json) {
    final pr = json['currentPR'] as int? ?? json['currentLP'] as int? ?? json['currentLp'] as int? ?? 0;
    return StoreRankingData(
      storeId: json['storeId']?.toString() ?? '',
      division: json['division']?.toString() ?? 'PUESTO_AMBULANTE',
      divisionTitle: json['divisionTitle']?.toString() ?? 'Puesto Ambulante',
      divisionEmblemUrl: json['divisionEmblemUrl'] as String?,
      currentLp: pr,
      currentPR: pr,
      lifetimeLp: json['lifetimeLp'] as int? ?? pr,
      ordersCompletedCount: json['ordersCompletedCount'] as int? ?? json['calibrationOrdersCompleted'] as int? ?? 0,
      inCalibration: json['inCalibration'] as bool? ?? json['isCalibrating'] as bool? ?? false,
      flaggedForReview: json['flaggedForReview'] as bool? ?? json['isFlagged'] as bool? ?? false,
      flagReason: json['flagReason'] as String?,
      position: json['position'] as int? ?? 0,
      consecutiveSalesDays: json['consecutiveSalesDays'] as int? ?? 0,
      streakMultiplier: (json['streakMultiplier'] as num?)?.toDouble() ?? 1.0,
      isShieldActive: json['isShieldActive'] as bool? ?? false,
      rankShieldExpiresAt: json['rankShieldExpiresAt'] != null
          ? DateTime.tryParse(json['rankShieldExpiresAt'].toString())
          : null,
      inDangerZone: json['inDangerZone'] as bool? ?? false,
      dangerZoneExpiresAt: json['dangerZoneExpiresAt'] != null
          ? DateTime.tryParse(json['dangerZoneExpiresAt'].toString())
          : null,
      nextDivision: json['nextDivision'] as String?,
      nextDivisionTitle: json['nextDivisionTitle'] as String?,
      pointsToNextTier: json['pointsToNextTier'] as int? ?? 0,
      nextTierThreshold: json['nextTierThreshold'] as int?,
      showcase: (json['showcase'] as List<dynamic>?)
              ?.map((item) => AchievementItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DailyMissionItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final int prReward;
  final int targetCount;
  final int currentCount;
  final bool isCompleted;
  final bool isClaimed;
  final String? badgeUrl;

  DailyMissionItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.prReward,
    required this.targetCount,
    required this.currentCount,
    required this.isCompleted,
    required this.isClaimed,
    this.badgeUrl,
  });

  factory DailyMissionItem.fromJson(Map<String, dynamic> json) {
    return DailyMissionItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      prReward: json['prReward'] as int? ?? 0,
      targetCount: json['targetCount'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      badgeUrl: json['badgeUrl'] as String?,
    );
  }
}

class RankingEventItem {
  final String id;
  final String eventType;
  final int lpDelta;
  final int lpAfter;
  final String? reason;
  final bool isVoided;
  final DateTime createdAt;

  RankingEventItem({
    required this.id,
    required this.eventType,
    required this.lpDelta,
    required this.lpAfter,
    this.reason,
    required this.isVoided,
    required this.createdAt,
  });

  factory RankingEventItem.fromJson(Map<String, dynamic> json) {
    return RankingEventItem(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'EVENT',
      lpDelta: json['lpDelta'] as int? ?? 0,
      lpAfter: json['lpAfter'] as int? ?? 0,
      reason: json['reason'] as String?,
      isVoided: json['isVoided'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AchievementItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final String? badgeUrl;
  final String triggerType;
  final int triggerThreshold;
  final int lpBonus;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool inShowcase;

  AchievementItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.badgeUrl,
    required this.triggerType,
    required this.triggerThreshold,
    required this.lpBonus,
    this.isUnlocked = false,
    this.unlockedAt,
    this.inShowcase = false,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    final ach = json['achievement'] is Map<String, dynamic>
        ? json['achievement'] as Map<String, dynamic>
        : json;
    return AchievementItem(
      id: (ach['id'] ?? json['achievementId'] ?? json['id'])?.toString() ?? '',
      code: (ach['code'] ?? json['code'])?.toString() ?? '',
      title: (ach['title'] ?? ach['name'] ?? json['title'] ?? json['name'])?.toString() ?? '',
      description: (ach['description'] ?? json['description'])?.toString() ?? '',
      badgeUrl: (ach['badgeUrl'] ?? ach['imageUrl'] ?? json['badgeUrl'] ?? json['imageUrl']) as String?,
      triggerType: (ach['triggerType'] ?? json['triggerType'])?.toString() ?? 'ORDERS_COUNT',
      triggerThreshold: (ach['triggerThreshold'] ?? json['triggerThreshold']) as int? ?? 0,
      lpBonus: (ach['lpBonus'] ?? json['lpBonus']) as int? ?? 0,
      isUnlocked: (json['isUnlocked'] as bool?) ?? (json['unlockedAt'] != null),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'].toString())
          : null,
      inShowcase: json['inShowcase'] as bool? ?? false,
    );
  }
}
