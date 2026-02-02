import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';
import '../../data/database_helper.dart';
import '../../data/models/document_model.dart';
import '../widgets/dashboard_card.dart';
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
  String _filter = 'All'; // All, Expiring Soon, Expired, Missing

  final List<String> _defaultTypes = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance'
  ];

  List<String> _displayTypes = [];

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
    _searchController.addListener(_filterDocuments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    
    // 1. Get all unique types from DB + Defaults
    final dbTypes = _documents.map((d) => d.docType).toSet();
    final allTypes = {..._defaultTypes, ...dbTypes}.toList();
    
    setState(() {
      _displayTypes = allTypes.where((type) {
        // Search Filter
        if (query.isNotEmpty && !type.toLowerCase().contains(query)) {
          return false;
        }

        // Status Filter
        if (_filter == 'All') return true;
        
        final doc = _getDocumentForType(type);
        if (_filter == 'Missing') return doc.status == 'Missing';
        if (_filter == 'Expired') return doc.status == 'Expired';
        if (_filter == 'Expiring Soon') return doc.status == 'Expiring';
        
        return true;
      }).toList();
    });
  }

  Document _getDocumentForType(String type) {
    return _documents.firstWhere(
      (d) => d.docType == type,
      orElse: () => Document(
        docType: type,
        filePath: '',
        issueDate: '-',
        expiryDate: '-',
        status: 'Missing',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoFile Dashboard'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeService.toggleTheme();
            },
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
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayTypes.isEmpty
                    ? Center(child: Text('No documents found', style: TextStyle(color: Colors.grey[400])))
                    : Padding(
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

                            return DashboardCard(
                              title: title,
                              expiryDate: doc.expiryDate,
                              status: doc.status,
                              onTap: () {
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
                              },
                            );
                          },
                        ),
                      ),
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
