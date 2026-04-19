import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// Widget that displays the current sync status
///
/// Shows different icons and colors based on sync state:
/// - Green cloud with checkmark: Synced
/// - Orange cloud with count badge: Offline/Pending
/// - Blue spinning cloud: Syncing
/// - Red cloud with X: Error
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService.instance.syncStatusNotifier,
      builder: (context, syncStatus, _) {
        return ValueListenableBuilder<int>(
          valueListenable: SyncService.instance.pendingCountNotifier,
          builder: (context, pendingCount, _) {
            return GestureDetector(
              onTap: () => _showSyncDetails(context, syncStatus, pendingCount),
              child: _buildIndicator(colors, syncStatus, pendingCount),
            );
          },
        );
      },
    );
  }

  Widget _buildIndicator(
    DailyDashColorScheme colors,
    SyncStatus status,
    int pendingCount,
  ) {
    IconData icon;
    Color color;
    Widget? badge;
    bool animate = false;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        color = colors.success;
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync_rounded;
        color = colors.primary;
        animate = true;
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_rounded;
        color = colors.chartOrange;
        if (pendingCount > 0) {
          badge = _buildBadge(colors, pendingCount);
        }
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_rounded;
        color = colors.error;
        break;
      case SyncStatus.idle:
        if (pendingCount > 0) {
          icon = Icons.cloud_upload_rounded;
          color = colors.chartOrange;
          badge = _buildBadge(colors, pendingCount);
        } else {
          icon = Icons.cloud_done_rounded;
          color = colors.success;
        }
        break;
    }

    Widget iconWidget = Icon(icon, color: color, size: 24);

    if (animate) {
      iconWidget = _AnimatedSyncIcon(color: color);
    }

    if (badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(right: -6, top: -4, child: badge),
        ],
      );
    }

    return iconWidget;
  }

  Widget _buildBadge(DailyDashColorScheme colors, int count) {
    final displayCount = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16),
      child: Text(
        displayCount,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSyncDetails(
    BuildContext context,
    SyncStatus status,
    int pendingCount,
  ) {
    final colors = context.colors;

    String title;
    String message;
    IconData icon;
    Color color;

    switch (status) {
      case SyncStatus.synced:
        title = 'All Synced';
        message = 'Your data is up to date with the cloud.';
        icon = Icons.cloud_done_rounded;
        color = colors.success;
        break;
      case SyncStatus.syncing:
        title = 'Syncing...';
        message = 'Your data is being synchronized with the cloud.';
        icon = Icons.cloud_sync_rounded;
        color = colors.primary;
        break;
      case SyncStatus.offline:
        title = 'Offline';
        message = pendingCount > 0
            ? '$pendingCount change${pendingCount > 1 ? 's' : ''} pending. Will sync when online.'
            : 'Changes will sync when you\'re back online.';
        icon = Icons.cloud_off_rounded;
        color = colors.chartOrange;
        break;
      case SyncStatus.error:
        final error = SyncService.instance.lastErrorNotifier.value;
        title = 'Sync Error';
        message = error ?? 'Failed to sync. Tap to retry.';
        icon = Icons.cloud_off_rounded;
        color = colors.error;
        break;
      case SyncStatus.idle:
        if (pendingCount > 0) {
          title = 'Pending Sync';
          message =
              '$pendingCount change${pendingCount > 1 ? 's' : ''} waiting to sync.';
          icon = Icons.cloud_upload_rounded;
          color = colors.chartOrange;
        } else {
          title = 'Synced';
          message = 'Your data is up to date.';
          icon = Icons.cloud_done_rounded;
          color = colors.success;
        }
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: colors.onSurface)),
          ],
        ),
        content: Text(message, style: TextStyle(color: colors.onSurfaceDim)),
        actions: [
          if (status == SyncStatus.error || status == SyncStatus.idle)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SyncService.instance.triggerSync();
              },
              child: Text('Sync Now', style: TextStyle(color: colors.primary)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colors.onSurfaceDim)),
          ),
        ],
      ),
    );
  }
}

/// Animated rotating sync icon for syncing state
class _AnimatedSyncIcon extends StatefulWidget {
  final Color color;

  const _AnimatedSyncIcon({required this.color});

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.cloud_sync_rounded, color: widget.color, size: 24),
    );
  }
}
