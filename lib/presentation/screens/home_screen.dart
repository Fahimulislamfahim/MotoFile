import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import '../../core/services/card_order_service.dart';
import '../../core/services/view_mode_service.dart';
import '../../data/daos/document_dao.dart';
import '../../data/models/document_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/vehicle_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/document_card_view.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/app_drawer.dart';
import 'add_document_screen.dart';
import 'pdf_viewer_screen.dart';
import 'garage_screen.dart';
import 'add_vehicle_screen.dart';

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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), // Reduced from 24
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
            : const KeyedSubtree(key: ValueKey('Garage'), child: GarageScreen()),
        ),
        
        floatingActionButton: _buildFloatingActionButton(),
        
        bottomNavigationBar: _buildBottomNav(),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0), // Tighter padding
                borderRadius: 32, // Reduced from 40
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
                    contentPadding: EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),
              
              const SizedBox(height: 12), // Reduced from 16
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: ['All', 'Expiring Soon', 'Expired', 'Missing'].map((filter) {
                    final isSelected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8), // Tighter chip spacing
                      child: GestureDetector(
                        onTap: () {
                           setState(() {
                            _filter = filter;
                            _filterDocuments();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // Reudced from 16, 8
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : Theme.of(context).cardColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : Colors.transparent
                            ),
                            boxShadow: isSelected ? [
                               BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)
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
              ? _buildShimmerView()
              : _displayTypes.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No documents found', style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: 16)),
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
            crossAxisSpacing: 12, // Tighter grid
            mainAxisSpacing: 12,
            childAspectRatio: 0.85, // Adjust for tighter cards
          ),
          itemCount: _displayTypes.length,
          itemBuilder: (context, index) {
             final title = _displayTypes[index];
             final doc = _getDocumentForType(title);
             
             return OpenContainer(
               transitionType: ContainerTransitionType.fadeThrough,
               closedElevation: 0,
               openElevation: 0,
               closedColor: Colors.transparent,
               openColor: Theme.of(context).scaffoldBackgroundColor,
               middleColor: Colors.transparent,
               tappable: false,
               transitionDuration: const Duration(milliseconds: 500),
               onClosed: (value) {
                 if (value == true) _refreshDocuments();
               },
               openBuilder: (context, action) {
                 if (doc.status == 'Missing') {
                   return AddDocumentScreen(preselectedType: title);
                 } else {
                   return PDFViewerScreen(
                      filePath: doc.filePath,
                      title: title,
                      documentId: doc.id!,
                   );
                 }
               },
               closedBuilder: (context, action) {
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
                          animationDelay: (index < 10 ? index * 50 : 500).ms,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: DashboardCard(title: title, expiryDate: doc.expiryDate, status: doc.status, onTap: () {})),
                  child: RepaintBoundary(
                    child: DragTarget<int>(
                      onAcceptWithDetails: (details) => _onReorder(details.data, index),
                      builder: (context, cand, rej) => DashboardCard(
                        key: ValueKey(title),
                        title: title,
                        expiryDate: doc.expiryDate,
                        status: doc.status,
                        onTap: action,
                        animationDelay: (index < 10 ? index * 50 : 500).ms,
                      ),
                    ),
                  ),
                 );
               },
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
            
            return RepaintBoundary(
              key: ValueKey(title),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12), // Moved padding here to wrap OpenContainer
                child: OpenContainer(
                   transitionType: ContainerTransitionType.fadeThrough,
                   closedElevation: 0,
                   openElevation: 0,
                   closedColor: Colors.transparent,
                   openColor: Theme.of(context).scaffoldBackgroundColor,
                   middleColor: Colors.transparent,
                   tappable: false, // We control tap
                   transitionDuration: const Duration(milliseconds: 500),
                   onClosed: (value) {
                     if (value == true) _refreshDocuments();
                   },
                   openBuilder: (context, action) {
                     if (doc.status == 'Missing') {
                       return AddDocumentScreen(preselectedType: title);
                     } else {
                       return PDFViewerScreen(
                          filePath: doc.filePath,
                          title: title,
                          documentId: doc.id!,
                       );
                     }
                   },
                   closedBuilder: (context, action) {
                      return DocumentListTile(
                        title: title,
                        expiryDate: _parseDate(doc.expiryDate),
                        status: doc.status,
                        onTap: action,
                        animationDelay: (index < 10 ? index * 50 : 500).ms,
                      );
                   }
                ),
              ),
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
            
            return RepaintBoundary(
              key: ValueKey(title),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OpenContainer(
                   transitionType: ContainerTransitionType.fadeThrough,
                   closedElevation: 0,
                   openElevation: 0,
                   closedColor: Colors.transparent,
                   openColor: Theme.of(context).scaffoldBackgroundColor,
                   middleColor: Colors.transparent,
                   tappable: false,
                   transitionDuration: const Duration(milliseconds: 500),
                   onClosed: (value) {
                     if (value == true) _refreshDocuments();
                   },
                   openBuilder: (context, action) {
                     if (doc.status == 'Missing') {
                       return AddDocumentScreen(preselectedType: title);
                     } else {
                       return PDFViewerScreen(
                          filePath: doc.filePath,
                          title: title,
                          documentId: doc.id!,
                       );
                     }
                   },
                   closedBuilder: (context, action) {
                      return DocumentCardView(
                        title: title,
                        expiryDate: _parseDate(doc.expiryDate),
                        status: doc.status,
                        onTap: action,
                        animationDelay: (index < 10 ? index * 50 : 500).ms,
                      );
                   }
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(left: 32, right: 32, bottom: 24),
      height: 64, // Sleeker height
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               Expanded(
                 child: _NavItem(
                   icon: Icons.grid_view_rounded,
                   label: 'Dashboard',
                   isSelected: _currentIndex == 0,
                   onTap: () => setState(() => _currentIndex = 0),
                 ),
               ),
              Expanded(
                child: _NavItem(
                  icon: Icons.two_wheeler_rounded,
                  label: 'Garage',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuart);
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      // Dashboard FAB
      return FloatingActionButton(
        onPressed: () => _navigateToAddDocument(null),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28), // Reduced from 32
      ).animate(key: const ValueKey('fab_dashboard')).scale(duration: 300.ms, curve: Curves.easeOutBack);
    } else if (_currentIndex == 1) {
      // Garage FAB
      return FloatingActionButton(
        onPressed: () async {
          final value = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditVehicleScreen()),
          );
          if (value == true && mounted) {
             Provider.of<VehicleService>(context, listen: false).loadVehicles();
          }
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.two_wheeler_rounded, size: 24), // Reduced from 28
      ).animate(key: const ValueKey('fab_garage')).scale(duration: 300.ms, curve: Curves.easeOutBack);
    }
    return null;
  }

  Widget _buildShimmerView() {
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
          itemCount: 6,
          itemBuilder: (context, index) => const ShimmerPlaceholder(width: double.infinity, height: double.infinity, borderRadius: 32),
        );
      case ViewMode.list:
        return ListView.builder(
           padding: bottomPadding,
           itemCount: 8,
           itemBuilder: (context, index) => Padding(
             padding: const EdgeInsets.only(bottom: 12),
             child: const ShimmerPlaceholder(width: double.infinity, height: 80, borderRadius: 32),
           ),
        );
      case ViewMode.card:
        return ListView.builder(
           padding: bottomPadding,
           itemCount: 4,
           itemBuilder: (context, index) => Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: const ShimmerPlaceholder(width: double.infinity, height: 220, borderRadius: 32),
           ),
        );
    }
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = AppColors.primaryLight;
    final unselectedColor = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min, // Need it to fill expanded
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => 
                  ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.icon,
                  key: ValueKey<bool>(widget.isSelected),
                  color: widget.isSelected ? selectedColor : unselectedColor,
                  size: 24, // slightly smaller icon
                ),
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.isSelected ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: selectedColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14, // smaller font
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
