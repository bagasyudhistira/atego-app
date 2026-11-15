## Introduction

ATEGO (Attendance on the Go) is an automatic presence application based on Global Positioning System (GPS) for smartphones. ATEGO can run in the background and record incoming attendance (check-in) when within the radius of the attendance point and record outgoing attendance (check-out) when leaving the radius of the attendance point automatically. ATEGO is based on mrezkys' flutter_presence repository, which is an open-source project. You can find the repository <a href="https://github.com/mrezkys/flutter_presence/">here.</a>

[//]: # (## App Screenshot)

[//]: # ()
[//]: # (<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/banner.jpg" width="auto" height="auto" >)

[//]: # (<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/shot.jpg" width="auto" height="auto" >)

[//]: # (<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/details.jpg" width="auto" height="auto" >)

## Prerequisites

- Flutter 3.50.0 (the validation version recorded in `.flutter-version`) with its bundled Dart SDK.
- Add Flutter's `bin` directory to PATH, or select your local SDK in VS Code.
- On Windows, enable Developer Mode to allow Flutter plugin symlinks.
- Android testing requires JDK 17, Android SDK command-line tools, accepted SDK licenses, and a phone with USB debugging enabled (or an emulator). Run `flutter doctor -v` to check the setup.
- Android debug APK compilation is verified with Gradle 9.5.0, Android Gradle Plugin 9.3.1, and Kotlin 2.4.20. The output is `build/app/outputs/flutter-apk/app-debug.apk`; on-device behavior is not yet verified. Release builds require a production signing configuration.
- Older Firebase, geolocator, and maps-launcher Android modules are aligned to compile SDK 36 in `android/build.gradle`. Flutter still warns that the app and maps-launcher must migrate to built-in Kotlin before a future Flutter upgrade.
- In VS Code, run the **Build Android debug APK** task. The first build downloads required Android components.
- Android uses package `com.bagasyudhistira.atego` and the isolated Firebase test project `atego-app`. Its default Firestore database is in Jakarta (`asia-southeast2`), with Email/Password authentication enabled. Initial production-mode rules deny client access; deploy app-specific rules and create a dedicated test employee before attendance testing. Storage is not yet provisioned.
- Android native configuration and Dart Firebase options must target the same registered Firebase app. Web and iOS still contain legacy Firebase configuration; do not launch them until they are configured for an isolated test backend.
- Changing the Android package creates a separate installed app; it does not migrate sessions or data from `com.bagasyudhistira.presence`.

## Development checks

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib/app/controllers/attendance_policy.dart test/attendance_policy_test.dart
flutter test test/attendance_policy_test.dart
```

Attendance uses the device's local date/time, weekday-only check-in, a 200-metre office radius, and 08:00–16:00 shift boundaries. Leaving the radius triggers checkout; 23:59 is the existing day-end fallback. Boundary times are inclusive. Existing attendance document IDs and fields are retained.

Tracking is started only for authenticated, email-verified users. On Android, a location foreground service runs attendance polling in a separate Flutter isolate with a persistent notification. Location permission is requested while the app is visible. Signing out requests service shutdown; the worker also checks the expected user identity. Polls are serialized and attendance transitions use Firestore transactions, which require connectivity. Shutdown cannot recall a database request already submitted.

Background tracking still requires device validation, including permission denial, minimizing the app, sign-out, account switching, and GPS/network loss. Tracking does not automatically start after reboot and is not guaranteed after force-stop, OS/vendor termination, or permission revocation. iOS background execution is not implemented; other platforms retain in-app timer polling. Fixed company timezone and overnight shifts remain unresolved.

## Firestore employee test setup

`firestore.rules` grants verified accounts with an `employee` role access only to their own employee document and attendance subcollection. Employee documents must be created through the Firebase Console with the Authentication UID as the document ID. Required string fields are `employee_id`, `name`, `email`, `role` (`employee`), `job`, and `created_at` (ISO8601).

Profile changes are limited to `name`, `avatar`, `position`, and `address`. Attendance allows an in-radius check-in followed by one checkout, preserving the original check-in. Document creation/deletion for employees, role changes, other users' data, and admin access are denied. The current admin employee-creation flow is incompatible with these rules; use the console instead.

These are client-access and schema safeguards, not trusted attendance verification. GPS coordinates, dates, office distance, and punctuality are supplied by the device. The rules do not enforce weekday, office coordinates, document date IDs, or trusted server time. Production attendance requires server-side validation; the string-date ordering assumes the app's consistent local ISO8601 format.

Run the isolated emulator tests (Node.js supported by Firebase CLI and Java 21 are required):

```powershell
Push-Location test\firestore
npm ci
npm test
Pop-Location
```

Tests use the `demo-atego-rules` project and do not access the live Firebase database. Publish the exact contents of `firestore.rules` in the `atego-app` Firestore Rules tab only after the tests pass, or use an authenticated Firebase CLI:

```powershell
npx --prefix test\firestore firebase deploy --only firestore:rules --project atego-app
```

Firebase Storage is not provisioned; avatar uploads require a Storage bucket and owner-only Storage rules in the same test project. Provisioning may require the Blaze billing plan; do not enable billing without the project owner's approval. Firestore rules do not grant Storage access. The app accepts JPEG, PNG, and WebP avatars up to 5 MB, prevents overlapping photo pickers, and reports upload failures without discarding the selected image. Create and verify a dedicated test account, then confirm its employee document exists before logging in.

## Installation

**Step 1:**

Download or clone this repository by using the link below and do flutter pub get.

```
cd atego-app
flutter pub get
```

**Step 2:**

Rename the application package name ( because this can affect the Firebase ) . You can do it manually or using this package <a href="https://pub.dev/packages/rename">Rename Package</a> or look at this <a href="https://stackoverflow.com/questions/51534616/how-to-change-package-name-in-flutter">Stackoverflow Question</a>

**Step 3:**

Reinitialize the Firebase CLI. <a href="https://firebase.google.com/docs/flutter/setup">See Documentation</a>

**Step 4:**

Enable Firebase email & password authentication

**Step 5:**

Create Firestore Database

**Step 6:**

This time, we will set up the database and admin account. The first thing that you need to do is add user at firebase console authentication menu
<br><img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/tutor/step 1.JPG" width="400" height="auto" ><br>
copy the User UID. Next, you need to start a collection like this : *use the User UID as Document id
<br><img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/tutor/step 2.JPG" width="400" height="auto" ><br>
role is the important field, in this application there are 2 role ( admin and employee ). Also, the created_at field is using Iso8601String, but you can use this dummy date
```
2022-05-10T12:34:58.274129
```

**Step 7:**

Build & run the Flutter application

**Step 8:**

Change the company data at lib/company_data.dart
## License
Flutter Presence is under MIT License.
