import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:presence/app/style/app_color.dart';
import 'package:presence/app/widgets/custom_input.dart';

import '../controllers/update_pofile_controller.dart';

class UpdatePofileView extends GetView<UpdatePofileController> {
  final Map<String, dynamic> user = Get.arguments;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profile',
          style: TextStyle(color: AppColor.secondary, fontSize: 14),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/icons/arrow-left.svg'),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.isLoading.value || controller.isPickingImage.value
                  ? null
                  : () => controller.updateProfile(context),
              child: Text(
                (controller.isLoading.isFalse) ? 'Done' : 'Loading...',
              ),
              style: TextButton.styleFrom(foregroundColor: AppColor.primary),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 1,
            color: AppColor.secondaryExtraSoft,
          ),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(20),
        children: [
          // section 1 - Profile Picture
          Center(
            child: Stack(
              children: [
                GetBuilder<UpdatePofileController>(
                  builder: (controller) {
                    if (controller.image != null) {
                      return ClipOval(
                        child: Container(
                          width: 98,
                          height: 98,
                          color: AppColor.primaryExtraSoft,
                          child: Image.file(
                            File(controller.image!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } else {
                      return ClipOval(
                        child: Container(
                          width: 98,
                          height: 98,
                          color: AppColor.primaryExtraSoft,
                          child: Image.network(
                            (user["avatar"] == null || user['avatar'] == "")
                                ? "https://ui-avatars.com/api/?name=${user['name']}/"
                                : user['avatar'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.isPickingImage.value ||
                                controller.isLoading.value
                            ? null
                            : () => controller.pickImage(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: SvgPicture.asset('assets/icons/camera.svg'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          //section 2 - user data
          CustomInput(
            controller: controller.nameC,
            label: "Full Name",
            hint: "Your Full Name",
            margin: EdgeInsets.only(bottom: 16, top: 42),
          ),
          CustomInput(
            controller: controller.employeeidC,
            label: "Employee ID",
            hint: "100000000000",
            disabled: true,
          ),
          CustomInput(
            controller: controller.emailC,
            label: "Email",
            hint: "youremail@email.com",
            disabled: true,
          ),
        ],
      ),
    );
  }
}
