import 'package:flutter/material.dart';
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

  final List<String> _requiredDocs = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance'
  ];

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.readAllDocuments();
    setState(() {
      _documents = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoFile Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _requiredDocs.length,
                itemBuilder: (context, index) {
                  final title = _requiredDocs[index];
                  // Find if we have this document
                  final doc = _documents.firstWhere(
                    (d) => d.docType == title,
                    orElse: () => Document(
                      docType: title,
                      filePath: '',
                      issueDate: '-',
                      expiryDate: '-',
                      status: 'Missing',
                    ),
                  );

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
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDocument(null),
        backgroundColor: const Color(0xFF00FFFF),
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
