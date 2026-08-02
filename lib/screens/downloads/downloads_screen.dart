// FILE: lib/screens/downloads/downloads_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/download_item.dart';
import '../../services/download_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadService>().loadDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DownloadService>();
    final downloads = svc.downloads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (svc.activeDownloads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${svc.activeDownloads.length} active',
                    style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: downloads.isEmpty
          ? const EmptyState(
              icon: Icons.download_outlined,
              title: 'No downloads yet',
              subtitle: 'Download past papers when you have internet access',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: downloads.length,
              itemBuilder: (_, i) => _DownloadCard(item: downloads[i]),
            ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadItem item;
  const _DownloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.read<DownloadService>();

    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case DownloadStatus.downloading:
        statusColor = AppTheme.primaryColor; statusIcon = Icons.downloading; break;
      case DownloadStatus.completed:
        statusColor = AppTheme.successColor; statusIcon = Icons.check_circle; break;
      case DownloadStatus.failed:
        statusColor = AppTheme.errorColor; statusIcon = Icons.error_outline; break;
      case DownloadStatus.paused:
        statusColor = AppTheme.warningColor; statusIcon = Icons.pause_circle_outline; break;
      default:
        statusColor = Colors.grey; statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            // Action buttons
            if (item.status == DownloadStatus.downloading)
              IconButton(
                icon: const Icon(Icons.pause, size: 20),
                onPressed: () => svc.pauseDownload(item.id),
                tooltip: 'Pause',
              )
            else if (item.status == DownloadStatus.paused)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 20),
                onPressed: () => svc.resumeDownload(item.id),
                tooltip: 'Resume',
              )
            else if (item.status == DownloadStatus.failed)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => svc.resumeDownload(item.id),
                tooltip: 'Retry',
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () async {
                final ok = await Helpers.showConfirmDialog(context,
                    title: 'Remove Download', content: 'Remove "${item.title}" from list?',
                    confirmText: 'Remove', isDestructive: true);
                if (ok && context.mounted) svc.cancelDownload(item.id);
              },
            ),
          ]),
          const SizedBox(height: 8),
          // Progress bar
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.paused) ...[
            LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item.formattedProgress, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
              Text('${(item.progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ] else
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.name.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (item.errorMessage != null) ...[
                const SizedBox(width: 8),
                Expanded(child: Text(item.errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ]),
        ]),
      ),
    );
  }
}
