// lib/widgets/tenant/bill_breakdown_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../utils/constants.dart';

/// Itemised, clearly labelled breakdown of what a bill contains:
/// rent, electricity, maintenance, other charges (with the note), late fine,
/// amount already paid and the balance still due.
class BillBreakdownCard extends StatelessWidget {
  final BillModel bill;
  const BillBreakdownCard({super.key, required this.bill});

  static String _inr(double v) =>
      '₹${NumberFormat('#,##,##0.00', 'en_IN').format(v)}';

  @override
  Widget build(BuildContext context) {
    final billed = bill.totalAmount + bill.fineAmount;
    final due = (billed - bill.paidAmount).clamp(0, double.infinity).toDouble();
    final earlier =
        (bill.totalOutstanding - due).clamp(0, double.infinity).toDouble();

    final rows = <_Row>[
      if (bill.rentAmount > 0) _Row('Monthly rent', _inr(bill.rentAmount), Icons.home_rounded),
      if (bill.electricityAmount > 0)
        _Row('Electricity', _inr(bill.electricityAmount), Icons.bolt_rounded),
      if (bill.maintenanceAmount > 0)
        _Row('Maintenance', _inr(bill.maintenanceAmount), Icons.build_rounded),
      if (bill.otherCharges > 0)
        _Row(
          'Other charges',
          _inr(bill.otherCharges),
          Icons.receipt_long_rounded,
          note: bill.otherChargesNote,
        ),
      if (bill.fineAmount > 0)
        _Row('Late payment fine', _inr(bill.fineAmount), Icons.warning_amber_rounded,
            color: Colors.redAccent,
            note: 'Added because this bill was not paid by the due date.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bill.billingMonth != null && bill.billingMonth!.isNotEmpty
                      ? 'Bill details · ${bill.billingMonth}'
                      : 'Bill details',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _StatusPill(status: bill.status, overdue: bill.isOverdue),
            ],
          ),
          const SizedBox(height: 14),
          for (final r in rows) _line(r),
          const Divider(color: Colors.white12, height: 22),
          _plain('Total billed', _inr(billed), bold: true),
          if (bill.paidAmount > 0)
            _plain('Paid so far', '− ${_inr(bill.paidAmount)}', color: kLivinkeyGreen),
          _plain('Balance due for this bill', _inr(due),
              bold: true, color: due > 0.005 ? Colors.orange : kLivinkeyGreen),
          if (earlier > 0.005) ...[
            const SizedBox(height: 6),
            _plain('Earlier unpaid bills', _inr(earlier), color: Colors.orange),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 14, color: Colors.white.withOpacity(0.45)),
              const SizedBox(width: 6),
              Text(
                'Pay by ${DateFormat('d MMM yyyy').format(bill.validUntil.toLocal())}',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(_Row r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: (r.color ?? kLivinkeyGreen).withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(r.icon, size: 16, color: r.color ?? kLivinkeyGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (r.note != null && r.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(r.note!,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5, height: 1.3)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(r.value,
              style: TextStyle(
                  color: r.color ?? Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _plain(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(bold ? 0.92 : 0.65),
                    fontSize: 13.5,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  final IconData icon;
  final String? note;
  final Color? color;
  _Row(this.label, this.value, this.icon, {this.note, this.color});
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool overdue;
  const _StatusPill({required this.status, required this.overdue});

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;
    switch (status) {
      case 'paid':
        text = 'Paid';
        color = kLivinkeyGreen;
        break;
      case 'partially_paid':
        text = 'Partly paid';
        color = Colors.amber;
        break;
      default:
        text = overdue || status == 'overdue' ? 'Overdue' : 'Unpaid';
        color = overdue || status == 'overdue' ? Colors.redAccent : Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}
