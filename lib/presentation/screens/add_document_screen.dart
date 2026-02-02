import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/database_helper.dart';
import '../../data/models/document_model.dart';

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

  final List<String> _docTypes = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance'
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
      final document = Document(
        docType: _selectedType!,
        filePath: savedFile.path,
        issueDate: _issueDate != null ? DateFormat('yyyy-MM-dd').format(_issueDate!) : '-',
        expiryDate: DateFormat('yyyy-MM-dd').format(_expiryDate!),
        status: status,
      );

      await DatabaseHelper.instance.create(document);

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_pickedFile == null ? 'Pick PDF' : 'File Selected: ${path.basename(_pickedFile!.path)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pickedFile != null ? Colors.green : null,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_issueDate == null
                    ? 'Select Issue Date (Optional)'
                    : 'Issue Date: ${DateFormat('yyyy-MM-dd').format(_issueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Select Expiry Date'
                    : 'Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                trailing: const Icon(Icons.calendar_today, color: Colors.cyan),
                 tileColor: _expiryDate == null ? Colors.deepOrange.withValues(alpha: 0.1) : null,
                onTap: () => _selectDate(context, true),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveDocument,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF00FFFF),
                  foregroundColor: Colors.black,
                ),
                child: const Text('SAVE DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
