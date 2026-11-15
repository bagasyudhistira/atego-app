import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/page_index_controller.dart';
import 'package:presence/app/controllers/theme_controller.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:presence/app/widgets/appearance_setting.dart';
import 'package:presence/app/widgets/dashboard_panel.dart';
import 'package:presence/app/widgets/dialog/action_confirmation.dart';
import 'package:presence/app/widgets/custom_bottom_navigation_bar.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  final pageIndexController = Get.find<PageIndexController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavigationBar(selectedIndex: 2),
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: controller.streamUser(),
              builder: (context, snapshot) {
                if (snapshot.hasError ||
                    (snapshot.connectionState != ConnectionState.waiting &&
                        snapshot.data?.data() == null)) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const DashboardMessage(
                        icon: Icons.person_outline,
                        title: 'Profile unavailable',
                        message: 'Try again when you’re online. Contact your administrator if this continues.',
                      ),
                      const SizedBox(height: 20),
                      DashboardPanel(
                        child: AppearanceSetting(
                          controller: Get.find<ThemeController>(),
                        ),
                      ),
                    ],
                  );
                }
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 24),
                        DashboardPanel(
                          child: AppearanceSetting(
                            controller: Get.find<ThemeController>(),
                          ),
                        ),
                      ],
                    );
                  case ConnectionState.active:
                  case ConnectionState.done:
                    Map<String, dynamic> userData = snapshot.data!.data()!;
                    return ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        SizedBox(height: 16),
                        // section 1 - profile
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 124,
                                height: 124,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: _avatar(context, userData),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 16, bottom: 4),
                              child: Text(
                                userData["name"] is String
                                    ? userData["name"]
                                    : 'Employee',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              userData["job"] is String ? userData["job"] : '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        DashboardPanel(
                          child: AppearanceSetting(
                            controller: Get.find<ThemeController>(),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.only(top: 42),
                          child: Column(
                            children: [
                              MenuTile(
                                title: 'Update Profile',
                                icon: SvgPicture.asset(
                                  'assets/icons/profile-1.svg',
                                ),
                                onTap: () => Get.toNamed(
                                  Routes.UPDATE_POFILE,
                                  arguments: userData,
                                ),
                              ),
                              (userData["role"] == "admin")
                                  ? MenuTile(
                                      title: 'Add Employee',
                                      icon: SvgPicture.asset(
                                        'assets/icons/people.svg',
                                      ),
                                      onTap: () =>
                                          Get.toNamed(Routes.ADD_EMPLOYEE),
                                    )
                                  : SizedBox(),
                              (userData["role"] == "admin")
                                  ? MenuTile(
                                      title: 'All User Presence',
                                      icon: SvgPicture.asset(
                                        'assets/icons/people.svg',
                                      ),
                                      onTap: () => Get.toNamed(
                                        Routes.ALL_USERS_PRESENCE,
                                      ),
                                    )
                                  : SizedBox(),
                              MenuTile(
                                title: 'Change Password',
                                icon: SvgPicture.asset(
                                  'assets/icons/password.svg',
                                ),
                                onTap: () =>
                                    Get.toNamed(Routes.CHANGE_PASSWORD),
                              ),
                              MenuTile(
                                isDanger: true,
                                title: 'Log out',
                                icon: SvgPicture.asset(
                                  'assets/icons/logout.svg',
                                ),
                                onTap: () async {
                                  final confirmed = await confirmAction(
                                    context,
                                    title: 'Log out?',
                                    message: 'You’ll need to log in again to access your account.',
                                    confirmLabel: 'Log out',
                                  );
                                  if (!confirmed || !context.mounted) return;
                                  await controller.logout();
                                },
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      ],
                    );
                  default:
                    return SizedBox();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context, Map<String, dynamic> user) {
    final name = user['name'] is String ? (user['name'] as String).trim() : '';
    final initials = name.isEmpty
        ? 'E'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => String.fromCharCode(part.runes.first))
              .join()
              .toUpperCase();
    final fallback = Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
    final avatar = user['avatar'];
    return avatar is String && avatar.isNotEmpty
        ? Image.network(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => fallback,
          )
        : fallback;
  }
}

class MenuTile extends StatelessWidget {
  final String title;
  final Widget icon;
  final void Function() onTap;
  final bool isDanger;
  MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              margin: EdgeInsets.only(right: 24),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSecondaryContainer,
                  BlendMode.srcIn,
                ),
                child: icon,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDanger
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 24),
              child: SvgPicture.asset(
                'assets/icons/arrow-right.svg',
                colorFilter: ColorFilter.mode(
                  isDanger
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
