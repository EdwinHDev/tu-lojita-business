import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/company_model.dart';
import '../../../../core/config/api_config.dart';

class CompanyService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<CompanyCheckResponse> checkHasCompany(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/check/has-company'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return CompanyCheckResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Error al verificar empresa: ${response.body}');
    }
  }

  Future<StoreCheckResponse> checkHasStore(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/check/has-store'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return StoreCheckResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Error al verificar tienda: ${response.body}');
    }
  }

  Future<StoreDetails> getStoreDetails(String storeId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stores/$storeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return StoreDetails.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Error al obtener detalles de tienda: ${response.body}');
    }
  }

  Future<Company> createCompany(CreateCompanyDto dto, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(dto.toJson()),
    );

    if (response.statusCode == 201) {
      return Company.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Error al crear empresa: ${response.body}');
    }
  }

  Future<Company> getCompany(String companyId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/companies/$companyId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Company.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Error al obtener empresa: ${response.body}');
    }
  }
}
