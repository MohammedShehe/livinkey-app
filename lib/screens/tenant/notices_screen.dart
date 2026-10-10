import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await ApiService().getLivinkeyNotices();
    if (!mounted) return;
    if (response['success'] == true) {
      final raw = response['data'];
      setState(() {
        _notices = raw is List
            ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = response['message']?.toString() ?? 'Unable to load notices.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        backgroundColor: kLivinkeyBlack,
        foregroundColor: Colors.white,
        title: const Text('Notices', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotices,
        color: kLivinkeyGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kLivinkeyGreen));
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .28),
          Icon(Icons.error_outline_rounded, color: Colors.white.withOpacity(.35), size: 52),
          const SizedBox(height: 14),
          Center(child: Text(_error!, style: TextStyle(color: Colors.white.withOpacity(.65)))),
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadNotices,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_notices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .28),
          Icon(Icons.campaign_outlined, color: Colors.white.withOpacity(.25), size: 64),
          const SizedBox(height: 14),
          Center(child: Text('No notices at the moment.', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 15))),
          const SizedBox(height: 8),
          Center(child: Text('Pull down to refresh.', style: TextStyle(color: Colors.white.withOpacity(.35), fontSize: 12))),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _notices.length,
      itemBuilder: (context, index) {
        final notice = _notices[index];
        final url = notice['image_url']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: url.isEmpty ? null : () => _showImage(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFF151515),
                child: url.isEmpty
                    ? const SizedBox(height: 180, child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48))
                    : Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 180,
                          child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: kLivinkeyGreen)));
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.92),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
