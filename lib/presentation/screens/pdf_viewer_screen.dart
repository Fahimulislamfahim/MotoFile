import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<File>(
        future: File(filePath).exists().then((exists) => exists ? File(filePath) : throw Exception('File not found')),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          } else {
             return PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              onError: (error) {
                // Handle error
              },
              onPageError: (page, error) {
                // Handle page error
              },
            );
          }
        },
      ),
    );
  }
}
