# YouTube Downloader App

## Overview

This Flutter application allows users to download videos and audio from YouTube. It provides a simple interface for entering YouTube URLs, selecting download quality, and managing downloads. The app supports both video and audio-only downloads, with the ability to convert audio to MP3 format.

## Features

- Download YouTube videos in various qualities (high, medium, low)
- Download audio-only and convert to MP3
- Queue multiple downloads
- View download progress
- Manage completed downloads (open or delete)
- Customizable download path
- Storage permission handling for Android

## Technologies Used

- Flutter: Cross-platform UI framework
- Dart: Programming language
- youtube_explode_dart: Library for parsing YouTube URLs and extracting video information
- dio: HTTP client for Dart, used for downloading files
- ffmpeg_kit_flutter: FFmpeg library for audio conversion
- permission_handler: Package for handling Android permissions
- path_provider: Package for accessing device file system
- file_picker: Package for selecting download directory
- open_file: Package for opening downloaded files

## Project Structure

```
lib/
├── main.dart
├── download_page.dart
├── download_task.dart
└── notifications.dart
```

## Main Components

### main.dart

The entry point of the application. It initializes the app, sets up FFmpeg, and handles notifications initialization for Android.

### download_page.dart

The main UI of the app. It contains the `DownloadPage` widget, which manages the download queue, completed downloads, and user interactions.

### download_task.dart

Defines the `DownloadTask` class, which represents a single download task with properties like URL, quality, progress, and status.

### notifications.dart

Handles the initialization and display of local notifications for download completion.

## Component Relationships

- `main.dart` initializes the app and sets up `DownloadPage` as the home screen.
- `DownloadPage` uses `DownloadTask` objects to manage individual downloads.
- `DownloadPage` calls functions from `notifications.dart` to show download completion notifications.

## Building and Running the App

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio or Visual Studio Code with Flutter extensions
- An Android or iOS device/emulator

### Steps

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/youtube_downloader_app.git
   cd youtube_downloader_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Android permissions:
   Open `android/app/src/main/AndroidManifest.xml` and add the following permissions:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   ```

4. For Android 10 (API level 29) and above, add the following to your `AndroidManifest.xml` file, inside the `<application>` tag:
   ```xml
   android:requestLegacyExternalStorage="true"
   ```

5. Run the app:
   ```
   flutter run
   ```

## Troubleshooting

If you encounter any issues with FFmpeg, ensure that the FFmpeg kit is properly initialized in `main.dart` and that the necessary configurations are set in `android/app/build.gradle`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](MIT License).