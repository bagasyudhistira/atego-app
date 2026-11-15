import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presence/app/modules/home/controllers/home_controller.dart';

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  bool get emailVerified => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  @override
  User? currentUser = _User('employee-one');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Firestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Firebase references are stubbed to test subscription identity without a backend.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Document();
  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;
  @override
  Query<Map<String, dynamic>> limit(int count) => this;
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) => StreamController<QuerySnapshot<Map<String, dynamic>>>().stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection();
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) => StreamController<DocumentSnapshot<Map<String, dynamic>>>().stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Home reuses subscriptions until the account or attendance day changes',
    () {
      final auth = _Auth();
      final controller = HomeController(auth: auth, firestore: _Firestore());
      final day = DateTime(2026, 11, 16);
      final user = controller.streamUser();
      final history = controller.streamLastPresence();
      final today = controller.streamTodayPresence(date: day);
      expect(identical(user, controller.streamUser()), isTrue);
      expect(identical(history, controller.streamLastPresence()), isTrue);
      expect(
        identical(today, controller.streamTodayPresence(date: day)),
        isTrue,
      );

      expect(
        identical(
          today,
          controller.streamTodayPresence(
            date: day.add(const Duration(days: 1)),
          ),
        ),
        isFalse,
      );
      expect(identical(user, controller.streamUser()), isTrue);
      auth.currentUser = _User('employee-two');
      expect(identical(user, controller.streamUser()), isFalse);
      expect(identical(history, controller.streamLastPresence()), isFalse);
      expect(
        identical(today, controller.streamTodayPresence(date: day)),
        isFalse,
      );
    },
  );

  for (final failure in ['disabled', 'denied', 'error']) {
    test(
      'GPS refresh retains the last reading while pending, clears it when $failure',
      () async {
        const channel = MethodChannel('flutter.baseflow.com/geolocator');
        final serviceEnabled = Completer<bool>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'isLocationServiceEnabled') {
                return serviceEnabled.future;
              }
              if (call.method == 'checkPermission') {
                return failure == 'denied' ? 0 : 2;
              }
              throw PlatformException(code: 'unavailable');
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        final controller = HomeController(
          auth: _Auth(),
          firestore: _Firestore(),
        );
        final updated = DateTime(2026, 11, 16, 8);
        controller.inOffice.value = true;
        controller.officeDistance.value = '50 m';
        controller.lastLocationUpdate.value = updated;

        final refresh = controller.refreshLocation();
        expect(controller.isLoading.value, isTrue);
        expect(controller.inOffice.value, isTrue);
        expect(controller.officeDistance.value, '50 m');
        expect(controller.lastLocationUpdate.value, updated);
        serviceEnabled.complete(failure != 'disabled');
        await refresh;
        expect(controller.isLoading.value, isFalse);
        expect(controller.inOffice.value, isNull);
        expect(controller.officeDistance.value, '-');
        expect(controller.lastLocationUpdate.value, isNull);
      },
    );
  }
}
