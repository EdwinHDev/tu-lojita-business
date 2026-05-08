import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';

class ItemFormState {
  final List<File> selectedImages;
  final List<String> existingImages;
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

  const ItemFormState({
    this.selectedImages = const [],
    this.existingImages = const [],
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
    this.categoryId,
    this.customizationGroups = const [],
  });

  ItemFormState copyWith({
    List<File>? selectedImages,
    List<String>? existingImages,
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
  }) {
    return ItemFormState(
      selectedImages: selectedImages ?? this.selectedImages,
      existingImages: existingImages ?? this.existingImages,
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
      categoryId: categoryId ?? this.categoryId,
      customizationGroups: customizationGroups ?? this.customizationGroups,
    );
  }
}

class ItemFormNotifier extends Notifier<ItemFormState> {
  @override
  ItemFormState build() {
    return const ItemFormState();
  }

  void initForEditing(Item item) {
    Map<String, dynamic> mappedAttributes = {};
    if (item.attributes != null && item.attributes!['properties'] != null) {
      final props = item.attributes!['properties'] as List;
      for (var p in props) {
        mappedAttributes[p['key']] = p['value'];
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
      categoryId: item.categoryId,
      existingImages: item.images,
      attributes: mappedAttributes,
      customizationGroups: item.customizationGroups,
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
  void onDiscountPriceChanged(double? value) => state = state.copyWith(discountPrice: value);
  void onItemTypeChanged(ItemType value) => state = state.copyWith(itemType: value);
  void onTrackInventoryChanged(bool value) => state = state.copyWith(trackInventory: value);
  void onStockQuantityChanged(double? value) => state = state.copyWith(stockQuantity: value);
  void onRequiresBookingChanged(bool value) => state = state.copyWith(requiresBooking: value);
  
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
      // TODO: Log error to a monitoring service
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
      final newList = [...state.existingImages];
      newList.removeAt(index);
      state = state.copyWith(existingImages: newList);
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
        'discountPrice': state.discountPrice,
        'trackInventory': state.trackInventory,
        'stockQuantity': state.trackInventory ? state.stockQuantity : null,
        'requiresBooking': state.requiresBooking,
        'categoryId': state.categoryId,
        'attributes': {
          'properties': properties,
        },
        'customizationGroups': state.customizationGroups.map((c) => c.toJson()).toList(),
        if (state.existingImages.isNotEmpty) 'existingImages': state.existingImages,
      };

      if (state.itemId != null) {
        await repository.updateItem(
          state.itemId!,
          itemData,
          newImages: validImages.isNotEmpty ? validImages : null,
          mainImageIndex: state.primaryImageIndex,
        );
      } else {
        await repository.createItem(
          itemData, 
          validImages,
          mainImageIndex: state.primaryImageIndex,
        );
      }
      
      if (!ref.mounted) return;
      
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final msg = e.response?.data != null && e.response!.data['message'] != null
          ? (e.response!.data['message'] is List
              ? (e.response!.data['message'] as List).join(', ')
              : e.response!.data['message'].toString())
          : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final itemFormProvider = NotifierProvider.autoDispose<ItemFormNotifier, ItemFormState>(() {
  return ItemFormNotifier();
});
