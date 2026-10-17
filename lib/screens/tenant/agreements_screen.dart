import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});
  @override State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _agreement;

  static const List<String> _terms = [
    'Tenant shall occupy premises for residential purpose only and not for any other purpose without prior written permission/consent of the owner.',
    'Tenant shall return the room in the same condition as it was given at the time of rent agreement. Fixed Rs. 500/- checkout fee is compulsory.',
    'Tenant shall not make any addition/alteration in the rented premises without prior consent/permission of the owner and shall not do work which will cause damage.',
    'Tenant shall pay rent monthly in the first week of every month on or before the 7th day. Late payment fine: Rs. 100/- per day until payment is received.',
    "Tenant cannot vacate before completion of the agreed 10/12-month lock-in and shall give one month's prior notice before vacating.",
    'Tenant shall provide two identity proofs along with a passport-size photograph.',
    'In case of any dispute, the matter shall be referred to Phagwara Court only.',
    'Tenant is responsible for any illegal work done in PG premises/room (drugs, fighting or any other illegal work).',
    'If tenant is found violating the rules, owner has the right to terminate the agreement and require the tenant to vacate the same day.',
    'Electricity bill shall be paid on or before the 5th of every month.',
    'Tenant must not misbehave with any staff members of LIVINKEY.',
    'Fixed maintenance charges of Rs. 300/- will be taken every month.',
    'Security deposit will be refunded upon receipt of written notice to vacate at least one month prior to the end of the lock-in period.',
    'Wi-Fi is not an inclusive service provided by LIVINKEY; it is an additional service and LIVINKEY does not guarantee it.',
    'No loud music, parties or disturbances are allowed inside the PG premises.',
    'LIVINKEY is not responsible for anything stolen inside/outside the room from common areas.',
    'Outsiders are not allowed to stay overnight. Only parents are allowed with prior permission.',
    'If anything in the room is broken, damaged or stolen, the tenant is responsible and double the amount will be charged.',
    'If the tenant loses the door keys, the tenant must pay Rs. 2,000/-.',
    'The source agreement states that the first party/owner will not take responsibility in case of injury, mishap or death.',
    'If the sub-meter fails, the average charge will be taken.',
    'Police verification is the responsibility of the tenant.',
    'For international students, C Form is necessary and must be taken 30 days before visa expiry.',
    'If the tenant stays beyond the agreement tenure, even for a single day, Rs. 800/- per day will be charged.',
    'If rent remains unpaid and tenant fails to respond to LIVINKEY messages or calls for 15 days, LIVINKEY reserves the right to break the lock and vacate the room.'
  ];

  Future<void> _accept() async {
    final res = await _api.acceptTenantAgreement();
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement accepted successfully.')));
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Unable to accept agreement.')));
    }
  }

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await _api.getTenantAgreement();
    if (!mounted) return;
    setState(() { _loading = false; _error = res['success'] == true ? null : (res['message']?.toString() ?? 'Unable to load agreement.'); _agreement = res['data'] is Map ? Map<String,dynamic>.from(res['data']) : null; });
  }

  Widget _detail(String label, dynamic value) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))), Expanded(child: Text((value == null || value.toString().trim().isEmpty) ? '—' : value.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))]));

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(backgroundColor: kLivinkeyBlack, foregroundColor: Colors.white, title: const Text('Agreements', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kLivinkeyGreen),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _agreement == null || _agreement!['enabled'] != true
                  ? const Center(
                      child: Text(
                        'No active tenant agreement.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description_rounded,
                                    color: kLivinkeyGreen),
                                SizedBox(width: 10),
                                Text(
                                  'Your Tenant Agreement',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _detail('Apartment name',
                                _agreement!['values']?['PG_NAME']),
                            _detail('Room no.',
                                _agreement!['values']?['ROOM_NUMBER']),
                            _detail('Time period',
                                _agreement!['values']?['STAYING_PERIOD']),
                            _detail('Tenant name',
                                _agreement!['values']?['TENANT_NAME']),
                            _detail('Mobile no.',
                                _agreement!['values']?['MOBILE_NO']),
                            _detail('Parents no.',
                                _agreement!['values']?['PARENTS_NO']),
                            _detail('Gender', _agreement!['values']?['GENDER']),
                            _detail('Nationality',
                                _agreement!['values']?['NATIONALITY']),
                            _detail('Date of joining',
                                _agreement!['values']?['JOINING_DATE']),
                            _detail('Monthly rent (Rs.)',
                                _agreement!['values']?['RENT']),
                            _detail('Security deposit (Rs.)',
                                _agreement!['values']?['SECURITY_FEE']),
                            _detail('Payment date',
                                _agreement!['values']?['PAYMENT_DATE']),
                            const SizedBox(height: 16),
                            const Text(
                              'TERMS & CONDITIONS',
                              style: TextStyle(
                                color: kLivinkeyGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              _terms.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${i + 1}. ${_terms[i]}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_agreement!['accepted'] == true
                                        ? kLivinkeyGreen
                                        : Colors.orange)
                                    .withOpacity(.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _agreement!['accepted'] == true
                                    ? 'Accepted'
                                    : 'Acceptance required',
                                style: TextStyle(
                                  color: _agreement!['accepted'] == true
                                      ? kLivinkeyGreen
                                      : Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_agreement!['accepted'] != true) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _accept,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kLivinkeyGreen,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Accept Agreement'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }
}
