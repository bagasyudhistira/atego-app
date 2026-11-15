import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dashboard_panel.dart';

class LocationStatusPanel extends StatelessWidget {
  const LocationStatusPanel({
    super.key,
    required this.gps,
    required this.permission,
    required this.distance,
    required this.inOffice,
    required this.lastUpdate,
    required this.checking,
    required this.onRefresh,
  });

  final String gps;
  final String permission;
  final String distance;
  final bool? inOffice;
  final DateTime? lastUpdate;
  final bool checking;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(
          Icons.location_on_outlined,
          inOffice == null
              ? checking
                    ? 'Checking location…'
                    : 'Location unavailable'
              : inOffice!
              ? 'At the office'
              : 'Away from the office',
          inOffice == null
              ? gps == 'Disabled'
                    ? 'Turn on your phone’s location.'
                    : permission.startsWith('Blocked') ||
                          permission.startsWith('Not granted')
                    ? 'Allow location access in phone settings.'
                    : 'Refresh to try again.'
              : '$distance from the office',
        ),
        if (lastUpdate != null)
          Text(
            'Updated ${DateFormat.Hm().format(lastUpdate!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: checking ? null : onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(checking ? 'Refreshing…' : 'Refresh location'),
        ),
      ],
    ),
  );

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}
