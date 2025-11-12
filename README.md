# Camera_test_task

A Flutter camera application that requests camera permission on launch and displays a live camera interface. The interface includes controls to switch between front and back cameras (rear active by default), add a semi-transparent overlay image from the gallery, start/stop video recording, and take photo snapshots.

## Key features

* Requests camera (and microphone, if needed) permission immediately on app start.
* Full-screen live camera preview.
* Toggle between rear and front cameras (rear active by default).
* Open gallery to select an image that is displayed as a static overlay above the preview (80% opacity) to help frame shots.
* Start / stop video recording.
* Capture photo snapshots.

## Requirements

* Flutter SDK (3.x or later recommended)
* A real device is recommended for camera and microphone functionality (simulators may have limited support).

## Dependencies (add to `pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: any
  image_picker: any
  permission_handler: any
  path_provider: any
```

(Use specific version constraints as desired for your project.)

## Android permissions

Add these permissions to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

If you save to external storage or need additional access, add the appropriate permissions and handle runtime requests as required.

## iOS permissions

Open `ios/Runner/Info.plist` and add the following entries inside the `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to take photos and record video.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record video sound.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photos to select an overlay image.</string>
```

## Installation & run

1. Clone the repository or add the code to a Flutter project.
2. Update `pubspec.yaml` and run:

   ```
   flutter pub get
   ```
3. Run the app on a connected device:

   ```
   flutter run
   ```

## Usage

1. On first launch the app requests camera (and microphone) permission. Grant permissions to continue.
2. After permission is granted the camera preview appears.
3. Controls (typically overlaid at the bottom or side, left→right):

   * **Switch Camera** — toggles between rear and front cameras. The app initializes with the rear camera active.
   * **Open Gallery / Add Overlay** — opens the image picker; selecting an image displays it as a static overlay on top of the camera preview with ~80% opacity to aid framing.
   * **Record / Stop** — starts and stops video recording; recorded files are saved locally.
   * **Capture Photo** — takes a still image and saves it locally.

The overlay remains visible on top of the camera preview until the user removes or replaces it. The overlay does not stop the preview; it is a semi-transparent guide layer only.

## Implementation notes

* Use `camera` package for preview, photo capture, and video recording.
* Use `image_picker` for selecting gallery images for overlay.
* Stack the camera preview and the overlay image in a `Stack` widget; wrap the overlay in an `Opacity` widget set to `0.8` for 80% opacity.
* Reinitialize the `CameraController` when switching between cameras.
* Ensure the `CameraController` is properly disposed and handle app lifecycle changes (pause/resume) to avoid resource conflicts.
* Use `path_provider` or similar to locate a safe directory for saving captured photos/videos.

## Saving and playback

* Captured photos and videos should be written to a local file (for example, the application documents directory) with unique filenames (timestamps recommended).
* Optionally, implement a simple gallery or playback screen to view recorded videos and photos within the app.