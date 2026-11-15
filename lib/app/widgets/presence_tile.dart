import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/routes/app_pages.dart';

class PresenceTile extends StatelessWidget {
  const PresenceTile({super.key, required this.presenceData});
  final Map<String, dynamic> presenceData;

  DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  String _time(String field) {
    final event = presenceData[field];
    final date = _date(event is Map ? event['date'] : null);
    return date == null ? '—' : DateFormat.Hm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final date = _date(presenceData['date']);
    final checkIn = presenceData['masuk'];
    final onTime = checkIn is Map ? checkIn['on_time'] : null;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Get.toNamed(Routes.DETAIL_PRESENCE, arguments: presenceData),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date == null
                    ? 'Date unavailable'
                    : DateFormat('EEE, d MMM yyyy').format(date),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text('Check-in  ${_time('masuk')}'),
                  Text('Check-out  ${_time('keluar')}'),
                ],
              ),
              if (onTime is bool) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      onTime ? Icons.check_circle_outline : Icons.schedule,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        onTime ? 'On-time check-in' : 'Late check-in',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
