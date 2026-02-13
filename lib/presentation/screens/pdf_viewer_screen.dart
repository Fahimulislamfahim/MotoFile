import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:share_plus/share_plus.dart';
import '../../data/daos/document_dao.dart';
import '../../core/services/notification_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final int documentId;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
    required this.documentId,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  // Default to horizontal scrolling (page-by-page) as per original behavior
  // Users can toggle to vertical for continuous scrolling
  bool _isVertical = false;

  Future<void> _deleteDocument(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This will permanently delete the file and cancel all reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Delete from DB
      await DocumentDao().delete(widget.documentId);
      
      // 2. Cancel notifications
      await NotificationService().cancelNotifications(widget.documentId);

      // 3. Delete file (optional, but good practice)
      try {
        final file = File(widget.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      if (context.mounted) {
        Navigator.pop(context, true); // Return true to refresh home
      }
    }
  }

  Future<void> _shareDocument() async {
    final file = File(widget.filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(widget.filePath)], text: 'Here is my ${widget.title} document.');
    }
  }

  void _toggleScrollDirection() {
    setState(() {
      _isVertical = !_isVertical;
    });
    
    // Show a small snackbar to feedback the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isVertical ? 'Switched to Vertical Scrolling' : 'Switched to Horizontal Scrolling'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Scroll direction toggle
          IconButton(
            tooltip: _isVertical ? 'Switch to Horizontal Scroll' : 'Switch to Vertical Scroll',
            icon: Icon(_isVertical ? Icons.swap_vert : Icons.swap_horiz),
            onPressed: _toggleScrollDirection,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteDocument(context),
          ),
        ],
      ),
      body: FutureBuilder<File>(
        future: File(widget.filePath).exists().then((exists) => exists ? File(widget.filePath) : throw Exception('File not found')),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Re-create PDFView when scroll direction changes to force mode switch
            // Adding a key based on direction ensures widget rebuild
            return PDFView(
              key: ValueKey('pdf_view_${_isVertical ? "vert" : "horiz"}'),
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: !_isVertical, // Horizontal if not vertical
              autoSpacing: true, // Auto-spacing is good for both
              pageFling: !_isVertical, // Snap to pages only in horizontal mode
              pageSnap: !_isVertical, // Explicitly control page snapping
              onError: (error) {
                debugPrint(error.toString());
              },
              onPageError: (page, error) {
                debugPrint('$page: ${error.toString()}');
              },
            );
          }
        },
      ),
    );
  }
}
