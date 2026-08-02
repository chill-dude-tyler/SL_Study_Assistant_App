// lib/services/download_service.dart
// Manages file download queue with pause/resume support via Dio.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/download_item.dart';
import '../database/database_helper.dart';
import '../utils/helpers.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._();
  factory DownloadService() => _instance;
  DownloadService._();

  final Dio _dio = Dio();
  final DatabaseHelper _db = DatabaseHelper();
  final Map<String, CancelToken> _cancelTokens = {};

  List<DownloadItem> _downloads = [];
  List<DownloadItem> get downloads => _downloads;

  List<DownloadItem> get activeDownloads => _downloads
      .where((d) => d.status == DownloadStatus.downloading)
      .toList();

  List<DownloadItem> get completedDownloads => _downloads
      .where((d) => d.status == DownloadStatus.completed)
      .toList();

  Future<void> loadDownloads() async {
    final maps = await _db.query(
      DatabaseHelper.tableDownloads,
      orderBy: 'created_at DESC',
    );
    _downloads = maps.map((m) => DownloadItem.fromMap(m)).toList();
    notifyListeners();
  }

  /// Start a new download
  Future<String?> startDownload({
    required String title,
    required String url,
    String? sourceId,
    String? sourceType,
  }) async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return null;
    }

    // Create download record
    final item = DownloadItem(
      id: Helpers.generateId(),
      title: title,
      url: url,
      status: DownloadStatus.pending,
      sourceId: sourceId,
      sourceType: sourceType,
      createdAt: DateTime.now(),
    );

    await _db.insert(DatabaseHelper.tableDownloads, item.toMap());
    _downloads.insert(0, item);
    notifyListeners();

    // Start actual download
    _processDownload(item);
    return item.id;
  }

  Future<void> _processDownload(DownloadItem item) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      // Get save directory
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(dir.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = _extractFileName(item.url);
      final savePath = p.join(downloadsDir.path, fileName);

      // Update status to downloading
      _updateItemStatus(item.id, DownloadStatus.downloading, filePath: savePath);

      await _dio.download(
        item.url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(item.id, progress, received, total);
          }
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': '*/*'},
        ),
      );

      // Mark as completed
      _updateItemStatus(
        item.id,
        DownloadStatus.completed,
        filePath: savePath,
        completedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _updateItemStatus(item.id, DownloadStatus.paused);
      } else {
        _updateItemStatus(
          item.id,
          DownloadStatus.failed,
          errorMessage: e.message ?? 'Download failed',
        );
      }
    } catch (e) {
      _updateItemStatus(
        item.id,
        DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      _cancelTokens.remove(item.id);
    }
  }

  void _updateProgress(String id, double progress, int received, int total) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index].progress = progress;
      _downloads[index].downloadedBytes = received;
      _db.update(
        DatabaseHelper.tableDownloads,
        {
          'progress': progress,
          'downloaded_bytes': received,
          'file_size': total,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyListeners();
    }
  }

  void _updateItemStatus(
    String id,
    DownloadStatus status, {
    String? filePath,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index].status = status;
      final updateMap = <String, dynamic>{'status': status.name};
      if (filePath != null) {
        _downloads[index].filePath = null; // workaround for final field
        updateMap['file_path'] = filePath;
      }
      if (errorMessage != null) {
        updateMap['error_message'] = errorMessage;
      }
      if (completedAt != null) {
        updateMap['completed_at'] = completedAt.toIso8601String();
      }
      _db.update(
        DatabaseHelper.tableDownloads,
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyListeners();
    }
  }

  /// Pause a download
  void pauseDownload(String id) {
    _cancelTokens[id]?.cancel('Paused by user');
    _cancelTokens.remove(id);
  }

  /// Resume a paused download
  void resumeDownload(String id) {
    final item = _downloads.firstWhere((d) => d.id == id,
        orElse: () => throw Exception('Download not found'));
    _processDownload(item);
  }

  /// Cancel and delete a download
  Future<void> cancelDownload(String id) async {
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);

    await _db.delete(
      DatabaseHelper.tableDownloads,
      where: 'id = ?',
      whereArgs: [id],
    );
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  String _extractFileName(String url) {
    final parts = url.split('/');
    final name = parts.last.split('?').first;
    return name.isNotEmpty ? name : 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// Extension to allow mutable filePath workaround
extension DownloadItemExt on DownloadItem {
  String? get _filePath => filePath;
}
