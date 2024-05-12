## Introduction

ATEGO (Attendance on the Go) is an automatic presence application based on Global Positioning System (GPS) for smartphones. ATEGO can run in the background and record incoming attendance (check-in) when within the radius of the attendance point and record outgoing attendance (check-out) when leaving the radius of the attendance point. ATEGO is based on mrezkys' flutter_presence repository, which is an open-source project. You can find the repository <a href="https://github.com/mrezkys/flutter_presence/">here.</a>

## App Screenshot

<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/banner.jpg" width="auto" height="auto" >
<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/shot.jpg" width="auto" height="auto" >
<img src="https://github.com/mrezkys/flutter_presence/blob/main/demo/details.jpg" width="auto" height="auto" >

## Prequites

Flutter SDK Version 2.10.1
Java JDK 11 (to build with gradle) || add Java JDK 11 Path in android > gradle.properties : `org.gradle.java.home=C:\\Program Files\\Zulu\\zulu-11`
Gradle 6.7

## Installation

**Step 1:**

Download or clone this repo by using the link below and do flutter pub get.

```
cd atego-app
flutter pub get
```

**Step 2:**

Rename the app package name ( because this can affect the firebase ) . You can do it manually or using this package <a href="https://pub.dev/packages/rename">Rename Package</a> or look at this <a href="https://stackoverflow.com/questions/51534616/how-to-change-package-name-in-flutter">Stackoverflow Question</a>

**Step 3:**

Re init the firebase cli. <a href="https://firebase.google.com/docs/flutter/setup">See Documentation</a>

**Step 4:**

Enable firebase email/password authentication

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

Run the flutter app

**Step 8:**

Change the company data at lib/company_data.dart
## License
Flutter Presence is under MIT License.
