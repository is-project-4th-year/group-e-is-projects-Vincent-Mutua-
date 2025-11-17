# is_application

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Platform permissions for profile image

- Android: we require camera and photo access for image picking and camera capture. Add the following to `android/app/src/main/AndroidManifest.xml` (already added by the project):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<!-- Android 13+ scoped images permission -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

- iOS: ensure the following keys are present in `ios/Runner/Info.plist` (already added by the project):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to choose a profile picture.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take a profile photo.</string>
```

## Image handling notes

- The Profile screen lets users pick or take a photo, then crops it to a square and compresses it before upload for efficient storage and consistent avatars.
- Uploads are stored in Firebase Storage at `user_photos/{uid}/avatar.jpg` (overwrites prior avatar file).
- If you want client-side cropping UX improvements, consider adding `image_cropper` settings or `image_cropper` plugin customization.

