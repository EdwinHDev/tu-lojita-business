import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'store_category_notifier.dart';
import 'store_category_state.dart';

final storeCategoryProvider = NotifierProvider<StoreCategoryNotifier, StoreCategoryState>(() {
  return StoreCategoryNotifier();
});
