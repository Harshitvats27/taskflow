import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/di/providers.dart';

class OfflineBanner extends ConsumerWidget {
  final String cacheKey;
  final VoidCallback onRetry;

  const OfflineBanner({
    super.key,
    required this.cacheKey,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();

    final lastUpdated = ref.watch(lastUpdatedProvider(cacheKey));
    final timeString = lastUpdated != null
        ? DateFormat('MMM d, h:mm a').format(lastUpdated.toLocal())
        : 'Never';

    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'re offline',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  'Last updated: $timeString',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }
}
