import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';
import '../common/notification_screen.dart';
import 'tenant_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;
  bool _isLoading = true;

  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _uploadedDocuments = [];
  List<Map<String, dynamic>> _requiredDocuments = [];
  String _residency = 'national';

  final Set<int> _selectedIndices = {};
  bool get _isSelectionMode => _selectedIndices.isNotEmpty;

  bool _isDownloadingAll = false;
  bool _isDownloadingSelected = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: kFadeDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await _api.getUser();
      if (user != null && user.residency != null) {
        _residency = user.residency!;
      }

      final typesRes = await _api.getDocumentTypes();
      
      if (typesRes['success'] == true) {
        final data = typesRes['data'];
        
        if (data is List) {
          _requiredDocuments = List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          if (data['documents'] != null && data['documents'] is List) {
            _requiredDocuments = List<Map<String, dynamic>>.from(data['documents']);
          } else if (data['data'] != null && data['data'] is List) {
            _requiredDocuments = List<Map<String, dynamic>>.from(data['data']);
          } else {
            _requiredDocuments = _getFallbackDocuments(_residency);
          }
        } else {
          _requiredDocuments = _getFallbackDocuments(_residency);
        }
      } else {
        _requiredDocuments = _getFallbackDocuments(_residency);
      }

      final docsRes = await _api.getMyDocuments();
      
      if (docsRes['success'] == true) {
        final data = docsRes['data'];
        
        if (data is Map<String, dynamic>) {
          if (data['tenant'] != null && data['tenant'] is Map<String, dynamic>) {
            final tenant = data['tenant'] as Map<String, dynamic>;
            if (tenant['residency'] != null) {
              _residency = tenant['residency'].toString();
            }
          }
          
          if (data['uploaded_documents'] != null && data['uploaded_documents'] is List) {
            _uploadedDocuments = List<Map<String, dynamic>>.from(data['uploaded_documents']);
          } else {
            _uploadedDocuments = [];
          }
          
          if (data['data'] != null && data['data'] is Map<String, dynamic>) {
            final nestedData = data['data'] as Map<String, dynamic>;
            if (nestedData['uploaded_documents'] != null && nestedData['uploaded_documents'] is List) {
              _uploadedDocuments = List<Map<String, dynamic>>.from(nestedData['uploaded_documents']);
            }
          }
        } else if (data is List) {
          _uploadedDocuments = List<Map<String, dynamic>>.from(data);
        } else {
          _uploadedDocuments = [];
        }
      } else {
        _uploadedDocuments = [];
      }

      if (mounted) {
        await NotificationService().refresh(isTenant: true);
      }
    } catch (e) {
      final user = await _api.getUser();
      if (user != null && user.residency != null) {
        _residency = user.residency!;
      }
      _requiredDocuments = _getFallbackDocuments(_residency);
      _uploadedDocuments = [];
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load documents');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackDocuments(String residency) {
    if (residency == 'international') {
      return [
        {'label': 'Passport Size Photo', 'key': 'passport_photo', 'required': true},
        {'label': 'Passport', 'key': 'passport', 'required': true},
        {'label': 'Visa', 'key': 'visa', 'required': true},
        {'label': 'Arrival Stamp', 'key': 'arrival_stamp', 'required': true},
        {'label': 'C-Form', 'key': 'c_form', 'required': true},
        {'label': 'E-FRRO', 'key': 'efrro', 'required': true},
        {'label': 'University ID', 'key': 'university_id', 'required': false},
      ];
    } else {
      return [
        {'label': 'Passport Size Photo', 'key': 'passport_photo', 'required': true},
        {'label': 'Tenant Aadhaar Card', 'key': 'tenant_aadhaar', 'required': true},
        {'label': 'Parent Aadhaar Card', 'key': 'parent_aadhaar', 'required': true},
        {'label': 'University ID', 'key': 'university_id', 'required': false},
      ];
    }
  }

  void _openDrawer() {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    state?.openDrawer();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await _loadDocuments();
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarHelper.showSuccess(context, 'Documents refreshed');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSelectionMode) {
      setState(() => _selectedIndices.clear());
      return false;
    }
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            title: const Text('Exit App?', style: TextStyle(color: Colors.white)),
            content: Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kLivinkeyGreen, Color(0xFF7CB342)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Text('Exit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<Map<String, dynamic>> get _docs {
    if (_requiredDocuments.isNotEmpty) {
      return _requiredDocuments;
    }
    return _getFallbackDocuments(_residency);
  }

  bool _hasDocument(String key) {
    return _uploadedDocuments.any((doc) => doc['document_type'] == key);
  }

  Map<String, dynamic>? _getDocument(String key) {
    try {
      return _uploadedDocuments.firstWhere((doc) => doc['document_type'] == key);
    } catch (e) {
      return null;
    }
  }

  void _toggleSelection(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _handleCardTap(int index) {
    final doc = _docs[index];
    final key = doc['key'];
    final uploaded = _getDocument(key);
    
    if (_isSelectionMode) {
      _toggleSelection(index);
    } else {
      if (uploaded != null) {
        _showDocumentPreview(uploaded);
      } else {
        _showUploadDialog(doc);
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _docs.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices
          ..clear()
          ..addAll(List.generate(_docs.length, (i) => i));
      }
    });
    HapticFeedback.selectionClick();
  }

  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }

  Future<void> _showUploadDialog(Map<String, dynamic> doc) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_rounded, color: kLivinkeyGreen),
              ),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: kLivinkeyGreen),
              ),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to open camera/gallery');
      }
      return;
    }

    if (pickedFile == null || !mounted) return;

    setState(() => _isUploading = true);

    try {
      String fileData;
      
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        fileData = 'data:image/jpeg;base64,$base64Image';
      } else {
        fileData = pickedFile.path;
      }

      final response = await _api.uploadDocument(
        documentType: doc['key'],
        filePath: fileData,
      );

      if (!mounted) {
        setState(() => _isUploading = false);
        return;
      }

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, '${doc['label']} uploaded successfully!');
        await _loadDocuments();
      } else {
        final errorMsg = response['message'] ?? 'Upload failed. Please try again.';
        SnackbarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      String errorMsg = 'An error occurred. Please try again.';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network')) {
        errorMsg = 'Network error. Please check your connection.';
      } else if (e.toString().contains('400')) {
        errorMsg = 'Invalid document type or file format.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMsg = 'Authentication failed. Please login again.';
      } else if (e.toString().contains('413')) {
        errorMsg = 'File too large. Please use a smaller image.';
      }
      
      if (mounted) {
        SnackbarHelper.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showDocumentPreview(Map<String, dynamic> doc) {
    final docType = doc['document_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Document';
    final docUrl = doc['document_url'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      docType,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kLivinkeyGreen.withOpacity(0.12), Colors.white.withOpacity(0.02)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLivinkeyGreen.withOpacity(0.14)),
                ),
                child: docUrl != null && docUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          docUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '📄',
                                    style: TextStyle(fontSize: 60, color: kLivinkeyGreen.withOpacity(0.4)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Preview not available',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '📄',
                              style: TextStyle(fontSize: 60, color: kLivinkeyGreen.withOpacity(0.4)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No document URL',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kLivinkeyGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kLivinkeyGreen.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_rounded, color: kLivinkeyGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'View Only - Already Uploaded',
                      style: TextStyle(color: kLivinkeyGreen, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (docUrl != null && docUrl.isNotEmpty) {
                          // Open URL in browser
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLivinkeyGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text('Download', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadAll() async {
    if (_isDownloadingAll || _uploadedDocuments.isEmpty) return;
    setState(() => _isDownloadingAll = true);
    try {
      for (final doc in _uploadedDocuments) {
        final url = doc['document_url'];
        if (url != null && url.isNotEmpty) {
          // Open in browser
        }
      }
      SnackbarHelper.show(context, 'Downloading all documents...');
    } finally {
      if (mounted) setState(() => _isDownloadingAll = false);
    }
  }

  Future<void> _handleDownloadSelected() async {
    if (_isDownloadingSelected || _selectedIndices.isEmpty) return;
    setState(() => _isDownloadingSelected = true);
    try {
      final count = _selectedIndices.length;
      SnackbarHelper.show(context, 'Downloading $count selected documents...');
      _clearSelection();
    } finally {
      if (mounted) setState(() => _isDownloadingSelected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    const double navBarClearance = 96.0;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading documents...',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isUploading) {
      return Scaffold(
        backgroundColor: kLivinkeyBlack,
        body: Stack(
          children: [
            _buildMainContent(bottomSafeArea, navBarClearance),
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kLivinkeyGreen),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading document...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kLivinkeyBlack,
        appBar: AppBar(
          backgroundColor: kLivinkeyBlack,
          elevation: 0,
          leading: _isSelectionMode
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                  onPressed: _clearSelection,
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                  onPressed: _openDrawer,
                ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSelectionMode
                ? Text('${_selectedIndices.length} selected', key: const ValueKey('selection-title'))
                : const Text('Documents', key: ValueKey('default-title')),
          ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: Icon(
                  _selectedIndices.length == _docs.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: _toggleSelectAll,
              ),
            if (!_isSelectionMode)
              IconButton(
                icon: Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: () {
                  final missingDocs = _docs.where((d) => !_hasDocument(d['key'])).toList();
                  if (missingDocs.isNotEmpty) {
                    _showUploadDialog(missingDocs.first);
                  } else {
                    SnackbarHelper.showInfo(context, 'All documents are uploaded!');
                  }
                },
              ),
          ],
        ),
        body: _buildMainContent(bottomSafeArea, navBarClearance),
      ),
    );
  }

  Widget _buildMainContent(double bottomSafeArea, double navBarClearance) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: kLivinkeyGreen,
      backgroundColor: kLivinkeyBlack,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kLivinkeyGreen.withOpacity(0.05), kLivinkeyBlack, kLivinkeyBlack],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + navBarClearance + bottomSafeArea + 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _residency == 'international' 
                              ? Colors.purple.withOpacity(0.15) 
                              : Colors.blue.withOpacity(0.15),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _residency == 'international' 
                            ? Colors.purple.withOpacity(0.2) 
                            : Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _residency == 'international' 
                              ? Icons.public_rounded 
                              : Icons.flag_rounded,
                          color: _residency == 'international' 
                              ? Colors.purple.withOpacity(0.8) 
                              : Colors.blue.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _residency == 'international' 
                              ? 'International Tenant' 
                              : 'National Tenant (Indian)',
                          style: TextStyle(
                            color: _residency == 'international' 
                                ? Colors.purple.withOpacity(0.9) 
                                : Colors.blue.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kLivinkeyGreen.withOpacity(0.08), Colors.white.withOpacity(0.02)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kLivinkeyGreen.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kLivinkeyGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: kLivinkeyGreen.withOpacity(0.85),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSelectionMode
                                ? 'Tap documents to add or remove them from your selection'
                                : 'Tap to upload if missing · Tap to view if uploaded',
                            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: kLivinkeyGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Documents',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        '${_uploadedDocuments.length}/${_docs.length} uploaded',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      double childAspectRatio = constraints.maxWidth > 600 ? 0.72 : 0.75;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _docs.length,
                        itemBuilder: (context, index) {
                          final doc = _docs[index];
                          final key = doc['key'];
                          final hasDocument = _hasDocument(key);
                          final uploadedDoc = _getDocument(key);
                          final bool isSelected = _selectedIndices.contains(index);
                          final isRequired = doc['required'] ?? true;

                          return _SelectableDocument(
                            isSelected: isSelected,
                            isSelectionMode: _isSelectionMode,
                            onLongPress: () => _toggleSelection(index),
                            child: _buildDocumentCard(doc, hasDocument, uploadedDoc, index, isRequired),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    Map<String, dynamic> doc, 
    bool hasDocument, 
    Map<String, dynamic>? uploadedDoc, 
    int index, 
    bool isRequired
  ) {
    final label = doc['label'] ?? doc['key'] ?? 'Document';
    final icon = _getIconForType(doc['key']);

    return InkWell(
      onTap: () => _handleCardTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hasDocument ? kLivinkeyGreen.withOpacity(0.08) : Colors.white.withOpacity(0.04),
              hasDocument ? kLivinkeyGreen.withOpacity(0.02) : Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDocument ? kLivinkeyGreen.withOpacity(0.3) : Colors.white.withOpacity(0.08),
            width: hasDocument ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: hasDocument ? kLivinkeyGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: hasDocument ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: hasDocument ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasDocument ? kLivinkeyGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasDocument ? '✓ Uploaded' : 'Missing',
                      style: TextStyle(
                        color: hasDocument ? kLivinkeyGreen : Colors.white.withOpacity(0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isRequired && !hasDocument)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.7),
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getIconForType(String? type) {
    switch (type) {
      case 'passport_photo':
        return '📸';
      case 'passport':
        return '📖';
      case 'visa':
        return '🛂';
      case 'arrival_stamp':
        return '📌';
      case 'c_form':
        return '📋';
      case 'efrro':
        return '📄';
      case 'university_id':
        return '🎓';
      case 'tenant_aadhaar':
      case 'parent_aadhaar':
        return '🪪';
      default:
        return '📄';
    }
  }
}

class _SelectableDocument extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;

  const _SelectableDocument({
    required this.child,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            scale: isSelectionMode && !isSelected ? 0.94 : 1.0,
            child: child,
          ),
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: kLivinkeyGreen.withOpacity(0.16),
                    border: Border.all(color: kLivinkeyGreen, width: 2),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: isSelected ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kLivinkeyGreen,
                  border: Border.all(color: kLivinkeyBlack, width: 1.5),
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}