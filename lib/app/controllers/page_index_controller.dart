import 'package:get/get.dart';
import 'package:presence/app/routes/app_pages.dart';

class PageIndexController extends GetxController {
  RxInt pageIndex = 0.obs;

  void changePage(int index) {
    final route = switch (index) {
      1 => Routes.ALL_PRESENCE,
      2 => Routes.PROFILE,
      _ => Routes.HOME,
    };
    if (Get.currentRoute == route) return;
    pageIndex.value = index;
    Get.offAllNamed(route);
  }
}
