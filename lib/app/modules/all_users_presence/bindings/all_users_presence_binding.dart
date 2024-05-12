import 'package:get/get.dart';

import '../controllers/all_users_presence_controller.dart';

class AllUsersPresenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllUsersPresenceController>(
          () => AllUsersPresenceController(),
    );
  }
}