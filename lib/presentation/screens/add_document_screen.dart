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
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
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
        ocrService.dispose();
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_formKey.currentState!.validate() && _pickedFile != null && _expiryDate != null) {
      // 1. Save file to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_selectedType!.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await _pickedFile!.copy(path.join(appDir.path, fileName));

      // 2. Calculate status
      final now = DateTime.now();
      final daysUntilExpiry = _expiryDate!.difference(now).inDays;
      String status = 'Valid';
      if (daysUntilExpiry < 0) {
        status = 'Expired';
      } else if (daysUntilExpiry <= 30) {
        status = 'Expiring';
      }

      // 3. Save to DB
      final typeToSave = _selectedType == 'Other' ? _customTypeController.text.trim() : _selectedType!;
      final document = Document(
        docType: typeToSave,
        filePath: savedFile.path,
        issueDate: _issueDate != null ? DateFormat('yyyy-MM-dd').format(_issueDate!) : '-',
        expiryDate: DateFormat('yyyy-MM-dd').format(_expiryDate!),
        status: status,
      );

      final id = await DatabaseHelper.instance.create(document);

      // Schedule notification
      await NotificationService().scheduleExpiryNotification(
        id: id,
        title: typeToSave,
        expiryDate: _expiryDate!,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh
      }
    } else if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
    } else if (_expiryDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
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
                    ? 'Select Expiry Date'
                    : 'Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                trailing: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                tileColor: _expiryDate == null ? Colors.deepOrange.withValues(alpha: 0.1) : null,
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
