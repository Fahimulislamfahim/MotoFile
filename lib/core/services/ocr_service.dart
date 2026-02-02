import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class OCRService {
  final _textRecognizer = TextRecognizer();

  Future<Map<String, dynamic>> scanPdf(File pdfFile) async {
    StringBuffer debugLogs = StringBuffer();
    debugLogs.writeln("Starting scanPdf for: ${pdfFile.path}");
    
    try {
      if (!await pdfFile.exists()) {
        debugLogs.writeln("ERROR: PDF file does not exist at path.");
        return {'rawText': debugLogs.toString(), 'issueDate': null, 'expiryDate': null};
      }
      
      final pdfBytes = await pdfFile.readAsBytes();
      debugLogs.writeln("PDF Bytes read: ${pdfBytes.length}");
      
      if (pdfBytes.isEmpty) {
        debugLogs.writeln("ERROR: PDF file is empty.");
        return {'rawText': debugLogs.toString(), 'issueDate': null, 'expiryDate': null};
      }

      int pageCount = 0;
      
      // Render the first page of the PDF to an image
      debugLogs.writeln("Attempting to rasterize PDF (dpi: 200)...");
      
      // Reduce DPI slightly to 200 to be safe on memory, 300 might be too high for some devices
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
         pageCount++;
         final imageBytes = await page.toPng();
         debugLogs.writeln("Page rasterized. Image bytes: ${imageBytes.length}");
         
         if (imageBytes.isEmpty) {
            debugLogs.writeln("ERROR: Rendered image is empty.");
            continue;
         }
         
         // Save to temp file
         final tempDir = Directory.systemTemp;
         final tempFile = File('${tempDir.path}/temp_pdf_page.png');
         await tempFile.writeAsBytes(imageBytes);
         debugLogs.writeln("Saved temp image to: ${tempFile.path}");
         
         // Use existing scan logic
         debugLogs.writeln("Starting OCR on temp image...");
         final results = await scanDocument(tempFile);
         
         debugLogs.writeln("OCR Completed.");
         debugLogs.writeln("Raw Text: ${results['rawText']}");
         
         // Cleanup
         await tempFile.delete();
         
         // Return results combined with debug logs
         results['rawText'] = "DEBUG LOG:\n$debugLogs\n\nOCR OUTPUT:\n${results['rawText']}";
         return results;
      }
      
      if (pageCount == 0) {
        debugLogs.writeln("ERROR: Printing.raster returned no pages. Is the PDF valid?");
      }

    } catch (e, stack) {
      debugLogs.writeln("EXCEPTION: $e");
      debugLogs.writeln("STACK: $stack");
      print('Error scanning PDF: $e');
    }
    
    return {
      'issueDate': null, 
      'expiryDate': null, 
      'rawText': debugLogs.toString()
    };
  }

  DateTime? _parseDate(String dateStr) {
    // Clean string: remove non-date characters from ends, normalize separators
    dateStr = dateStr.trim().replaceAll(RegExp(r'[.,]$'), '');
    String normalize(String s) => s.replaceAll('.', '-').replaceAll('/', '-').replaceAll('\\', '-').replaceAll(' ', '-');
    
    final cleanStr = normalize(dateStr);
    
    List<String> formats = [
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'yyyy-MM-dd',
      'dd-MMM-yyyy',
      'd-MMM-yyyy',
      'dd-MMM-yy',
      'd-MMM-yy',
      'dd MMM yyyy', 
      'd MMM yyyy',
      'dd-MM-yy',
    ];

    for (final format in formats) {
      try {
        final d = DateFormat(format).parse(cleanStr);
        // Sanity check: year should be reasonable (e.g. within last 50 years or next 50 years)
        // Fix 2-digit years if needed (e.g. 24 -> 2024)
        int year = d.year;
        if (year < 100) year += 2000; 
        
        final corrected = DateTime(year, d.month, d.day);
        if (year > 1970 && year < 2100) return corrected;
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>> scanDocument(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    DateTime? issueDate;
    DateTime? expiryDate;
    
    // Debug: print all text
    print("OCR Text detected: ${recognizedText.text}");

    // 1. Collect and Sort Lines by Y-coordinate (Top to Bottom)
    List<TextLine> allLines = [];
    for (var block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    
    // Sort logic: Sort by Top, with a small tolerance for same-line items
    allLines.sort((a, b) {
      final diff = a.boundingBox.top - b.boundingBox.top;
      if (diff.abs() < 10) { // 10px tolerance for same line
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return diff.compareTo(0);
    });

    List<String> sortedTextLines = allLines.map((e) => e.text).toList();
    print("Sorted OCR Lines: $sortedTextLines");

    // Regex to find dates: matches things like 12/12/2022, 12-Dec-2022, 2022.12.12, 12 12 2024
    final datePattern = RegExp(r'(?:\d{1,2}[-/\. ]\d{1,2}[-/\. ]\d{2,4})|(?:\d{1,2}[-/\. ][A-Za-z]{3}[-/\. ]\d{2,4})|(?:\d{4}[-/\. ]\d{1,2}[-/\. ]\d{1,2})');
    
    // Find all potential dates with their line index
    List<Map<String, dynamic>> foundDates = [];
    
    for (int i = 0; i < sortedTextLines.length; i++) {
        final text = sortedTextLines[i];
        final matches = datePattern.allMatches(text);
        for (final match in matches) {
          final dateStr = text.substring(match.start, match.end);
          final date = _parseDate(dateStr);
          if (date != null) {
            foundDates.add({
              'date': date,
              'lineIndex': i,
              'raw': dateStr
            });
          }
        }
    }
    
    print("Found dates: $foundDates");

    // Strategy 1: Look for keywords on the SAME line or PREVIOUS/NEXT lines
    // Keywords for Expiry: "exp", "valid", "until", "to"
    // Keywords for Issue: "issue", "reg", "from", "start"
    
    for (var dateEntry in foundDates) {
      DateTime date = dateEntry['date'];
      int lineIdx = dateEntry['lineIndex'];
      
      // Check context (current line, prev, next)
      // Expanded context to 2 lines up/down due to potential layout spacing
      String contextText = "";
      for (int offset = -2; offset <= 2; offset++) {
        int idx = lineIdx + offset;
        if (idx >= 0 && idx < sortedTextLines.length) {
          contextText += "${sortedTextLines[idx]} ";
        }
      }
      
      contextText = contextText.toLowerCase();

      if (contextText.contains('exp') || contextText.contains('valid') || contextText.contains('until') || contextText.contains('bad')) {
        if (expiryDate == null) expiryDate = date;
      } else if (contextText.contains('issue') || contextText.contains('reg') || contextText.contains('start') || contextText.contains('from') || contextText.contains('w.e.f')) {
        if (issueDate == null) issueDate = date;
      }
    }
    
    // Strategy 2: Heuristics if still null (dates without readable keywords close by)
    if (issueDate == null || expiryDate == null) {
      for (var dateEntry in foundDates) {
        DateTime date = dateEntry['date'];
        
        // Skip if already used
        if (date == issueDate || date == expiryDate) continue;
        
        if (expiryDate == null && date.isAfter(DateTime.now().add(const Duration(days: 30)))) {
           expiryDate = date;
        } else if (issueDate == null && date.isBefore(DateTime.now())) {
           issueDate = date;
        }
      }
    }

    // Final conflict resolution
    if (issueDate != null && expiryDate != null && issueDate.isAfter(expiryDate)) {
       final temp = issueDate;
       issueDate = expiryDate;
       expiryDate = temp;
    }

    return {
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'rawText': recognizedText.text, // Return raw text for debugging
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}
