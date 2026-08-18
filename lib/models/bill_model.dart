import 'package:livinkey/models/auth_models.dart';

class BillModel {
  final int id;
  final int tenantId;
  final double rentAmount;
  final double electricityAmount;
  final double maintenanceAmount;
  final double otherCharges;
  final double totalAmount;
  final double paidAmount;
  final double fineAmount;
  final String status;
  final String? paymentQr;
  final String? partialPaymentQr;
  final String? adminQr;
  final String? electricityMeterImage;
  final DateTime sentAt;
  final DateTime validUntil;
  final String? tenantName;
  final String? tenantEmail;
  final String? tenantPhone;
  final String? pgName;
  final String? roomNumber;
  final double dueAmount;
  final bool isOverdue;

  BillModel({
    required this.id,
    required this.tenantId,
    required this.rentAmount,
    required this.electricityAmount,
    required this.maintenanceAmount,
    required this.otherCharges,
    required this.totalAmount,
    required this.paidAmount,
    required this.fineAmount,
    required this.status,
    this.paymentQr,
    this.partialPaymentQr,
    this.adminQr,
    this.electricityMeterImage,
    required this.sentAt,
    required this.validUntil,
    this.tenantName,
    this.tenantEmail,
    this.tenantPhone,
    this.pgName,
    this.roomNumber,
    this.dueAmount = 0,
    this.isOverdue = false,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] ?? 0,
      tenantId: json['tenant_id'] ?? 0,
      rentAmount: json['rent_amount']?.toDouble() ?? 0,
      electricityAmount: json['electricity_amount']?.toDouble() ?? 0,
      maintenanceAmount: json['maintenance_amount']?.toDouble() ?? 0,
      otherCharges: json['other_charges']?.toDouble() ?? 0,
      totalAmount: json['total_amount']?.toDouble() ?? 0,
      paidAmount: json['paid_amount']?.toDouble() ?? 0,
      fineAmount: json['fine_amount']?.toDouble() ?? 0,
      status: json['status'] ?? 'unpaid',
      paymentQr: json['payment_qr'],
      partialPaymentQr: json['partial_payment_qr'],
      adminQr: json['admin_qr'],
      electricityMeterImage: json['electricity_meter_image'],
      sentAt: DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
      validUntil: DateTime.parse(json['valid_until'] ?? DateTime.now().toIso8601String()),
      tenantName: json['tenant_name'],
      tenantEmail: json['tenant_email'],
      tenantPhone: json['tenant_phone'],
      pgName: json['pg_name'],
      roomNumber: json['room_number'],
      dueAmount: json['due_amount']?.toDouble() ?? 0,
      isOverdue: json['is_overdue'] ?? false,
    );
  }
}

class PaymentHistory {
  final UserModel? tenant;
  final List<PaymentRecord> onlinePayments;
  final List<PaymentRecord> cashPayments;
  final List<PaymentRecord> paymentProofs;

  PaymentHistory({
    this.tenant,
    this.onlinePayments = const [],
    this.cashPayments = const [],
    this.paymentProofs = const [],
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      tenant: json['tenant'] != null ? UserModel.fromJson(json['tenant']) : null,
      onlinePayments: json['online_payments'] is List
          ? (json['online_payments'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
      cashPayments: json['cash_payments'] is List
          ? (json['cash_payments'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
      paymentProofs: json['payment_proofs'] is List
          ? (json['payment_proofs'] as List)
              .map((p) => PaymentRecord.fromJson(p))
              .toList()
          : [],
    );
  }
}

class PaymentRecord {
  final int id;
  final int billId;
  final double amount;
  final String paymentMethod;
  final String? transactionId;
  final String status;
  final DateTime createdAt;
  final String? type;
  final double? billTotal;

  PaymentRecord({
    required this.id,
    required this.billId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.status,
    required this.createdAt,
    this.type,
    this.billTotal,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] ?? 0,
      billId: json['bill_id'] ?? 0,
      amount: json['amount']?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] ?? json['_gateway'] ?? 'online',
      transactionId: json['transaction_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      type: json['_type'],
      billTotal: json['bill_total']?.toDouble(),
    );
  }
}