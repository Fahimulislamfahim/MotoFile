import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  Future<void> createBackup(BuildContext context) async {
    try {
      // 1. Get paths
      final dbPath = await getDatabasesPath();
      final databaseFile = File(p.join(dbPath, 'motofile.db'));
      final appDocDir = await getApplicationDocumentsDirectory();

      // 2. Create an archive
      final archive = Archive();

      // Add Database
      if (await databaseFile.exists()) {
        final dbBytes = await databaseFile.readAsBytes();
        archive.addFile(ArchiveFile('motofile.db', dbBytes.length, dbBytes));
      }

      // Add Document Directory contents (images etc)
      final entities = await appDocDir.list(recursive: true).toList();
      for (var entity in entities) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: appDocDir.path);
          // skip adding zip file if it's already there
          if (relativePath.endsWith('.zip')) continue;
          
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile('files/$relativePath', bytes.length, bytes));
        }
      }

      // 3. Zip it
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      // 4. Save zip temporarily to share
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(p.join(tempDir.path, 'motofile_backup_${DateTime.now().millisecondsSinceEpoch}.zip'));
      await backupFile.writeAsBytes(zipData);

      // 5. Share backup
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(backupFile.path)],
          text: 'MotoFile Backup',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    }
  }

  Future<void> restoreBackup(BuildContext context) async {
    try {
      // 1. Pick zip file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
      );

      if (result != null && result.files.single.path != null) {
        final zipFile = File(result.files.single.path!);
        
        // Ensure it's a zip file
        if (!zipFile.path.endsWith('.zip')) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Please select a valid .zip backup file')),
             );
           }
           return;
        }

        // 2. Decode archive
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // 3. Get paths
        final dbPath = await getDatabasesPath();
        final databasePath = p.join(dbPath, 'motofile.db');
        final appDocDir = await getApplicationDocumentsDirectory();
        
        // 4. Extract
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            if (filename == 'motofile.db') {
              // Overwrite database
              final dbFile = File(databasePath);
              await dbFile.writeAsBytes(data);
            } else if (filename.startsWith('files/')) {
              // Extract to appDocDir
              final relativePath = filename.substring('files/'.length);
              final targetFile = File(p.join(appDocDir.path, relativePath));
              // Ensure directory exists
              await targetFile.parent.create(recursive: true);
              await targetFile.writeAsBytes(data);
            }
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Backup restored successfully! Please completely close and reopen the app to apply changes.', style: TextStyle(fontWeight: FontWeight.bold)),
               duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    }
  }
}
