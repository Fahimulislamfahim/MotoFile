import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OCRService {
  final _textRecognizer = TextRecognizer();

  Future<Map<String, DateTime?>> scanDocument(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    DateTime? issueDate;
    DateTime? expiryDate;

    // Simple regex for date matching (YYYY-MM-DD or DD/MM/YYYY or similar)
    // This is a basic implementation and can be improved with more specific regex for different doc types
    final datePattern = RegExp(r'\d{2,4}[-/]\d{1,2}[-/]\d{2,4}');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text;
        
        // Try to find dates
        final matches = datePattern.allMatches(text);
        for (final match in matches) {
          final dateStr = text.substring(match.start, match.end);
          final date = _parseDate(dateStr);
          if (date != null) {
            // Heuristic: Expiry date is usually in the future, Issue date in the past
            if (date.isAfter(DateTime.now())) {
              expiryDate = date;
            } else {
              issueDate = date;
            }
          }
        }
      }
    }

    return {
      'issueDate': issueDate,
      'expiryDate': expiryDate,
    };
  }

  DateTime? _parseDate(String dateStr) {
    List<String> formats = [
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd',
      'dd MMM yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
