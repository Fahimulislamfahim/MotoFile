import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';
import '../../core/services/card_order_service.dart';
import '../../core/services/view_mode_service.dart';
import '../../data/database_helper.dart';
import '../../data/models/document_model.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/document_card_view.dart';
import '../widgets/app_drawer.dart';
import 'add_document_screen.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
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
    final data = await DatabaseHelper.instance.readAllDocuments();
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Card order saved'),
        duration: const Duration(seconds: 1),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('MotoFile Dashboard'),
        actions: [
          // View Mode Switcher
          PopupMenuButton<ViewMode>(
            icon: Icon(
              _viewMode == ViewMode.grid
                  ? Icons.grid_view
                  : _viewMode == ViewMode.list
                      ? Icons.view_list
                      : Icons.view_agenda,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: 'Change View',
            onSelected: _changeViewMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ViewMode.grid,
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view,
                      color: _viewMode == ViewMode.grid
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Grid View',
                      style: TextStyle(
                        color: _viewMode == ViewMode.grid
                            ? Theme.of(context).primaryColor
                            : null,
                        fontWeight: _viewMode == ViewMode.grid
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ViewMode.list,
                child: Row(
                  children: [
                    Icon(
                      Icons.view_list,
                      color: _viewMode == ViewMode.list
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'List View',
                      style: TextStyle(
                        color: _viewMode == ViewMode.list
                            ? Theme.of(context).primaryColor
                            : null,
                        fontWeight: _viewMode == ViewMode.list
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ViewMode.card,
                child: Row(
                  children: [
                    Icon(
                      Icons.view_agenda,
                      color: _viewMode == ViewMode.card
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Card View',
                      style: TextStyle(
                        color: _viewMode == ViewMode.card
                            ? Theme.of(context).primaryColor
                            : null,
                        fontWeight: _viewMode == ViewMode.card
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Expiring Soon', 'Expired', 'Missing'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filter = filter;
                        _filterDocuments();
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    checkmarkColor: Theme.of(context).primaryColor,
                    backgroundColor: Theme.of(context).cardColor,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayTypes.isEmpty
                    ? Center(child: Text('No documents found', style: TextStyle(color: Colors.grey[400])))
                    : _buildDocumentView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDocument(null),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDocumentView() {
    switch (_viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.card:
        return _buildCardView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _displayTypes.length,
        itemBuilder: (context, index) {
          final title = _displayTypes[index];
          final doc = _getDocumentForType(title);
          
          return LongPressDraggable<int>(
            data: index,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.8,
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
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: DashboardCard(
                key: ValueKey(title),
                title: title,
                expiryDate: doc.expiryDate,
                status: doc.status,
                onTap: () => _navigateToDocument(title),
              ),
            ),
            child: DragTarget<int>(
              onAcceptWithDetails: (details) {
                _onReorder(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                return DashboardCard(
                  key: ValueKey(title),
                  title: title,
                  expiryDate: doc.expiryDate,
                  status: doc.status,
                  onTap: () => _navigateToDocument(title),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _displayTypes.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.02,
              child: Opacity(
                opacity: 0.9,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
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
  }

  Widget _buildCardView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _displayTypes.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.02,
              child: Opacity(
                opacity: 0.9,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
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
}
