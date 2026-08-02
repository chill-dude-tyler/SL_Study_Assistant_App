// lib/models/download_item.dart

enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadItem {
  final String id;
  final String title;
  final String url;
  final String? filePath;
  final int fileSize;
  int downloadedBytes;
  DownloadStatus status;
  double progress;
  String? errorMessage;
  final String? sourceId;
  final String? sourceType;
  final DateTime createdAt;
  final DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    this.filePath,
    this.fileSize = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.sourceId,
    this.sourceType,
    required this.createdAt,
    this.completedAt,
  });

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'],
      title: map['title'],
      url: map['url'],
      filePath: map['file_path'],
      fileSize: map['file_size'] ?? 0,
      downloadedBytes: map['downloaded_bytes'] ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DownloadStatus.pending,
      ),
      progress: (map['progress'] ?? 0.0).toDouble(),
      errorMessage: map['error_message'],
      sourceId: map['source_id'],
      sourceType: map['source_type'],
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'file_path': filePath,
      'file_size': fileSize,
      'downloaded_bytes': downloadedBytes,
      'status': status.name,
      'progress': progress,
      'error_message': errorMessage,
      'source_id': sourceId,
      'source_type': sourceType,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  String get formattedProgress {
    if (fileSize > 0) {
      final downloaded = _formatBytes(downloadedBytes);
      final total = _formatBytes(fileSize);
      return '$downloaded / $total';
    }
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
