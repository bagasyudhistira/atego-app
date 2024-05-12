import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:presence/app/style/app_color.dart';

import '../../../widgets/presence_tile.dart';
import '../controllers/all_users_presence_controller.dart';

class AllUsersPresenceView extends GetView<AllUsersPresenceController> {
  String selectedUser = "0";

  @override
  Widget build(BuildContext context) {
    String displayUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Users Presence',
          style: TextStyle(
            color: AppColor.secondary,
            fontSize: 14,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/icons/arrow-left.svg'),
        ),
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
      body: Center(
          child: ListView(
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('employee').snapshots(),
              builder: (context, snapshot) {
                List<DropdownMenuItem<String>> clientItems = [];
                if (!snapshot.hasData) {
                  const CircularProgressIndicator();
                } else {
                  final clients = snapshot.data?.docs.reversed.toList();
                  clientItems.add(DropdownMenuItem(
                    value: "0",
                    child: Text('Select User'),
                  ));

                  for (var client in clients!) {
                    clientItems.add(
                      DropdownMenuItem(
                        value: client.id,
                        child: Text(
                          client['name'],
                        ),
                      ),
                    );
                  }
                }
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  child: DropdownButton(
                    items: clientItems,
                    onChanged: (String? clientValue) {
                      selectedUser = clientValue!;
                      displayUser=clientValue;
                      // controller.displayUser.value = clientValue;
                      controller.UserSearch((clientValue).toString());
                      // print((clientValue).toString());
                    },
                    value: selectedUser,
                    isExpanded: false,
                  ),
                );
              }),
          GetBuilder<AllUsersPresenceController>(
            builder: (con) {
              return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: controller.getAllUsersPresence(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Center(child: CircularProgressIndicator());
                    case ConnectionState.active:
                    case ConnectionState.done:
                      var data = snapshot.data!.docs;
                      return ListView.separated(
                        itemCount: data.length,
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.all(20),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          var presenceData = data[index].data();
                          return PresenceTile(
                            presenceData: presenceData,
                          );
                        },
                      );
                    default:
                      return SizedBox();
                  }
                },
              );
            },
          ),
        ],
      )),
    );
  }
}
