import 'dart:ui' as UI;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme_service.dart';
import '../../core/services/card_order_service.dart';
import '../../core/services/view_mode_service.dart';
import '../../data/daos/document_dao.dart';
import '../../data/models/document_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/document_card_view.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_drawer.dart';
import 'add_document_screen.dart';
import 'pdf_viewer_screen.dart';
import 'garage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _documentDao = DocumentDao();
  List<Document> _documents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // ... rest of variables

  String _filter = 'All';
  final CardOrderService _cardOrderService = CardOrderService();
  final ViewModeService _viewModeService = ViewModeService();

  final List<String> _defaultTypes = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance'
  ];

  List<String> _displayTypes = [];
  List<String> _savedOrder = [];
  ViewMode _viewMode = ViewMode.grid;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCardOrder();
    _loadViewMode();
    _refreshDocuments();
    _searchController.addListener(_filterDocuments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ... _loadCardOrder, _loadViewMode, _saveCardOrder, _changeViewMode ...

  Future<void> _loadCardOrder() async {
    final order = await _cardOrderService.getCardOrder();
    setState(() {
      _savedOrder = order;
    });
  }

  Future<void> _loadViewMode() async {
    final mode = await _viewModeService.getViewMode();
    setState(() {
      _viewMode = mode;
    });
  }

  Future<void> _saveCardOrder() async {
    await _cardOrderService.saveCardOrder(_displayTypes);
    setState(() {
      _savedOrder = List.from(_displayTypes);
    });
  }

  Future<void> _changeViewMode(ViewMode mode) async {
    await _viewModeService.saveViewMode(mode);
    setState(() {
      _viewMode = mode;
    });
  }

  Future<void> _refreshDocuments() async {
    setState(() => _isLoading = true);
    final data = await _documentDao.readAll();
    setState(() {
      _documents = data;
      _isLoading = false;
    });
    _filterDocuments();
  }

  void _filterDocuments() {
    final query = _searchController.text.toLowerCase();
    
    final dbTypes = _documents.map((d) => d.docType).toSet();
    final allTypes = {..._defaultTypes, ...dbTypes}.toList();
    
    final filteredTypes = allTypes.where((type) {
      if (query.isNotEmpty && !type.toLowerCase().contains(query)) {
        return false;
      }

      if (_filter == 'All') return true;
      
      final doc = _getDocumentForType(type);
      if (_filter == 'Missing') return doc.status == 'Missing';
      if (_filter == 'Expired') return doc.status == 'Expired';
      if (_filter == 'Expiring Soon') return doc.status == 'Expiring';
      
      return true;
    }).toList();

    final sortedTypes = _cardOrderService.sortByOrder(filteredTypes, _savedOrder);
    
    setState(() {
      _displayTypes = sortedTypes;
    });
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  Document _getDocumentForType(String type) {
    return _documents.firstWhere(
      (d) => d.docType == type,
      orElse: () => Document(
        docType: type,
        filePath: '',
        issueDate: null,
        expiryDate: null,
        status: 'Missing',
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _displayTypes.removeAt(oldIndex);
      _displayTypes.insert(newIndex, item);
    });
    
    _saveCardOrder();
     // Optional: Feedback (removed SnackBar to reduce clutter, or keep it subtle)
  }

  void _navigateToDocument(String title) {
    final doc = _getDocumentForType(title);
    if (doc.status == 'Missing') {
      _navigateToAddDocument(title);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            filePath: doc.filePath,
            title: title,
            documentId: doc.id!,
          ),
        ),
      ).then((value) {
        if (value == true) _refreshDocuments();
      });
    }
  }

  Future<void> _navigateToAddDocument(String? preselectedType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentScreen(preselectedType: preselectedType),
      ),
    );

    if (result == true) {
      _refreshDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine title based on tab
    final title = _currentIndex == 0 ? 'MotoFile' : 'My Garage';

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Important for PremiumBackground
        drawer: const AppDrawer(),
        extendBody: true, // For glass bottom nav
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          actions: _currentIndex == 0 ? [
            // View Mode Menu
             PopupMenuButton<ViewMode>(
                icon: const Icon(Icons.grid_view_rounded),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: _changeViewMode,
                itemBuilder: (context) => [
                  PopupMenuItem(value: ViewMode.grid, child: _buildMenuItem(Icons.grid_view, 'Grid View', _viewMode == ViewMode.grid)),
                  PopupMenuItem(value: ViewMode.list, child: _buildMenuItem(Icons.view_list, 'List View', _viewMode == ViewMode.list)),
                  PopupMenuItem(value: ViewMode.card, child: _buildMenuItem(Icons.view_agenda, 'Card View', _viewMode == ViewMode.card)),
                ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshDocuments,
            ),
            const SizedBox(width: 8),
          ] : [],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _currentIndex == 0 
            ? KeyedSubtree(key: const ValueKey('Dashboard'), child: _buildDashboardContent())
            : const KeyedSubtree(key: const ValueKey('Garage'), child: GarageScreen()),
        ),
        
        floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
          onPressed: () => _navigateToAddDocument(null),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 10,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ).animate().scale(delay: 500.ms) : null,
        
        bottomNavigationBar: _buildGlassBottomNav(),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, bool isSelected) {
    return Row(
      children: [
        Icon(icon, color: isSelected ? AppColors.primaryLight : Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryLight : null
        )),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        // Search & Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical padding slightly for better centering
                borderRadius: 40,
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),
              
              const SizedBox(height: 16),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: ['All', 'Expiring Soon', 'Expired', 'Missing'].map((filter) {
                    final isSelected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                           setState(() {
                            _filter = filter;
                            _filterDocuments();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : Theme.of(context).cardColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : Colors.transparent
                            ),
                            boxShadow: isSelected ? [
                               BoxShadow(color: AppColors.primaryLight.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)
                            ] : [],
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayTypes.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No documents found', style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16)),
                      ],
                    ))
                  : ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                          stops: [0.0, 0.05, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: _buildDocumentView(),
                    ),
        ),
        const SizedBox(height: 80), // Space for Bubble Bottom Nav
      ],
    );
  }

  Widget _buildDocumentView() {
    // Add extra padding at bottom for FAB and Nav
    const bottomPadding = EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 8);

    switch (_viewMode) {
      case ViewMode.grid:
        return GridView.builder(
          padding: bottomPadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82, 
          ),
          itemCount: _displayTypes.length,
          itemBuilder: (context, index) {
             final title = _displayTypes[index];
             final doc = _getDocumentForType(title);
             return LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.05,
                  child: SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    child: DashboardCard(
                      title: title,
                      expiryDate: doc.expiryDate,
                      status: doc.status,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: DashboardCard(title: title, expiryDate: doc.expiryDate, status: doc.status, onTap: () {})),
              child: DragTarget<int>(
                onAcceptWithDetails: (details) => _onReorder(details.data, index),
                builder: (context, cand, rej) => DashboardCard(
                  key: ValueKey(title),
                  title: title,
                  expiryDate: doc.expiryDate,
                  status: doc.status,
                  onTap: () => _navigateToDocument(title),
                ),
              ),
             );
          },
        );
      case ViewMode.list:
        return ReorderableListView.builder(
          padding: bottomPadding,
          itemCount: _displayTypes.length,
          onReorder: _onReorder,
          proxyDecorator: (child, index, animation) => 
            Material(color: Colors.transparent, child: child), // Fix proxy decorator background
          itemBuilder: (context, index) {
            final title = _displayTypes[index];
            final doc = _getDocumentForType(title);
            return DocumentListTile(
              key: ValueKey(title),
              title: title,
              expiryDate: _parseDate(doc.expiryDate),
              status: doc.status,
              onTap: () => _navigateToDocument(title),
            );
          },
        );
      case ViewMode.card:
        return ReorderableListView.builder(
           padding: bottomPadding,
          itemCount: _displayTypes.length,
          onReorder: _onReorder,
           proxyDecorator: (child, index, animation) => 
            Material(color: Colors.transparent, child: child),
          itemBuilder: (context, index) {
            final title = _displayTypes[index];
            final doc = _getDocumentForType(title);
            return DocumentCardView(
              key: ValueKey(title),
              title: title,
              expiryDate: _parseDate(doc.expiryDate),
              status: doc.status,
              onTap: () => _navigateToDocument(title),
            );
          },
        );
    }
  }

  Widget _buildGlassBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.6) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: UI.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavIcon(Icons.grid_view_rounded, 'Dashboard', 0),
              _buildNavIcon(Icons.two_wheeler_rounded, 'Garage', 1),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, delay: 600.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildNavIcon(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? Border.all(color: AppColors.primaryLight.withOpacity(0.3), width: 1) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryLight : const Color(0xFF8E8E93), // iOS grey
                size: 26,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
            ]
          ],
        ),
      ),
    );
  }
}

// Helper for BackdropFilter in Nav (Moved to top)
