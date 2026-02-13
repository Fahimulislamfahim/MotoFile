import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../data/daos/document_dao.dart';
import '../../data/database_helper.dart';
import '../../data/models/document_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_app_bar.dart';

class AddDocumentScreen extends StatefulWidget {
  final String? preselectedType;

  const AddDocumentScreen({super.key, this.preselectedType});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late ConfettiController _confettiController;
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.preselectedType != null && _docTypes.contains(widget.preselectedType)) {
      _selectedType = widget.preselectedType;
    } else {
      _selectedType = _docTypes.first;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  // File picking and scanning logic remains exactly the same
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      setState(() => _pickedFile = file);
      _scanDocumentInternal(file);
    }
  }

  Future<void> _scanDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: AppColors.primaryLight,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(title: 'Crop Document'),
      ],
    );

    if (croppedFile != null) {
      final file = File(croppedFile.path);
      setState(() => _pickedFile = file);
      _scanDocumentInternal(file);
    }
  }

  Future<void> _scanDocumentInternal(File file) async {
    final extension = path.extension(file.path).toLowerCase();
    final isPdf = extension == '.pdf';

    if (mounted) {
       showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: GlassCard(borderRadius: 16, padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Scanning...")]))),
      );
    }

    try {
      final ocrService = OCRService();
      final results = isPdf 
          ? await ocrService.scanPdf(file)
          : await ocrService.scanDocument(file);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {
          if (results['issueDate'] != null) _issueDate = results['issueDate'];
          if (results['expiryDate'] != null) _expiryDate = results['expiryDate'];
        });

        if (results['issueDate'] != null || results['expiryDate'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dates Detected!'), backgroundColor: AppColors.success));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No dates detected automatically.'), backgroundColor: AppColors.warning));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
       builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryLight, 
              surface: AppColors.surfaceLight,
            ),
          ),
          child: child!,
        );
      },
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
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      // Logic same as before
      final appDir = await getApplicationDocumentsDirectory();
      final fileExtension = path.extension(_pickedFile!.path);
      final fileName = '${_selectedType!.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final savedFile = await _pickedFile!.copy(path.join(appDir.path, fileName));

      String status = 'Valid';
      if (_expiryDate != null) {
        final now = DateTime.now();
        final daysUntilExpiry = _expiryDate!.difference(now).inDays;
        if (daysUntilExpiry < 0) status = 'Expired';
        else if (daysUntilExpiry <= 30) status = 'Expiring';
      }

      final typeToSave = _selectedType == 'Other' ? _customTypeController.text.trim() : _selectedType!;
      final document = Document(
        docType: typeToSave,
        filePath: savedFile.path,
        issueDate: _issueDate != null ? DateFormat('yyyy-MM-dd').format(_issueDate!) : null,
        expiryDate: _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
        status: status,
      );

      final id = await DocumentDao().create(document);
      await NotificationService().scheduleExpiryNotification(id: id, title: typeToSave, expiryDate: _expiryDate);

      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document Saved!'), backgroundColor: AppColors.success));
      
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) Navigator.pop(context, true);
    } else if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file or scan a document')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const PremiumAppBar(title: 'Add Document'),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 32,
                  child: Column(
                    children: [
                       DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Document Type', border: InputBorder.none),
                        dropdownColor: AppColors.surfaceLight,
                        style: Theme.of(context).textTheme.bodyLarge,
                        items: _docTypes.map((String type) {
                          return DropdownMenuItem<String>(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedType = newValue),
                      ),
                      if (_selectedType == 'Other')
                        Padding(
                           padding: const EdgeInsets.only(top: 8),
                           child: TextFormField(
                              controller: _customTypeController,
                              decoration: const InputDecoration(labelText: 'Enter Document Type', filled: true),
                              validator: (value) => _selectedType == 'Other' && (value == null || value.isEmpty) ? 'Required' : null,
                           ),
                        )
                    ],
                  ),
                ).animate().fadeIn().slideY(),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.upload_file, 
                        label: 'Pick File', 
                        onTap: _pickFile, 
                        isPrimary: _pickedFile != null
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.camera_alt, 
                        label: 'Scan', 
                        onTap: _scanDocument, 
                        isPrimary: false
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(),

                if (_pickedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: 32,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 8),
                          Expanded(child: Text('Selected: ${path.basename(_pickedFile!.path)}', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                
                GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 32,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(_issueDate == null ? 'Issue Date (Optional)' : 'Issue Date: ${DateFormat('yyyy-MM-dd').format(_issueDate!)}'),
                           trailing: Icon(Icons.calendar_today, color: AppColors.primaryLight),
                           onTap: () => _selectDate(context, false),
                        ),
                        Divider(height: 1),
                         ListTile(
                          title: Text(_expiryDate == null ? 'Expiry Date (Optional)' : 'Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                           trailing: Icon(Icons.calendar_today, color: AppColors.primaryLight),
                           onTap: () => _selectDate(context, true),
                        ),
                      ],
                    ),
                ).animate().fadeIn(delay: 400.ms).slideY(),
              ],
            ),
          ),
        ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              gravity: 0.1,
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: AppColors.primaryLight.withOpacity(0.5),
                shape: const StadiumBorder(),
              ),
              child: const Text('SAVE DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryLight : Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
          ]
        ),
        child: Column(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppColors.primaryLight, size: 28),
            const SizedBox(height: 8),
             Text(label, style: TextStyle(color: isPrimary ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
