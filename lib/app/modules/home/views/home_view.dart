import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/controllers/attendance_policy.dart';
import 'package:presence/app/controllers/presence_controller.dart';
import 'package:presence/app/widgets/custom_bottom_navigation_bar.dart';
import 'package:presence/app/widgets/dashboard_panel.dart';
import 'package:presence/app/widgets/dialog/action_confirmation.dart';
import 'package:presence/app/widgets/location_status_panel.dart';
import 'package:presence/app/widgets/presence_card.dart';
import 'package:presence/app/widgets/presence_tile.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const CustomBottomNavigationBar(selectedIndex: 0),
    body: SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: ObjectKey(controller.streamUser()),
        stream: controller.streamUser(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              Icons.cloud_off_outlined,
              'Profile unavailable',
              'Try again when you’re online. Contact your administrator if this continues.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data?.data();
          if (user == null) {
            return _message(
              Icons.person_search_outlined,
              'Employee profile missing',
              'Contact your administrator to set up your employee profile.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _greeting(context, user),
                  const SizedBox(height: 24),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    key: ObjectKey(controller.streamTodayPresence()),
                    stream: controller.streamTodayPresence(),
                    builder: (context, attendance) {
                      if (attendance.hasError) {
                        return const DashboardMessage(
                          icon: Icons.cloud_off_outlined,
                          title: 'Attendance unavailable',
                          message: 'Unable to load today’s attendance. Try again when you’re online.',
                        );
                      }
                      if (attendance.connectionState ==
                              ConnectionState.waiting &&
                          !attendance.hasData) {
                        return const DashboardPanel(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final presence = Get.find<PresenceController>();
                      return Obx(
                        () => PresenceCard(
                          userData: user,
                          todayPresenceData: attendance.data?.data(),
                          fromCache:
                              attendance.data?.metadata.isFromCache ?? false,
                          busy: presence.isLoading.value,
                          onCheckIn: () => _recordAttendance(
                            context,
                            AttendanceAction.checkIn,
                          ),
                          onCheckOut: () => _recordAttendance(
                            context,
                            AttendanceAction.checkOut,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => LocationStatusPanel(
                      gps: controller.gpsStatus.value,
                      permission: controller.permissionStatus.value,
                      distance: controller.officeDistance.value,
                      inOffice: controller.inOffice.value,
                      lastUpdate: controller.lastLocationUpdate.value,
                      checking: controller.isLoading.value,
                      onRefresh: controller.refreshLocation,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: controller.launchOfficeOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open office in Maps'),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      Text(
                        'Recent attendance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            Get.find<PageIndexController>().changePage(1),
                        child: const Text('View history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    key: ObjectKey(controller.streamLastPresence()),
                    stream: controller.streamLastPresence(),
                    builder: (context, history) {
                      if (history.hasError) {
                        return const DashboardMessage(
                          icon: Icons.cloud_off_outlined,
                          title: 'History unavailable',
                          message: 'Attendance history could not be loaded.',
                        );
                      }
                      if (history.connectionState == ConnectionState.waiting &&
                          !history.hasData) {
                        return const DashboardPanel(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final records = history.data?.docs ?? [];
                      if (records.isEmpty) {
                        return const DashboardMessage(
                          icon: Icons.event_note_outlined,
                          title: 'No attendance yet',
                          message: 'Your recorded check-ins and checkouts will appear here.',
                        );
                      }
                      return Column(
                        children: [
                          for (final record in records)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PresenceTile(presenceData: record.data()),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Future<void> _recordAttendance(
    BuildContext context,
    AttendanceAction action,
  ) async {
    final checkingIn = action == AttendanceAction.checkIn;
    final confirmed = await confirmAction(
      context,
      title: checkingIn ? 'Check in?' : 'Check out?',
      message: checkingIn
          ? 'Record your check-in now? Your location will be checked.'
          : 'Record your check-out now? Your location will be checked.',
      confirmLabel: checkingIn ? 'Check in' : 'Check out',
    );
    if (!confirmed || !context.mounted) return;
    final message = await Get.find<PresenceController>().manualAttendance(
      action,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _message(IconData icon, String title, String message) => ListView(
    padding: const EdgeInsets.all(20),
    children: [DashboardMessage(icon: icon, title: title, message: message)],
  );

  Widget _greeting(BuildContext context, Map<String, dynamic> user) {
    final name =
        user['name'] is String && (user['name'] as String).trim().isNotEmpty
        ? (user['name'] as String).trim()
        : 'Employee';
    final initials = name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => String.fromCharCode(part.runes.first))
        .join()
        .toUpperCase();
    final avatar = user['avatar'];
    final fallback = Center(child: Text(initials));
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatar is String && avatar.isNotEmpty
              ? Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => fallback,
                )
              : fallback,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              if (user['job'] is String) Text(user['job'] as String),
            ],
          ),
        ),
      ],
    );
  }
}
