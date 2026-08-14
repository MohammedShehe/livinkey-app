// lib/screens/tenant/documents_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/tenant/document_card.dart';
import '../../widgets/common/snackbar_helper.dart';
import '../../widgets/common/loading_indicator.dart';
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
  bool _isInternational = false;
  bool _isRefreshing = false;

  // ---- Selection state -----------------------------------------------
  final Set<int> _selectedIndices = {};
  bool get _isSelectionMode => _selectedIndices.isNotEmpty;

  // ---- Download / loading state ---------------------------------------
  bool _isDownloadingAll = false;
  bool _isDownloadingSelected = false;

  final List<Map<String, String>> _internationalDocs = [
    {'label': 'Passport Size Photo', 'icon': '📸'},
    {'label': 'Passport Photo', 'icon': '📖'},
    {'label': 'Visa Photo', 'icon': '🛂'},
    {'label': 'Arrival Stamp Photo', 'icon': '📌'},
    {'label': 'C-Form Photo', 'icon': '📋'},
    {'label': 'e-FRRO', 'icon': '📄'},
    {'label': 'University ID Photo', 'icon': '🎓'},
  ];

  final List<Map<String, String>> _nationalDocs = [
    {'label': 'Passport Size Photo', 'icon': '📸'},
    {'label': 'Tenant Aadhar Card Photo', 'icon': '🪪'},
    {'label': 'Parent Aadhar Card Photo', 'icon': '🪪'},
    {'label': 'University ID Photo', 'icon': '🎓'},
  ];

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Helper method to open drawer using the parent state
  void _openDrawer() {
    final state = context.findAncestorStateOfType<TenantScreenState>();
    if (state != null) {
      state.openDrawer();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
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
              side: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            title: const Text(
              'Exit App?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kLivinkeyGreen, Color(0xFF7CB342)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kLivinkeyGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<Map<String, String>> get _docs => _isInternational ? _internationalDocs : _nationalDocs;

  // ---- Selection helpers ------------------------------------------------

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
    if (_isSelectionMode) {
      _toggleSelection(index);
    } else {
      _showDocumentPreview(_docs[index]['label']!);
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

  // ---- Download actions --------------------------------------------------

  Future<void> _handleDownloadAll() async {
    if (_isDownloadingAll) return;
    setState(() => _isDownloadingAll = true);
    try {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      SnackbarHelper.show(context, 'Downloading all documents...');
    } finally {
      if (mounted) setState(() => _isDownloadingAll = false);
    }
  }

  Future<void> _handleDownloadSelected() async {
    if (_isDownloadingSelected) return;
    final int count = _selectedIndices.length;
    setState(() => _isDownloadingSelected = true);
    try {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Downloading $count selected document${count == 1 ? '' : 's'}...',
      );
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: kLivinkeyBlack,
        appBar: AppBar(
          backgroundColor: kLivinkeyBlack,
          elevation: 0,
          scrolledUnderElevation: 0,
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
                ? Text(
                    '${_selectedIndices.length} selected',
                    key: const ValueKey('selection-title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  )
                : const Text(
                    'Documents',
                    key: ValueKey('default-title'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                tooltip: _selectedIndices.length == _docs.length
                    ? 'Deselect all'
                    : 'Select all',
                icon: Icon(
                  _selectedIndices.length == _docs.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: _toggleSelectAll,
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _isInternational ? 'International' : 'National',
                    dropdownColor: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'International',
                        child: Text('🌍 International'),
                      ),
                      DropdownMenuItem(
                        value: 'National',
                        child: Text('🇮🇳 National'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isInternational = value == 'International';
                        _selectedIndices.clear();
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: kLivinkeyGreen,
          backgroundColor: kLivinkeyBlack,
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kLivinkeyGreen.withOpacity(0.05),
                      kLivinkeyBlack,
                      kLivinkeyBlack,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        32 + navBarClearance + bottomSafeArea + 72,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  kLivinkeyGreen.withOpacity(0.08),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: kLivinkeyGreen.withOpacity(0.12),
                                width: 1,
                              ),
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
                                        : 'Tap to view a document · Hold to select multiple',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          _buildSectionHeader('My Documents'),
                          const SizedBox(height: 14),

                          // Responsive Grid - adapts to screen size with better card fitting
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Determine crossAxisCount based on available width
                              int crossAxisCount = 2;
                              double childAspectRatio = 0.75;
                              double crossAxisSpacing = 12;
                              double mainAxisSpacing = 12;
                              
                              if (constraints.maxWidth > 600) {
                                crossAxisCount = 3;
                                childAspectRatio = 0.72;
                                crossAxisSpacing = 14;
                                mainAxisSpacing = 14;
                              }
                              if (constraints.maxWidth > 900) {
                                crossAxisCount = 4;
                                childAspectRatio = 0.70;
                                crossAxisSpacing = 16;
                                mainAxisSpacing = 16;
                              }
                              if (constraints.maxWidth < 380) {
                                crossAxisCount = 2;
                                childAspectRatio = 0.82;
                                crossAxisSpacing = 10;
                                mainAxisSpacing = 10;
                              }
                              
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: crossAxisSpacing,
                                  mainAxisSpacing: mainAxisSpacing,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: _docs.length,
                                itemBuilder: (context, index) {
                                  final hasPhoto = DateTime.now().millisecondsSinceEpoch % 3 != 0;
                                  final bool isSelected = _selectedIndices.contains(index);

                                  return _SelectableDocument(
                                    isSelected: isSelected,
                                    isSelectionMode: _isSelectionMode,
                                    onLongPress: () => _toggleSelection(index),
                                    child: DocumentCard(
                                      doc: _docs[index],
                                      hasPhoto: hasPhoto,
                                      onTap: () => _handleCardTap(index),
                                    ),
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

              // ---- Pinned action bar --------------------------------------
              Positioned(
                left: 20,
                right: 20,
                bottom: navBarClearance + bottomSafeArea - 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _isSelectionMode
                      ? _buildSelectionBar(key: const ValueKey('selection-bar'))
                      : _buildDefaultBar(key: const ValueKey('default-bar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bar shown normally (no selection active)
  Widget _buildDefaultBar({Key? key}) {
    return _FloatingBarShell(
      key: key,
      child: ElevatedButton(
        onPressed: _isDownloadingAll ? null : _handleDownloadAll,
        style: ElevatedButton.styleFrom(
          backgroundColor: kLivinkeyGreen,
          disabledBackgroundColor: kLivinkeyGreen.withOpacity(0.6),
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: _isDownloadingAll
              ? const SizedBox(
                  key: ValueKey('spinner'),
                  height: 20,
                  width: 20,
                  child: LoadingIndicator(size: 20, color: Colors.black),
                )
              : const Row(
                  key: ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Download All',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Bar shown while one or more documents are selected
  Widget _buildSelectionBar({Key? key}) {
    return _FloatingBarShell(
      key: key,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isDownloadingSelected ? null : _clearSelection,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: kLivinkeyGreen.withOpacity(0.3),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isDownloadingSelected ? null : _handleDownloadSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: kLivinkeyGreen,
                disabledBackgroundColor: kLivinkeyGreen.withOpacity(0.6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _isDownloadingSelected
                    ? const SizedBox(
                        key: ValueKey('spinner'),
                        height: 20,
                        width: 20,
                        child: LoadingIndicator(size: 20, color: Colors.black),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Download (${_selectedIndices.length})',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
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

  Widget _buildSectionHeader(String title) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  void _showDocumentPreview(String label) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isDownloading = false;

          Future<void> handleDownload() async {
            if (isDownloading) return;
            setDialogState(() => isDownloading = true);
            await Future.delayed(const Duration(milliseconds: 1200));
            if (!context.mounted) return;
            SnackbarHelper.show(context, 'Document downloaded');
            setDialogState(() => isDownloading = false);
          }

          return Dialog(
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
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 18,
                          ),
                        ),
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
                        colors: [
                          kLivinkeyGreen.withOpacity(0.12),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kLivinkeyGreen.withOpacity(0.14),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '📄',
                        style: TextStyle(
                          fontSize: 60,
                          color: kLivinkeyGreen.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDownloading ? null : handleDownload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLivinkeyGreen,
                            disabledBackgroundColor: kLivinkeyGreen.withOpacity(0.6),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: isDownloading
                                ? const SizedBox(
                                    key: ValueKey('spinner'),
                                    height: 20,
                                    width: 20,
                                    child: LoadingIndicator(size: 20, color: Colors.black),
                                  )
                                : const Row(
                                    key: ValueKey('label'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.download_rounded, color: Colors.black, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Download',
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Frosted-glass shell for the pinned bottom bar
class _FloatingBarShell extends StatelessWidget {
  final Widget child;

  const _FloatingBarShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps a DocumentCard with long-press-to-select behavior
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
      behavior: HitTestBehavior.opaque,
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
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}