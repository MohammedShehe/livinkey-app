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

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await _api.getTenantAgreement();
    if (!mounted) return;
    setState(() { _loading = false; _error = res['success'] == true ? null : (res['message']?.toString() ?? 'Unable to load agreement.'); _agreement = res['data'] is Map ? Map<String,dynamic>.from(res['data']) : null; });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(backgroundColor: kLivinkeyBlack, foregroundColor: Colors.white, title: const Text('Agreements', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: kLivinkeyGreen)) : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center))) : _agreement == null || _agreement!['enabled'] != true ? const Center(child: Text('No active tenant agreement.', style: TextStyle(color: Colors.white70))) : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.description_rounded, color: kLivinkeyGreen), SizedBox(width: 10), Text('Your Tenant Agreement', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))]), const SizedBox(height: 18), Text(_agreement!['text']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.7)), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (_agreement!['accepted'] == true ? kLivinkeyGreen : Colors.orange).withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Text(_agreement!['accepted'] == true ? 'Accepted' : 'Acceptance required', style: TextStyle(color: _agreement!['accepted'] == true ? kLivinkeyGreen : Colors.orange, fontWeight: FontWeight.w700))) ]))));
  }
}
