import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/item.dart';

class ItemFormState {
  final List<File> selectedImages;
  final int primaryImageIndex;
  final Map<String, dynamic> attributes;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  // New fields
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

  const ItemFormState({
    this.selectedImages = const [],
    this.primaryImageIndex = 0,
    this.attributes = const {},
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
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
  });

  ItemFormState copyWith({
    List<File>? selectedImages,
    int? primaryImageIndex,
    Map<String, dynamic>? attributes,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
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
  }) {
    return ItemFormState(
      selectedImages: selectedImages ?? this.selectedImages,
      primaryImageIndex: primaryImageIndex ?? this.primaryImageIndex,
      attributes: attributes ?? this.attributes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
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
    );
  }
}

class ItemFormNotifier extends Notifier<ItemFormState> {
  @override
  ItemFormState build() {
    return const ItemFormState();
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
  void onCategoryIdChanged(String? value) => state = state.copyWith(categoryId: value);

  void addImages(List<File> images) {
    // Robust selection: Filter out already selected files if needed, but here we just append
    state = state.copyWith(selectedImages: [...state.selectedImages, ...images]);
  }

  void removeImage(int index) {
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

  void setPrimaryImage(int index) {
    state = state.copyWith(primaryImageIndex: index);
  }

  void addAttribute(String key, dynamic value) {
    final newAttributes = {...state.attributes};
    newAttributes[key] = value;
    state = state.copyWith(attributes: newAttributes);
  }

  void removeAttribute(String key) {
    final newAttributes = {...state.attributes};
    newAttributes.remove(key);
    state = state.copyWith(attributes: newAttributes);
  }

  Future<void> submit(String storeId) async {
    if (state.selectedImages.isEmpty) {
      state = state.copyWith(errorMessage: 'Debes seleccionar al menos una imagen');
      return;
    }

    if (state.discountPrice != null && state.discountPrice! >= state.price) {
      state = state.copyWith(errorMessage: 'El precio de oferta debe ser menor al precio base');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(itemRepositoryProvider);
      
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
        'attributes': state.attributes,
      };

      await repository.createItem(
        itemData, 
        state.selectedImages,
        mainImageIndex: state.primaryImageIndex,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final itemFormProvider = NotifierProvider.autoDispose<ItemFormNotifier, ItemFormState>(() {
  return ItemFormNotifier();
});
