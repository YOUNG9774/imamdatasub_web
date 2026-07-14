import 'package:equatable/equatable.dart';

class ReferralEntity extends Equatable {
  const ReferralEntity({
    required this.referralCode,
    required this.totalReferrals,
    required this.totalEarned,
    required this.pendingCommission,
    required this.paidCommission,
    this.referees = const [],
  });

  final String referralCode;
  final int totalReferrals;
  final double totalEarned;
  final double pendingCommission;
  final double paidCommission;
  final List<RefereeEntity> referees;

  String get shareLink =>
      'https://imamdatasub.com.ng/ref/$referralCode';

  factory ReferralEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ReferralEntity(
      referralCode: data['referral_code']?.toString() ?? '',
      totalReferrals:
          int.tryParse(data['total_referrals']?.toString() ?? '0') ?? 0,
      totalEarned: _toDouble(data['total_earned']),
      pendingCommission: _toDouble(data['pending_commission']),
      paidCommission: _toDouble(data['paid_commission']),
      referees: (data['referees'] as List<dynamic>? ?? [])
          .map((e) =>
              RefereeEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static const empty = ReferralEntity(
    referralCode: '',
    totalReferrals: 0,
    totalEarned: 0,
    pendingCommission: 0,
    paidCommission: 0,
  );

  @override
  List<Object?> get props => [
        referralCode,
        totalReferrals,
        totalEarned,
        pendingCommission,
        paidCommission,
      ];
}

class RefereeEntity extends Equatable {
  const RefereeEntity({
    required this.name,
    required this.joinedAt,
    required this.totalTransactions,
    required this.commissionEarned,
  });

  final String name;
  final DateTime joinedAt;
  final int totalTransactions;
  final double commissionEarned;

  factory RefereeEntity.fromJson(Map<String, dynamic> json) {
    return RefereeEntity(
      name: json['name']?.toString() ?? 'User',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
      totalTransactions:
          int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
      commissionEarned: double.tryParse(
              json['commission_earned']?.toString() ?? '0') ??
          0.0,
    );
  }

  @override
  List<Object?> get props =>
      [name, joinedAt, totalTransactions, commissionEarned];
}
