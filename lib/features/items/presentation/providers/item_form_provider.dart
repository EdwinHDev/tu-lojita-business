import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/item.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';

class ItemFormState {
  final List<File> selectedImages;
  final List<String> existingImages;
  final List<String> deletedImages;
  final int primaryImageIndex;
  final Map<String, dynamic> attributes;
  final List<PropertyTemplate> availableTemplates;
  final bool isLoading;
  final bool isLoadingTemplates;
  final String? errorMessage;
  final bool isSuccess;

  // New fields
  final String? itemId;
  final String title;
  final String description;
  final double price;
  final PriceType priceType;
  final bool isFeatured;
  final double? discountPrice;
  final ItemType itemType;
  final bool trackInventory;
  final double? stockQuantity;
  final bool requiresBooking;
  final String? categoryId;
  final List<CustomizationGroup> customizationGroups;
  final bool allowInstallments;
  final double lateFeePercentage;
  final bool isActive;
  final bool isAgeRestricted;
  final List<Map<String, dynamic>> commissionRanges;
  final bool hasVariants;
  final List<VariantAxis> variantAxes;
  final List<ItemVariant> variants;
  final Map<String, dynamic> slotConfig;
  final Map<String, dynamic> preorderConfig;

  const ItemFormState({
    this.selectedImages = const [],
    this.existingImages = const [],
    this.deletedImages = const [],
    this.primaryImageIndex = 0,
    this.attributes = const {},
    this.availableTemplates = const [],
    this.isLoading = false,
    this.isLoadingTemplates = false,
    this.errorMessage,
    this.isSuccess = false,
    this.itemId,
    this.title = '',
    this.description = '',
    this.price = 0,
    this.priceType = PriceType.fixed,
    this.isFeatured = false,
    this.discountPrice,
    this.itemType = ItemType.product,
    this.trackInventory = true,
    this.stockQuantity,
    this.requiresBooking = false,
    this.slotConfig = const {
      'minNoticeHours': 2,
      'serviceDurationMinutes': 60,
      'allowSameDay': true,
      'maxConcurrentBookings': 1,
      'serviceLocationType': 'ON_SITE',
      'slots': <Map<String, dynamic>>[],
    },
    this.preorderConfig = const {
      'depositType': 'PERCENTAGE',
      'depositValue': 50.0,
      'estimatedLeadDaysMin': 7,
      'estimatedLeadDaysMax': 15,
      'maxPreOrderUnits': 50,
      'settlementWindowHours': 48,
    },
    this.categoryId,
    this.customizationGroups = const [],
    this.allowInstallments = false,
    this.lateFeePercentage = 0,
    this.isActive = true,
    this.isAgeRestricted = false,
    this.commissionRanges = const [],
    this.hasVariants = false,
    this.variantAxes = const [],
    this.variants = const [],
  });

  double get effectivePrice =>
      (discountPrice != null && discountPrice! > 0) ? discountPrice! : price;

  Map<String, dynamic>? get matchedRange {
    final p = effectivePrice;
    if (p <= 0 || commissionRanges.isEmpty) return null;
    for (final r in commissionRanges) {
      final min =
          double.tryParse(r['minAmount']?.toString() ?? '0') ?? 0.0;
      final max = r['maxAmount'] != null
          ? double.tryParse(r['maxAmount'].toString())
          : double.infinity;
      if (p >= min && p <= (max ?? double.infinity)) {
        return r;
      }
    }
    return null;
  }

  double get singleCommissionRate =>
      double.tryParse(matchedRange?['singlePaymentRate']?.toString() ?? '0') ??
      0.0;

  double get installmentCommissionRate =>
      double.tryParse(
          matchedRange?['installmentPaymentRate']?.toString() ?? '0') ??
      0.0;

  double get singleCommissionAmount =>
      (effectivePrice * singleCommissionRate) / 100;

  double get installmentCommissionAmount =>
      (effectivePrice * installmentCommissionRate) / 100;

  double get customerSingleFinalPrice =>
      effectivePrice + singleCommissionAmount;

  double get customerInstallmentFinalPrice =>
      effectivePrice + installmentCommissionAmount;

  ItemFormState copyWith({
    List<File>? selectedImages,
    List<String>? existingImages,
    List<String>? deletedImages,
    int? primaryImageIndex,
    Map<String, dynamic>? attributes,
    List<PropertyTemplate>? availableTemplates,
    bool? isLoading,
    bool? isLoadingTemplates,
    String? errorMessage,
    bool? isSuccess,
    String? itemId,
    String? title,
    String? description,
    double? price,
    PriceType? priceType,
    bool? isFeatured,
    double? discountPrice,
    ItemType? itemType,
    bool? trackInventory,
    double? stockQuantity,
    bool? requiresBooking,
    String? categoryId,
    List<CustomizationGroup>? customizationGroups,
    bool? allowInstallments,
    double? lateFeePercentage,
    bool? isActive,
    bool? isAgeRestricted,
    List<Map<String, dynamic>>? commissionRanges,
    bool? hasVariants,
    List<VariantAxis>? variantAxes,
    List<ItemVariant>? variants,
    Map<String, dynamic>? slotConfig,
    Map<String, dynamic>? preorderConfig,
  }) {
    return ItemFormState(
      selectedImages: selectedImages ?? this.selectedImages,
      existingImages: existingImages ?? this.existingImages,
      deletedImages: deletedImages ?? this.deletedImages,
      primaryImageIndex: primaryImageIndex ?? this.primaryImageIndex,
      attributes: attributes ?? this.attributes,
      availableTemplates: availableTemplates ?? this.availableTemplates,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTemplates: isLoadingTemplates ?? this.isLoadingTemplates,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPrice: discountPrice ?? this.discountPrice,
      itemType: itemType ?? this.itemType,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      slotConfig: slotConfig ?? this.slotConfig,
      preorderConfig: preorderConfig ?? this.preorderConfig,
      categoryId: categoryId ?? this.categoryId,
      customizationGroups: customizationGroups ?? this.customizationGroups,
      allowInstallments: allowInstallments ?? this.allowInstallments,
      lateFeePercentage: lateFeePercentage ?? this.lateFeePercentage,
      isActive: isActive ?? this.isActive,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      commissionRanges: commissionRanges ?? this.commissionRanges,
      hasVariants: hasVariants ?? this.hasVariants,
      variantAxes: variantAxes ?? this.variantAxes,
      variants: variants ?? this.variants,
    );
  }
}

class ItemFormNotifier extends Notifier<ItemFormState> {
  @override
  ItemFormState build() {
    Future.microtask(() => loadCommissionSettings());
    return const ItemFormState();
  }

  Future<void> loadCommissionSettings() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/commissions/active-ranges');
      final isEnabled = res.data['isEnabled'] == true;
      final ranges = isEnabled
          ? ((res.data['ranges'] as List?)
                  ?.map((r) => Map<String, dynamic>.from(r as Map))
                  .toList() ??
              [])
          : <Map<String, dynamic>>[];
      state = state.copyWith(commissionRanges: ranges);
    } catch (_) {}
  }

  void initForEditing(Item item) {
    initFromItem(item);
    loadFullItem(item.id);
  }

  Future<void> loadFullItem(String itemId) async {
    try {
      final repository = ref.read(itemRepositoryProvider);
      final fullItem = await repository.getItemById(itemId);
      initFromItem(fullItem);
    } catch (_) {}
  }

  void initFromItem(Item item) {
    Map<String, dynamic> mappedAttributes = {};
    if (item.attributes != null) {
      if (item.attributes!['properties'] is List) {
        for (var prop in (item.attributes!['properties'] as List)) {
          if (prop is Map && prop['key'] != null) {
            mappedAttributes[prop['key']] = prop['value'];
          }
        }
      } else {
        mappedAttributes = Map<String, dynamic>.from(item.attributes!);
      }
    }

    Map<String, dynamic> mappedSlotConfig = Map<String, dynamic>.from(state.slotConfig);
    if (item.slotConfig != null) {
      mappedSlotConfig = Map<String, dynamic>.from(item.slotConfig!);
      if (mappedSlotConfig['slots'] is List) {
        mappedSlotConfig['slots'] = (mappedSlotConfig['slots'] as List)
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList();
      } else {
        mappedSlotConfig['slots'] = <Map<String, dynamic>>[];
      }
    }

    state = state.copyWith(
      itemId: item.id,
      title: item.title,
      description: item.description,
      price: item.price,
      priceType: item.priceType,
      isFeatured: item.isFeatured,
      discountPrice: item.discountPrice,
      itemType: item.itemType,
      trackInventory: item.trackInventory,
      stockQuantity: item.stockQuantity,
      requiresBooking: item.requiresBooking,
      slotConfig: mappedSlotConfig,
      preorderConfig: item.preorderConfig ?? state.preorderConfig,
      categoryId: item.categoryId,
      existingImages: item.images,
      attributes: mappedAttributes,
      customizationGroups: item.customizationGroups,
      allowInstallments: item.allowInstallments,
      lateFeePercentage: item.lateFeePercentage,
      isActive: item.isActive,
      isAgeRestricted: item.isAgeRestricted,
      hasVariants: item.hasVariants,
      variantAxes: item.variantAxes,
      variants: item.variants,
    );
    if (item.categoryId != null) {
      loadCategoryTemplates(item.categoryId!);
    }
  }

  void onTitleChanged(String value) => state = state.copyWith(title: value);
  void onDescriptionChanged(String value) => state = state.copyWith(description: value);
  void onPriceChanged(double value) => state = state.copyWith(price: value);
  void onPriceTypeChanged(PriceType value) => state = state.copyWith(priceType: value);
  void onIsFeaturedChanged(bool value) => state = state.copyWith(isFeatured: value);
  void onIsActiveChanged(bool value) => state = state.copyWith(isActive: value);
  void onIsAgeRestrictedChanged(bool value) => state = state.copyWith(isAgeRestricted: value);
  void onDiscountPriceChanged(double? value) => state = state.copyWith(discountPrice: value);
  void onItemTypeChanged(ItemType value) => state = state.copyWith(
        itemType: value,
        trackInventory: value == ItemType.service ? false : state.trackInventory,
        requiresBooking: value == ItemType.service ? true : state.requiresBooking,
      );
  void onTrackInventoryChanged(bool value) => state = state.copyWith(trackInventory: value);
  void onStockQuantityChanged(double? value) => state = state.copyWith(stockQuantity: value);
  void onRequiresBookingChanged(bool value) => state = state.copyWith(requiresBooking: value);
  void onSlotConfigChanged(Map<String, dynamic> value) => state = state.copyWith(slotConfig: value);
  void onPreorderConfigChanged(Map<String, dynamic> value) => state = state.copyWith(preorderConfig: value);
  void onAllowInstallmentsChanged(bool value) => state = state.copyWith(allowInstallments: value);
  void onLateFeePercentageChanged(double value) => state = state.copyWith(lateFeePercentage: value);
  
  void onCategoryIdChanged(String? value) {
    state = state.copyWith(categoryId: value, attributes: {});
    if (value != null) {
      loadCategoryTemplates(value);
    } else {
      state = state.copyWith(availableTemplates: []);
    }
  }

  Future<void> loadCategoryTemplates(String categoryId) async {
    state = state.copyWith(isLoadingTemplates: true);
    try {
      final repository = ref.read(itemRepositoryProvider);
      final templates = await repository.getCategoryTemplates(categoryId);
      if (!ref.mounted) return;
      state = state.copyWith(availableTemplates: templates, isLoadingTemplates: false);
    } catch (e) {
      state = state.copyWith(isLoadingTemplates: false);
    }
  }

  void onAttributeChanged(String key, dynamic value) {
    final newAttributes = {...state.attributes};
    newAttributes[key] = value;
    state = state.copyWith(attributes: newAttributes);
  }

  void addImages(List<File> images) {
    state = state.copyWith(selectedImages: [...state.selectedImages, ...images]);
  }

  void removeImage(int index, {bool isExisting = false}) {
    if (isExisting) {
      final imageUrl = state.existingImages[index];
      final newList = [...state.existingImages];
      newList.removeAt(index);
      state = state.copyWith(
        existingImages: newList,
        deletedImages: [...state.deletedImages, imageUrl],
      );
    } else {
      final newList = [...state.selectedImages];
      newList.removeAt(index);
      
      int newPrimary = state.primaryImageIndex;
      if (newPrimary >= newList.length) {
        newPrimary = newList.isEmpty ? 0 : newList.length - 1;
      }
      
      state = state.copyWith(
        selectedImages: newList,
        primaryImageIndex: newPrimary,
      );
    }
  }

  void setPrimaryImage(int index) {
    state = state.copyWith(primaryImageIndex: index);
  }

  void addAttribute(String key, dynamic value) => onAttributeChanged(key, value);

  void removeAttribute(String key) {
    final newAttributes = {...state.attributes};
    newAttributes.remove(key);
    state = state.copyWith(attributes: newAttributes);
  }

  void onCustomizationGroupsChanged(List<CustomizationGroup> value) {
    state = state.copyWith(customizationGroups: value);
  }

  void toggleVariants(bool enabled) {
    state = state.copyWith(hasVariants: enabled);
    if (enabled && state.variants.isEmpty && state.variantAxes.isNotEmpty) {
      _regenerateVariants(state.variantAxes);
    }
  }

  void addAxis(String name, [List<String>? initialValues]) {
    if (state.variantAxes.length >= 3) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final newAxes = List<VariantAxis>.from(state.variantAxes);
    newAxes.add(VariantAxis(
      name: trimmed,
      values: initialValues ?? [],
      position: newAxes.length,
    ));
    _regenerateVariants(newAxes);
  }

  void removeAxis(int index) {
    if (index < 0 || index >= state.variantAxes.length) return;
    final newAxes = List<VariantAxis>.from(state.variantAxes);
    newAxes.removeAt(index);
    for (int i = 0; i < newAxes.length; i++) {
      newAxes[i] = newAxes[i].copyWith(position: i);
    }
    _regenerateVariants(newAxes);
  }

  void updateAxisValues(int axisIndex, List<String> values) {
    if (axisIndex < 0 || axisIndex >= state.variantAxes.length) return;
    final seen = <String>{};
    final deduped = <String>[];
    for (final val in values) {
      final base = val.contains('|') ? val.split('|')[0].trim().toLowerCase() : val.trim().toLowerCase();
      if (base.isNotEmpty && !seen.contains(base)) {
        seen.add(base);
        deduped.add(val);
      }
    }
    final newAxes = List<VariantAxis>.from(state.variantAxes);
    newAxes[axisIndex] = newAxes[axisIndex].copyWith(values: deduped);
    _regenerateVariants(newAxes);
  }

  void updateVariant(int index, ItemVariant updated) {
    if (index < 0 || index >= state.variants.length) return;
    final newVariants = List<ItemVariant>.from(state.variants);
    newVariants[index] = updated;
    state = state.copyWith(variants: newVariants);
  }

  void batchUpdatePrice(double? price, [bool onlyActive = true]) {
    final newVariants = state.variants.map((v) {
      if (!onlyActive || v.isActive) {
        return v.copyWith(price: price);
      }
      return v;
    }).toList();
    state = state.copyWith(variants: newVariants);
  }

  void batchUpdateStock(double stock, [bool onlyActive = true]) {
    final newVariants = state.variants.map((v) {
      if (!onlyActive || v.isActive) {
        return v.copyWith(stockQuantity: stock);
      }
      return v;
    }).toList();
    state = state.copyWith(variants: newVariants);
  }

  void toggleAllVariants(bool active) {
    final newVariants = state.variants.map((v) => v.copyWith(isActive: active)).toList();
    state = state.copyWith(variants: newVariants);
  }

  void _regenerateVariants(List<VariantAxis> axes) {
    final validAxes = axes.where((a) => a.values.isNotEmpty).toList();
    if (validAxes.isEmpty) {
      state = state.copyWith(variantAxes: axes, variants: []);
      return;
    }

    List<Map<String, String>> combinations = [{}];
    for (final axis in validAxes) {
      final List<Map<String, String>> nextCombos = [];
      for (final combo in combinations) {
        for (final val in axis.values) {
          nextCombos.add({...combo, axis.name: val});
        }
      }
      combinations = nextCombos;
    }

    if (combinations.length > 100) {
      combinations = combinations.sublist(0, 100);
    }

    final List<ItemVariant> newVariants = combinations.map((combo) {
      final existing = state.variants.cast<ItemVariant?>().firstWhere(
        (v) => v != null && _areAxisValuesEqual(v.axisValues, combo),
        orElse: () => null,
      );

      if (existing != null) {
        return existing.copyWith(axisValues: combo);
      }

      return ItemVariant(
        axisValues: combo,
        price: state.price > 0 ? state.price : null,
        stockQuantity: 0,
        isActive: true,
      );
    }).toList();

    state = state.copyWith(variantAxes: axes, variants: newVariants);
  }

  bool _areAxisValuesEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final bVal = b[entry.key];
      if (bVal == null) return false;
      final cleanA = entry.value.contains('|') ? entry.value.split('|')[0].trim().toLowerCase() : entry.value.trim().toLowerCase();
      final cleanB = bVal.contains('|') ? bVal.split('|')[0].trim().toLowerCase() : bVal.trim().toLowerCase();
      if (cleanA != cleanB) return false;
    }
    return true;
  }

  Future<void> submit(String storeId) async {
    final validImages = state.selectedImages.where((f) => f.existsSync()).toList();
    if (validImages.isEmpty && state.existingImages.isEmpty) {
      state = state.copyWith(errorMessage: 'Debes tener al menos una imagen');
      return;
    }

    if (state.discountPrice != null && state.discountPrice! >= state.price) {
      state = state.copyWith(errorMessage: 'El precio de oferta debe ser menor al precio base');
      return;
    }

    if (state.hasVariants) {
      if (state.variantAxes.isEmpty || state.variantAxes.every((a) => a.values.isEmpty)) {
        state = state.copyWith(errorMessage: 'Debes definir al menos un eje con opciones para las variantes.');
        return;
      }
      final activeVariants = state.variants.where((v) => v.isActive).toList();
      if (activeVariants.isEmpty) {
        state = state.copyWith(errorMessage: 'Debes tener al menos una variante activa.');
        return;
      }
      if (state.trackInventory) {
        for (final v in activeVariants) {
          if (v.stockQuantity < 0) {
            state = state.copyWith(errorMessage: 'El stock de las variantes activas no puede ser negativo.');
            return;
          }
        }
      }
    } else if (state.trackInventory) {
      if (state.stockQuantity == null || state.stockQuantity! <= 0) {
        state = state.copyWith(
          errorMessage: 'Debes especificar una cantidad de stock mayor a 0 al activar el control de inventario.',
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(itemRepositoryProvider);
      
      final properties = state.attributes.entries.map((e) {
        final template = state.availableTemplates.firstWhere((t) => t.name == e.key, orElse: () => PropertyTemplate(id: '', name: e.key, type: PropertyType.text, isRequired: false));
        return {
          'templateId': template.id.isEmpty ? null : template.id,
          'key': e.key,
          'type': template.type.name.toUpperCase(),
          'value': e.value,
        };
      }).toList();

      final itemData = {
        'storeId': storeId,
        'title': state.title,
        'description': state.description,
        'price': state.price,
        'priceType': state.priceType.name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(0)}').toUpperCase(),
        'itemType': state.itemType.name.toUpperCase(),
        'isFeatured': state.isFeatured,
        'isActive': state.isActive,
        'isAgeRestricted': state.isAgeRestricted,
        'discountPrice': state.discountPrice,
        'trackInventory': state.itemType == ItemType.service ? false : state.trackInventory,
        'stockQuantity': state.itemType == ItemType.service
            ? null
            : (state.trackInventory ? state.stockQuantity : null),
        'requiresBooking': state.requiresBooking,
        if (state.requiresBooking) ...{
          'bookingType': state.itemType == ItemType.service ? 'TIME_SLOT' : 'PRE_ORDER',
          if (state.itemType == ItemType.service)
            'slotConfig': _sanitizeSlotConfig(state.slotConfig),
          if (state.itemType == ItemType.product)
            'preorderConfig': _sanitizePreorderConfig(state.preorderConfig),
        } else ...{
          'bookingType': 'NONE',
        },
        'categoryId': state.categoryId,
        'attributes': {
          'properties': properties,
        },
        'customizationGroups': state.customizationGroups.map((c) => c.toJson()).toList(),
        'allowInstallments': state.allowInstallments,
        'lateFeePercentage': state.lateFeePercentage,
        'hasVariants': state.hasVariants,
        if (state.hasVariants) ...{
          'variantAxes': state.variantAxes.map((a) => a.toJson()).toList(),
          'variants': state.variants.map((v) => v.toJson()).toList(),
        },
        if (state.existingImages.isNotEmpty) 'existingImages': state.existingImages,
      };

      if (state.itemId != null) {
        await repository.updateItem(
          state.itemId!,
          itemData,
          newImages: validImages.isNotEmpty ? validImages : null,
          mainImageIndex: state.primaryImageIndex,
        );
        if (state.deletedImages.isNotEmpty) {
          await repository.deleteImages(state.deletedImages);
        }
      } else {
        await repository.createItem(
          itemData,
          validImages,
          mainImageIndex: state.primaryImageIndex,
        );
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      String message = 'Error al guardar el producto';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] is List ? (data['message'] as List).join(', ') : data['message'].toString();
        } else if (e.message != null) {
          message = e.message!;
        }
      } else {
        message = e.toString();
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Map<String, dynamic> _sanitizeSlotConfig(Map<String, dynamic> raw) {
    final rawSlots = raw['slots'] as List? ?? [];
    final cleanSlots = rawSlots.whereType<Map>().map((s) {
      final slotMap = <String, dynamic>{
        'startTime': s['startTime']?.toString() ?? '09:00',
        'endTime': s['endTime']?.toString() ?? '10:00',
        'label': s['label']?.toString() ?? 'Turno',
      };
      if (s['id'] != null && s['id'].toString().isNotEmpty) {
        slotMap['id'] = s['id'].toString();
      }
      if (s['dayOfWeek'] != null) {
        final dow = int.tryParse(s['dayOfWeek'].toString());
        if (dow != null) slotMap['dayOfWeek'] = dow;
      }
      if (s['specificDate'] != null && s['specificDate'].toString().isNotEmpty) {
        slotMap['specificDate'] = s['specificDate'].toString();
      }
      if (s['isActive'] != null) {
        slotMap['isActive'] = s['isActive'] == true || s['isActive'] == 'true';
      }
      return slotMap;
    }).toList();

    return {
      if (raw['id'] != null && raw['id'].toString().isNotEmpty) 'id': raw['id'].toString(),
      'minNoticeHours': int.tryParse(raw['minNoticeHours']?.toString() ?? '2') ?? 2,
      'serviceDurationMinutes': int.tryParse(raw['serviceDurationMinutes']?.toString() ?? '60') ?? 60,
      'allowSameDay': raw['allowSameDay'] == true || raw['allowSameDay'] == 'true',
      'maxConcurrentBookings': int.tryParse(raw['maxConcurrentBookings']?.toString() ?? '1') ?? 1,
      'serviceLocationType': raw['serviceLocationType']?.toString() ?? 'ON_SITE',
      'slots': cleanSlots,
    };
  }

  Map<String, dynamic> _sanitizePreorderConfig(Map<String, dynamic> raw) {
    return {
      if (raw['id'] != null && raw['id'].toString().isNotEmpty) 'id': raw['id'].toString(),
      'depositType': raw['depositType']?.toString() ?? 'PERCENTAGE',
      'depositValue': double.tryParse(raw['depositValue']?.toString() ?? '50') ?? 50.0,
      if (raw['estimatedLeadDaysMin'] != null)
        'estimatedLeadDaysMin': int.tryParse(raw['estimatedLeadDaysMin'].toString()),
      if (raw['estimatedLeadDaysMax'] != null)
        'estimatedLeadDaysMax': int.tryParse(raw['estimatedLeadDaysMax'].toString()),
      if (raw['maxPreOrderUnits'] != null)
        'maxPreOrderUnits': int.tryParse(raw['maxPreOrderUnits'].toString()),
      if (raw['settlementWindowHours'] != null)
        'settlementWindowHours': int.tryParse(raw['settlementWindowHours'].toString()),
    };
  }
}

final itemFormProvider = NotifierProvider.autoDispose<ItemFormNotifier, ItemFormState>(
  ItemFormNotifier.new,
);
