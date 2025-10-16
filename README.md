# Issho - Final Year Project

- Issho is a Flutter-based mobile application developed by Ibrahim Azaan Mauroof (TP070788) from intake APD3F2411SE (Software Engineering) to facilitate and encourage more physical events and make meaningful and productive social connections.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Running the App on an Emulator](#running-the-app-on-an-emulator)
- [Installing the Release APK on Android](#installing-the-release-apk-on-android)

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Flutter SDK installed ([installation guide](https://flutter.dev/docs/get-started/install))
- Android Studio (for Android emulator)
- VS Code or Android Studio (recommended IDEs)
- For physical device testing: USB debugging enabled on your Android device

## Running the App on an Emulator

1. **Set up an emulator**:
   - Open Android Studio
   - Go to Tools → AVD Manager
   - Create a new virtual device (recommended: Pixel 5 with API 30 or higher)
   - Start the emulator
2. **Run the app**:

   ```bash
   
   # Navigate to the project directory
   cd issho
   
   # Install dependencies
   flutter pub get
   
   # Run the app on the emulator
   flutter run

## Installing the Release APK on Android

1. **Build the APK**
    - Navigate to your project's root directory in the terminal and run:

    ```bash
    flutter build apk --release
    -This command will compile your Dart code into native ARM and x64 machine code, optimize assets, and package everything into an Android application package (APK).

2. **Locate the Release APK**

    - Once the build process is complete, you will find the generated APK file in the following directory:
    build/app/outputs/flutter-apk/app-release.apk

3. **Install the APK on your Phone**
    - There are a few ways to install the app-release.apk file on an Android phone:
    - Method 1: Via USB Cable (Recommended)
    - Connect your phone to your computer using a USB cable.
    - Enable File Transfer: On your phone, pull down the notification shade and tap the USB connection notification. Select "File transfer" or "MTP" (Media Transfer Protocol).
    - Copy the APK: Locate the app-release.apk file on your computer (from build/app/outputs/flutter-apk/) and copy it to your phone's internal storage (e.g., to the "Downloads" folder or a new "APKs" folder).
    - Install the APK:
        - On your phone, open a file manager app (e.g., "Files," "My Files").
        - Navigate to where you copied the app-release.apk file.
        - Tap on the app-release.apk file.
        - Enable "Install unknown apps": If prompted, you'll need to grant permission to your file manager or browser to install apps from unknown sources. Follow the on-screen instructions to go to settings and enable this. (You might want to disable this after installation for security reasons).
        - Tap "Install" to install the app.
