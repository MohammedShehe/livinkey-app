import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';

/// Vehicle documents screen for tenants.
/// - Toggle "I have a vehicle"
/// - If yes: must provide vehicle number + upload Vehicle Photo, RC Photo, Driver License
/// - Tenant can view/download only — NO delete (admin only)
class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _numberController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasVehicle = false;
  String? _vehicleNumber;
  bool _complete = true;
  List<Map<String, dynamic>> _documents = [];
  final Set<String> _uploadingKeys = {};

  static const _docMeta = {
    'vehicle_photo': {'label': 'Vehicle Photo', 'icon': Icons.directions_car_rounded},
    'vehicle_rc': {'label': 'RC Photo', 'icon': Icons.article_rounded},
    'driver_license': {'label': 'Driver License', 'icon': Icons.badge_rounded},
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMyVehicle();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        _hasVehicle = data['has_vehicle'] == true || data['has_vehicle'] == 1;
        _vehicleNumber = data['vehicle_number']?.toString();
        _numberController.text = _vehicleNumber ?? '';
        _complete = data['complete'] == true;
        final docs = data['documents'];
        if (docs is List) {
          _documents = List<Map<String, dynamic>>.from(
            docs.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        } else {
          _documents = [];
        }
      }
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load vehicle info');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHasVehicle(bool value) async {
    setState(() => _isSaving = true);
    try {
      final res = await _api.updateMyVehicle(hasVehicle: value);
      if (res['success'] == true) {
        await _load();
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            value ? 'Vehicle enabled. Please upload required documents.' : 'Vehicle disabled.',
          );
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, res['message']?.toString() ?? 'Update failed');
        }
      }
    } catch (_) {
      if (mounted) SnackbarHelper.showError(context, 'Update failed');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveVehicleNumber() async {
    final number = _numberController.text.trim().toUpperCase();
    if (number.isEmpty) {
      SnackbarHelper.showError(context, 'Enter vehicle number / plate');
      return;
    }
    if (number.length < 4 || number.length > 20) {
      SnackbarHelper.showError(context, 'Vehicle number must be 4–20 characters');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final res = await _api.updateMyVehicle(vehicleNumber: number);
      if (res['success'] == true) {
        await _load();
        if (mounted) SnackbarHelper.showSuccess(context, 'Vehicle number saved');
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, res['message']?.toString() ?? 'Save failed');
        }
      }
    } catch (_) {
      if (mounted) SnackbarHelper.showError(context, 'Save failed');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUpload(String docKey) async {
    if (_uploadingKeys.contains(docKey)) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kLivinkeyGreen),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kLivinkeyGreen),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingKeys.add(docKey));
    try {
      final res = await _api.uploadDocument(
        documentType: docKey,
        filePath: picked.path,
      );
      if (res['success'] == true) {
        await _load();
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            '${_docMeta[docKey]?['label'] ?? docKey} uploaded',
          );
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            res['message']?.toString() ?? 'Upload failed',
          );
        }
      }
    } catch (_) {
      if (mounted) SnackbarHelper.showError(context, 'Upload failed');
    } finally {
      if (mounted) setState(() => _uploadingKeys.remove(docKey));
    }
  }

  Future<void> _viewOrDownload(Map<String, dynamic> doc) async {
    final url = doc['document_url']?.toString();
    if (url == null || url.isEmpty) {
      SnackbarHelper.showError(context, 'No file URL');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      SnackbarHelper.showError(context, 'Invalid URL');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) SnackbarHelper.showError(context, 'Could not open file');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLivinkeyBlack,
      appBar: AppBar(
        backgroundColor: kLivinkeyBlack,
        elevation: 0,
        title: const Text('Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              color: kLivinkeyGreen,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildToggleCard(),
                  if (_hasVehicle) ...[
                    const SizedBox(height: 16),
                    _buildNumberCard(),
                    const SizedBox(height: 16),
                    if (!_complete)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Please upload all required vehicle documents and save the vehicle number.',
                                style: TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._documents.map(_buildDocCard),
                    const SizedBox(height: 12),
                    Text(
                      'Once uploaded, documents cannot be deleted by you. Contact admin if you need a re-upload.',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Toggle on if you have a vehicle parked at the property. You will be asked to upload vehicle photo, RC, and driving license.',
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kLivinkeyGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded, color: kLivinkeyGreen),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I have a vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 2),
                Text('Required docs if enabled', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (_isSaving)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kLivinkeyGreen))
          else
            Switch(
              value: _hasVehicle,
              activeColor: kLivinkeyGreen,
              onChanged: _toggleHasVehicle,
            ),
        ],
      ),
    );
  }

  Widget _buildNumberCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Number / Plate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _numberController,
            style: const TextStyle(color: Colors.white, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. KA01AB1234',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveVehicleNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: kLivinkeyGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Number', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> item) {
    final key = item['key']?.toString() ?? '';
    final label = item['label']?.toString() ?? _docMeta[key]?['label']?.toString() ?? key;
    final uploaded = item['uploaded'] == true;
    final doc = item['document'] is Map ? Map<String, dynamic>.from(item['document']) : null;
    final isUploading = _uploadingKeys.contains(key);
    final icon = _docMeta[key]?['icon'] as IconData? ?? Icons.insert_drive_file_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uploaded ? kLivinkeyGreen.withOpacity(0.45) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (uploaded ? kLivinkeyGreen : Colors.white).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: uploaded ? kLivinkeyGreen : Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  uploaded ? 'Uploaded · View / Download only' : 'Required · Not uploaded',
                  style: TextStyle(
                    color: uploaded ? kLivinkeyGreen.withOpacity(0.9) : Colors.orangeAccent.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isUploading)
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: kLivinkeyGreen))
          else if (uploaded && doc != null)
            IconButton(
              tooltip: 'View / Download',
              onPressed: () => _viewOrDownload(doc),
              icon: const Icon(Icons.visibility_rounded, color: Colors.white70),
            )
          else
            IconButton(
              tooltip: 'Upload',
              onPressed: () => _pickAndUpload(key),
              icon: const Icon(Icons.upload_rounded, color: kLivinkeyGreen),
            ),
        ],
      ),
    );
  }
}
