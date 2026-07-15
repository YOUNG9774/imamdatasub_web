import 'package:dio/dio.dart';
import '../../../../core/config/app_endpoints.dart';
import '../../buy_data/domain/entities/data_plan_entity.dart';

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class DataPriceRow {
  const DataPriceRow({
    required this.id,
    required this.providerPlanId,
    required this.network,
    required this.name,
    required this.providerCost,
    required this.sellingPrice,
    required this.profit,
    required this.isActive,
    this.planType,
    this.validity,
  });

  final String id;
  final String providerPlanId;
  final String network;
  final String name;
  final String? planType;
  final String? validity;
  final double providerCost;
  final double sellingPrice;
  final double profit;
  final bool isActive;

  factory DataPriceRow.fromJson(Map<String, dynamic> json) {
    return DataPriceRow(
      id: json['id']?.toString() ?? '',
      providerPlanId: json['provider_plan_id']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      planType: json['plan_type']?.toString(),
      validity: json['validity']?.toString(),
      providerCost: _num(json['provider_cost']),
      sellingPrice: _num(json['selling_price']),
      profit: _num(json['profit']),
      isActive: json['is_active'] == true,
    );
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AdminPricingRepository {
  const AdminPricingRepository(this._dio);

  final Dio _dio;

  Future<AdminUserSummary?> getAdminMe() async {
    try {
      final response = await _dio.get(AppEndpoints.adminMe);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final admin = data['admin'] as Map<String, dynamic>?;
      return admin == null ? null : AdminUserSummary.fromJson(admin);
    } on DioException {
      return null;
    }
  }

  Future<List<DataPriceRow>> getDataPrices(NetworkProvider network) async {
    final response = await _dio.get(
      AppEndpoints.adminDataPrices(network: network.code),
    );
    final list = (response.data['data'] ?? const []) as List<dynamic>;
    return list
        .map(
          (item) =>
              DataPriceRow.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<DataPriceRow>> syncDataPrices(NetworkProvider network) async {
    final response = await _dio.post(
      AppEndpoints.adminSyncDataPrices(network.code),
    );
    final list = (response.data['data'] ?? const []) as List<dynamic>;
    return list
        .map(
          (item) =>
              DataPriceRow.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> updatePrice({
    required String id,
    double? sellingPrice,
    bool? isActive,
    bool resetToDefault = false,
  }) async {
    await _dio.patch(
      AppEndpoints.adminDataPrice(id),
      data: {
        if (resetToDefault) 'selling_price': null,
        if (!resetToDefault && sellingPrice != null)
          'selling_price': sellingPrice,
        if (isActive != null) 'is_active': isActive,
      },
    );
  }

  Future<void> applyMarkup({
    required NetworkProvider network,
    required double markupNaira,
    required double markupPercent,
  }) async {
    await _dio.post(
      AppEndpoints.adminApplyDataMarkup,
      data: {
        'network': network.code,
        'markup_naira': markupNaira,
        'markup_percent': markupPercent,
      },
    );
  }
}
