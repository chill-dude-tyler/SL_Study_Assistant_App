// lib/services/file_service.dart
// Handles file picking, saving, and management using file_picker & path_provider.

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  static final FileService _instance = FileService._();
  factory FileService() => _instance;
  FileService._();

  /// Pick a PDF or document file
  Future<PlatformFile?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
        allowMultiple: false,
        withData: false,
        withReadStream: true,
      );
      return result?.files.single;
    } catch (e) {
      return null;
    }
  }

  /// Pick an image for OCR
  Future<PlatformFile?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      return result?.files.single;
    } catch (e) {
      return null;
    }
  }

  /// Get the app's documents directory
  Future<Directory> getDocumentsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir;
  }

  /// Get or create a sub-directory
  Future<Directory> getSubDir(String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save file to local storage and return the saved path
  Future<String?> saveFile(
    String sourcePath,
    String category,
    String fileName,
  ) async {
    try {
      final dir = await getSubDir(category);
      final destPath = p.join(dir.path, fileName);
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
        return destPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save bytes to local storage
  Future<String?> saveBytes(
    List<int> bytes,
    String category,
    String fileName,
  ) async {
    try {
      final dir = await getSubDir(category);
      final destPath = p.join(dir.path, fileName);
      final file = File(destPath);
      await file.writeAsBytes(bytes);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Get file size in bytes
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get total storage used by app
  Future<int> getTotalStorageUsed() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;

      await for (final entity
          in appDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Generate safe file name from title
  String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s.-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
