import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/style/app_color.dart';
import 'package:presence/company_data.dart';

class PresenceCard extends StatelessWidget {
  const PresenceCard({
    super.key,
    required this.userData,
    required this.todayPresenceData,
    this.date,
    this.fromCache = false,
    this.onCheckIn,
    this.onCheckOut,
    this.busy = false,
  });

  final Map<String, dynamic> userData;
  final Map<String, dynamic>? todayPresenceData;
  final DateTime? date;
  final bool fromCache;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final bool busy;

  String _time(String field) {
    final event = todayPresenceData?[field];
    final value = event is Map ? event['date'] : null;
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed == null ? '—' : DateFormat.Hm().format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final today = date ?? DateTime.now();
    final checkedIn = todayPresenceData?['masuk'] != null;
    final checkedOut = todayPresenceData?['keluar'] != null;
    final status = checkedOut
        ? 'Checked out'
        : checkedIn
        ? 'Checked in'
        : 'Not checked in';
    final weekday = CompanyData.config.isWorkday(today);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontFamily: 'inter'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today’s attendance', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              status,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, d MMMM').format(today)),
            const SizedBox(height: 16),
            Text(
              weekday
                  ? 'Shift ${DateFormat.Hm().format(CompanyData.shiftStart(today))} – ${DateFormat.Hm().format(CompanyData.shiftEnd(today))}'
                  : 'No scheduled shift today',
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final entries = [
                  _entry('Check-in', _time('masuk')),
                  _entry('Check-out', _time('keluar')),
                ];
                if (constraints.maxWidth < 260 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      entries[0],
                      const SizedBox(height: 16),
                      entries[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: entries[0]),
                    Expanded(child: entries[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              fromCache
                  ? 'Offline · showing last saved attendance.'
                  : 'Attendance is automatic. Use the button if needed.',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            if (onCheckIn != null || onCheckOut != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy || checkedOut
                      ? null
                      : checkedIn
                      ? onCheckOut
                      : onCheckIn,
                  icon: Icon(checkedIn ? Icons.logout : Icons.login),
                  label: Text(
                    busy
                        ? 'Saving…'
                        : checkedOut
                        ? 'Attendance complete'
                        : checkedIn
                        ? 'Check out'
                        : 'Check in',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entry(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
