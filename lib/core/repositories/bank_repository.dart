import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final bankRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return BankRepository(dio);
});

class BankRepository {
  final Dio _dio;

  BankRepository(this._dio);

  Future<List<Bank>> getBanks() async {
    try {
      final response = await _dio.get('/banks');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Bank.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final banksProvider = FutureProvider<List<Bank>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return await repository.getBanks();
});
