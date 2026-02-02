import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../../data/database_helper.dart';
import '../../data/models/document_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ocr_service.dart';

class AddDocumentScreen extends StatefulWidget {
  final String? preselectedType;

  const AddDocumentScreen({super.key, this.preselectedType});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  File? _pickedFile;

  final _customTypeController = TextEditingController();
  final List<String> _docTypes = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null && _docTypes.contains(widget.preselectedType)) {
      _selectedType = widget.preselectedType;
    } else {
      _selectedType = _docTypes.first;
    }
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _pickedFile = file;
      });

      // Auto-scan PDF
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Scanning PDF for dates...',
                   style: TextStyle(
                     color: Theme.of(context).textTheme.bodyLarge?.color,
                     fontWeight: FontWeight.w500
                   )
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we extract info.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12
                  )
                ),
              ],
            ),
          ),
        );
      }

      try {
        final ocrService = OCRService();
        final results = await ocrService.scanPdf(file);
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          setState(() {
            if (results['issueDate'] != null) _issueDate = results['issueDate'];
            if (results['expiryDate'] != null) _expiryDate = results['expiryDate'];
          });

          if (results['issueDate'] != null || results['expiryDate'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Found dates: ${results['expiryDate'] != null ? "Expiry: ${DateFormat('dd-MMM-yyyy').format(results['expiryDate']!)}" : ""} ')),
            );
          } else {
             // Debugging help: Show what was seen
             showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("No Dates Detected"),
                  content: SingleChildScrollView(
                    child: Text("Could not find dates automatically. Here is the text we saw:\n\n${results['rawText'] ?? 'No text extracted'}", style: const TextStyle(fontSize: 10)),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                )
             );
          }
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        print('Error scanning PDF: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _scanDocument() async {
    // ... existing camera scan logic (unchanged for now, but could be unified) ...
    // keeping it simple as user asked for PDF upload detection specificallly
    // Reuse existing implementation but verify it handles nullable types compatible variables
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      final ocrService = OCRService();
      final File imageFile = File(image.path);
      
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        final dates = await ocrService.scanDocument(imageFile);
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          setState(() {
            if (dates['issueDate'] != null) _issueDate = dates['issueDate'];
            if (dates['expiryDate'] != null) _expiryDate = dates['expiryDate'];
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanned: Found ${_issueDate != null ? "Issue" : ""} ${_expiryDate != null ? "Expiry" : ""} dates')),
          );
        }
      } catch (e) {
         if (mounted) {
          Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error scanning: $e')),
          );
         }
      } finally {
        // ocrService.dispose(); // Removed dispose as it was likely closing native resources too aggressively or not needed if service is transient
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      // 1. Save file to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_selectedType!.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await _pickedFile!.copy(path.join(appDir.path, fileName));

      // 2. Calculate status
      String status = 'Valid';
      if (_expiryDate != null) {
        final now = DateTime.now();
        final daysUntilExpiry = _expiryDate!.difference(now).inDays;
        if (daysUntilExpiry < 0) {
          status = 'Expired';
        } else if (daysUntilExpiry <= 30) {
          status = 'Expiring';
        }
      }

      // 3. Save to DB
      final typeToSave = _selectedType == 'Other' ? _customTypeController.text.trim() : _selectedType!;
      final document = Document(
        docType: typeToSave,
        filePath: savedFile.path,
        issueDate: _issueDate != null ? DateFormat('yyyy-MM-dd').format(_issueDate!) : null,
        expiryDate: _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
        status: status,
      );

      final id = await DatabaseHelper.instance.create(document);

      // Schedule notification (only if expiry exists)
      await NotificationService().scheduleExpiryNotification(
        id: id,
        title: typeToSave,
        expiryDate: _expiryDate,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh
      }
    } else if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Document Type'),
                items: _docTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
              ),
              if (_selectedType == 'Other')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _customTypeController,
                    decoration: const InputDecoration(labelText: 'Enter Document Type'),
                    validator: (value) {
                      if (_selectedType == 'Other' && (value == null || value.isEmpty)) {
                        return 'Please enter a document type';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_pickedFile == null ? 'Pick PDF' : 'File Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pickedFile != null ? Colors.green : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanDocument,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Info'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected: ${path.basename(_pickedFile!.path)}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_issueDate == null
                    ? 'Select Issue Date (Optional)'
                    : 'Issue Date: ${DateFormat('yyyy-MM-dd').format(_issueDate!)}'),
                trailing: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                onTap: () => _selectDate(context, false),
              ),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Select Expiry Date (Optional)'
                    : 'Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                trailing: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                tileColor: null, // Removed warning color since it's now optional
                onTap: () => _selectDate(context, true),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveDocument,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
            ),
            child: const Text('SAVE DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
