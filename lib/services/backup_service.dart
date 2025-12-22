import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/business_card.dart';

class BackupService {
  Future<void> exportDatabase(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get all cards
      final cards = await DatabaseHelper.instance.readAllCards();
      if (cards.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No cards to export')));
        }
        return;
      }

      // 2. Setup temp directory structure
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupRootDir = Directory(
        p.join(tempDir.path, 'backup_$timestamp'),
      );
      if (await backupRootDir.exists())
        await backupRootDir.delete(recursive: true);
      await backupRootDir.create();

      final imagesDestDir = Directory(p.join(backupRootDir.path, 'images'));
      await imagesDestDir.create();

      // 3. Process cards
      final List<Map<String, dynamic>> cardsJson = [];

      for (final card in cards) {
        final cardData = card.toMap();

        // Handle Image
        if (card.imagePath.isNotEmpty) {
          final sourceFile = File(card.imagePath);
          if (await sourceFile.exists()) {
            final fileName = p.basename(card.imagePath);
            // Ensure unique filename in backup in case of collisions
            final cleanFileName = '${card.id}_$fileName';
            final destPath = p.join(imagesDestDir.path, cleanFileName);

            await sourceFile.copy(destPath);

            // Update path to be relative for the backup (force forward slashes for zip)
            cardData['imagePath'] = 'images/$cleanFileName';
          } else {
            // Keeps original path but it won't work on other devices.
            // Maybe clear it? Or keeping it implies "missing".
            // We'll leave it but since we aren't copying the file,
            // import logic needs to handle missing files gracefully.
            cardData['imagePath'] = '';
          }
        }

        cardsJson.add(cardData);
      }

      // 4. Create JSON file
      final jsonFile = File(p.join(backupRootDir.path, 'bcard_data.json'));
      await jsonFile.writeAsString(
        jsonEncode({'cards': cardsJson, 'version': 1}),
      );

      // 5. Zip it up
      final zipFilePath = p.join(tempDir.path, 'bcard_backup_$timestamp.zip');
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      // Add JSON file at root
      await encoder.addFile(jsonFile, 'bcard_data.json');

      // Add Images
      if (await imagesDestDir.exists()) {
        await for (final file in imagesDestDir.list()) {
          if (file is File) {
            await encoder.addFile(file, 'images/${p.basename(file.path)}');
          }
        }
      }

      encoder.close();

      // 6. Share
      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Using share_plus to export
        final result = await Share.shareXFiles([
          XFile(zipFilePath),
        ], text: 'VibeCode Business Cards Backup (${cards.length} cards)');

        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Export successful')));
        }
      }

      // Cleanup? OS cleans temp, but good practice.
      // await backupRootDir.delete(recursive: true);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
      debugPrint('Export Error: $e');
    }
  }

  Future<void> importDatabase(BuildContext context) async {
    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      // Show loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final zipPath = result.files.single.path!;
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(
        p.join(tempDir.path, 'import_${DateTime.now().millisecondsSinceEpoch}'),
      );
      await extractDir.create();

      // 2. Extract Zip
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (var file in archive.files) {
        final filename = file.name;
        if (file.isFile) {
          // Sanitize filename to prevent directory traversal
          if (filename.contains('..')) continue;

          final destPath = p.join(extractDir.path, filename);
          final outFile = File(destPath);
          await outFile.parent.create(recursive: true);

          final outputStream = OutputFileStream(outFile.path);
          file.writeContent(outputStream);
          outputStream.close();
        }
      }

      // Debug print extracted structure
      debugPrint('Extracted files to: ${extractDir.path}');
      await for (final entity in extractDir.list(recursive: true)) {
        debugPrint(' - ${entity.path}');
      }

      // 3. Locate and Read JSON
      // The zip structure might be:
      // root/bcard_data.json
      // root/images/...
      // OR
      // root/backup_TIMESTAMP/bcard_data.json (if root folder was zipped)

      // Let's find the json file recursively
      File? jsonFile;
      await for (final entity in extractDir.list(recursive: true)) {
        if (entity is File && p.basename(entity.path) == 'bcard_data.json') {
          jsonFile = entity;
          break;
        }
      }

      if (jsonFile == null) {
        throw Exception('Invalid backup file: bcard_data.json not found');
      }

      final jsonString = await jsonFile.readAsString();
      final data = jsonDecode(jsonString);
      final List cardsList = data['cards'] ?? [];

      // 4. Process Cards and Images
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDocDir.path, 'card_images'));
      if (!await imagesDir.exists()) await imagesDir.create();

      int importCount = 0;

      // Calculate the root of the backup (where JSON is) to resolve relative paths
      final backupRootPath = jsonFile.parent.path;

      for (final cardMap in cardsList) {
        // Handle image
        String newImagePath = '';
        final relativeImgPath = cardMap['imagePath'] as String?;

        if (relativeImgPath != null && relativeImgPath.isNotEmpty) {
          final imageSourceFile = File(p.join(backupRootPath, relativeImgPath));
          if (await imageSourceFile.exists()) {
            // Copy to app storage
            final fileName = p.basename(relativeImgPath);
            // Ensure uniqueness
            final newFileName = '${const Uuid().v4()}_$fileName';
            final targetFile = File(p.join(imagesDir.path, newFileName));

            await imageSourceFile.copy(targetFile.path);
            newImagePath = targetFile.path;
          }
        }

        // Create Card Object
        // We might need to override the ID to avoid conflicts if we wanted toDuplicate,
        // but typically Restore overwrites or adds back known IDs.
        // Given `conflictAlgorithm.replace` in DB helper, this will overwrite existing cards with same ID.
        // This is preferred for "Import/Restore".

        // We reconstruct the map with the NEW image path
        final Map<String, dynamic> newCardMap = Map.from(cardMap);
        if (newImagePath.isNotEmpty) {
          newCardMap['imagePath'] = newImagePath;
        } else {
          // If we couldn't restore image, but one was listed..
          // For now, set empty or keep old logic if it was absolute (unlikely from our export)
          newCardMap['imagePath'] = '';
        }

        final card = BusinessCard.fromMap(newCardMap);
        await DatabaseHelper.instance.createCard(card);
        importCount++;
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $importCount cards successfully')),
        );
        // Refresh?
      }

      // Note: The UI won't auto-refresh unless we trigger it.
      // Ideally we callback or use Provider. But HomeScreen calls `readAllCards` on `initData`.
      // The user might need to pull-to-refresh or restart, or we can use the result to trigger refresh.
      // SettingsScreen doesn't have direct access to HomeScreen state.
      // But HomeScreen refreshes on nav changes often.
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
      debugPrint('Import Error Details: $e');
    }
  }
}
