import 'package:flutter/material.dart';

import '../network.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const HistoryPage({
    super.key,
    required this.entries,
  });

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear recent trips?'),
        content: const Text('This removes the saved trip list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(
        context,
        <String, dynamic>{'clear': true},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent trips'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Calculate a route to save your first trip.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];

                final when = DateTime.tryParse(
                  entry['created']?.toString() ?? '',
                );

                final dateLabel = when == null
                    ? ''
                    : when.toLocal().toString().split('.').first;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          '${metroNetwork.name(entry['start'] as String)} → '
                          '${metroNetwork.name(
                            entry['destination'] as String,
                          )}',
                        ),
                        subtitle: Text(
                          'Saved fare: EGP ${entry['fare']}'
                          ' • ${entry['minutes']} min\n'
                          '$dateLabel\n'
                          'Tap to recalculate with current settings.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, entry),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
