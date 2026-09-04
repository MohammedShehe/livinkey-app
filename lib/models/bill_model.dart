import 'package:livinkey/models/auth_models.dart';

class BillModel {
  final int id;
  final int tenantId;
  final String? billingMonth;
  final DateTime? periodFrom;
  final DateTime? periodTill;
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
  final String? electricityMeterImage2;
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
    this.billingMonth,
    this.periodFrom,
    this.periodTill,
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
    this.electricityMeterImage2,
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

  /// True when at least one meter image is attached.
  bool get hasMeterImages =>
      (electricityMeterImage != null && electricityMeterImage!.isNotEmpty) ||
      (electricityMeterImage2 != null && electricityMeterImage2!.isNotEmpty);

  /// Ordered list of available meter image URLs (1 or 2).
  List<String> get meterImageUrls {
    final list = <String>[];
    if (electricityMeterImage != null && electricityMeterImage!.isNotEmpty) {
      list.add(electricityMeterImage!);
    }
    if (electricityMeterImage2 != null && electricityMeterImage2!.isNotEmpty) {
      list.add(electricityMeterImage2!);
    }
    return list;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      tenantId: json['tenant_id'] is int
          ? json['tenant_id'] as int
          : int.tryParse('${json['tenant_id']}') ?? 0,
      billingMonth: json['billing_month']?.toString(),
      periodFrom: _toDate(json['period_from']),
      periodTill: _toDate(json['period_till']),
      rentAmount: _toDouble(json['rent_amount']),
      electricityAmount: _toDouble(json['electricity_amount']),
      maintenanceAmount: _toDouble(json['maintenance_amount']),
      otherCharges: _toDouble(json['other_charges']),
      totalAmount: _toDouble(json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      fineAmount: _toDouble(json['fine_amount']),
      status: json['status']?.toString() ?? 'unpaid',
      paymentQr: json['payment_qr']?.toString(),
      partialPaymentQr: json['partial_payment_qr']?.toString(),
      adminQr: json['admin_qr']?.toString(),
      electricityMeterImage: json['electricity_meter_image']?.toString(),
      electricityMeterImage2: json['electricity_meter_image_2']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse(json['valid_until']?.toString() ?? '') ?? DateTime.now(),
      tenantName: json['tenant_name']?.toString(),
      tenantEmail: json['tenant_email']?.toString(),
      tenantPhone: json['tenant_phone']?.toString(),
      pgName: json['pg_name']?.toString(),
      roomNumber: json['room_number']?.toString(),
      dueAmount: _toDouble(json['due_amount'] ?? json['total_due']),
      isOverdue: json['is_overdue'] == true || json['is_overdue'] == 1 || json['is_overdue'] == '1',
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
              .map((p) => PaymentRecord.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      cashPayments: json['cash_payments'] is List
          ? (json['cash_payments'] as List)
              .map((p) => PaymentRecord.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      paymentProofs: json['payment_proofs'] is List
          ? (json['payment_proofs'] as List)
              .map((p) => PaymentRecord.fromJson(Map<String, dynamic>.from(p as Map)))
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
  final String? adminNotes;

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
    this.adminNotes,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      billId: json['bill_id'] is int
          ? json['bill_id'] as int
          : int.tryParse('${json['bill_id']}') ?? 0,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount']}') ?? 0,
      paymentMethod: json['payment_method']?.toString() ??
          json['_gateway']?.toString() ??
          'online',
      transactionId: json['transaction_id']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['_type']?.toString() ?? json['type']?.toString(),
      billTotal: json['bill_total'] != null
          ? ((json['bill_total'] is num)
              ? (json['bill_total'] as num).toDouble()
              : double.tryParse('${json['bill_total']}'))
          : null,
      adminNotes: json['admin_notes']?.toString() ?? json['notes']?.toString(),
    );
  }
}
