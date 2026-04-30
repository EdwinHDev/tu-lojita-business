import 'package:dio/dio.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';

abstract class CompanyRemoteDataSource {
  Future<Map<String, dynamic>> createCompany({
    required String name,
    required String rif,
    required String logo,
  });
  Future<void> updateStoreBranchName(String storeId, String branchName);
  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? rif,
    String? logo,
  });
}

class CompanyRemoteDataSourceImpl implements CompanyRemoteDataSource {
  final Dio _dio;

  CompanyRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> createCompany({
    required String name,
    required String rif,
    required String logo,
  }) async {
    try {
      final response = await _dio.post(
        '/companies',
        data: {
          'name': name,
          'rif': rif,
          'logo': logo,
        },
      );
      
      if (response.data == null) return {};
      if (response.data is! Map) return {};
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(ErrorParser.parse(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateStoreBranchName(String storeId, String branchName) async {
    try {
      await _dio.patch(
        '/stores/$storeId',
        data: {
          'branchName': branchName,
        },
      );
    } on DioException catch (e) {
      throw Exception(ErrorParser.parse(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? rif,
    String? logo,
  }) async {
    try {
      await _dio.patch(
        '/companies/$companyId',
        data: {
          // ignore: use_null_aware_elements
          if (name != null) 'name': name,
          // ignore: use_null_aware_elements
          if (rif != null) 'rif': rif,
          // ignore: use_null_aware_elements
          if (logo != null) 'logo': logo,
        },
      );
    } on DioException catch (e) {
      throw Exception(ErrorParser.parse(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
