# Dice Roll

A minimal Flutter game for two players sharing one device, with Firebase email/password login and signup. Supports **Android and web**.

Player 2 is on top; Player 1 is below and starts each match. Players alternate animated rolls from 1 to 6. The first to reach or exceed 30 points wins. Either **Roll again** button resets the match. Login persists between app launches; matches reset when the game screen closes.

## 1. Install tools on the new machine

1. Install [Git](https://git-scm.com/downloads).
2. Install the [Flutter SDK](https://docs.flutter.dev/install) and add its `bin` directory to your system `PATH`. Dart is bundled with Flutter.
3. Use **Flutter 3.47.6 / Dart 3.13.5**, the versions used for this project, or a compatible newer stable release. This project requires Dart `^3.13.5`.
4. For Android, install [Android Studio](https://developer.android.com/studio) and complete its setup wizard. For web, install Chrome or Microsoft Edge. An editor with the Flutter extension is optional.
5. Open a new terminal and check the tools:

```sh
git --version
flutter --version
flutter doctor -v
```

Resolve issues for your target platform. Windows/Linux desktop toolchains are not needed for Android or web; Firebase desktop support is not configured here.

## 2. Clone and install dependencies

```sh
git clone https://github.com/towfiq-rakin/dice_roll.git
cd dice_roll
flutter pub get
```

Run subsequent commands from this directory. Keep `pubspec.lock` to use the project's resolved dependency versions.

## 3. Check Firebase

The repository includes configuration for Firebase project **dice-roll-b65cc**:

- Android: `android/app/google-services.json`, matching package `com.example.dice_roll`.
- Web: `lib/firebase_web_options.dart`, passed to Firebase initialization in `lib/main.dart`.

No Firebase CLI or FlutterFire CLI setup is necessary to run the clone with this configuration. Both platforms use the same user accounts. Managing the project's console settings requires access to the Firebase project.

The project owner should check these settings in the [Firebase Console](https://console.firebase.google.com/):

1. Open **Build → Authentication → Sign-in method**.
2. Enable **Email/Password** and save.
3. For local web development, check **Authentication → Settings → Authorized domains** and add `localhost` if needed. Recent Firebase projects do not include it by default. Check your hosting domain if you later deploy the app. See [Firebase authentication troubleshooting](https://firebase.google.com/docs/auth/faq-and-troubleshooting).

### Optional: use your own Firebase project

1. Create a Firebase project and enable Email/Password.
2. Register an **Android app** with package `com.example.dice_roll`. Download its `google-services.json` and replace `android/app/google-services.json`. SHA-1 is not required for email/password authentication. The Gradle plugin is already configured.
3. Register a **Web app** in the same project. Copy its SDK configuration into `lib/firebase_web_options.dart`: `apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, and `appId`.
4. Check authorized domains as above, then fully stop and rerun the app.

Accounts from the original project do not transfer; sign up again. Firebase client configuration identifies the project and is not an administrator credential. See [Firebase project configuration](https://firebase.google.com/docs/projects/learn-more).

## 4. Run on Android

### Set up the SDK

1. Open Android Studio's **SDK Manager**.
2. Install Android SDK Platform, Build-Tools, Platform-Tools, and Command-line Tools as required by `flutter doctor`. Install Android Emulator if using a virtual device. The first build may download additional SDK components.
3. Review and accept SDK licenses, then verify the toolchain:

```sh
flutter doctor --android-licenses
flutter doctor -v
```

If Flutter cannot find a custom SDK installation, use its actual path from SDK Manager:

```sh
flutter config --android-sdk "PATH_TO_ANDROID_SDK"
```

Do not copy another machine's `android/local.properties`; Flutter generates this local file. See the [Android setup guide](https://docs.flutter.dev/platform-integration/android/setup) for toolchain issues.

### Connect a device and run

1. Either start an emulator through Android Studio's **Device Manager**, or connect a phone with Developer options and USB debugging enabled. Accept the phone's debugging prompt; install its USB driver on Windows if needed.
2. List connected devices:

```sh
flutter devices
```

3. Replace `ANDROID_DEVICE_ID` below with the Android ID from that output:

```sh
flutter run -d ANDROID_DEVICE_ID
```

The first build can take several minutes. Stop and rerun after changing native settings or Firebase configuration; hot reload does not apply native changes.

### Build and install an APK

```sh
flutter build apk --debug
flutter install --debug -d ANDROID_DEVICE_ID
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`. Installation requires a connected Android device. Store publishing needs your own release signing configuration; the current release configuration uses a debug key.

## 5. Run on web

Android Studio and the Android SDK are not required for web.

1. Install Chrome, or Edge on Windows.
2. Enable web support and confirm browser detection:

```sh
flutter config --enable-web
flutter devices
```

3. Launch in Chrome:

```sh
flutter run -d chrome --web-port 8080
```

Or use Edge on Windows:

```sh
flutter run -d edge --web-port 8080
```

For another browser, start a server and manually open the URL printed by Flutter:

```sh
flutter run -d web-server --web-hostname localhost --web-port 8080
```

Keep the terminal running. Web requires `lib/firebase_web_options.dart`; `google-services.json` configures Android only. See the [Flutter web setup guide](https://docs.flutter.dev/platform-integration/web/setup).

### Build web files

```sh
flutter build web
```

Output: `build/web/`. Serve this directory over HTTP or upload it to a static host. Do not open `index.html` directly as a local file. For a local preview with Python 3 installed:

```sh
python -m http.server 8080 --directory build/web
```

Open [localhost:8080](http://localhost:8080). On Windows, use `py` instead of `python` if Python is installed through the `py` launcher.

## 6. Log in and play

1. Choose **Sign up** and enter an email and a password of at least six characters, or log in with an existing account.
2. Player 1 rolls first. Only the current player's button is enabled; both buttons are disabled during animation.
3. Take turns until one player reaches at least 30 points.
4. Tap **Roll again** to reset the match.
5. Use the logout icon to return to login.

Internet access is required for Firebase signup/login. The two players share one screen and one login; this is local multiplayer.

## 7. Run checks

```sh
flutter analyze
flutter test
```

Tests cover authentication forms, submission errors, alternating turns, duplicate-roll prevention, winning, replay, small layouts, and cancelling animation when leaving the game.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `flutter` is not recognized | Add the SDK's `bin` directory to `PATH` and reopen the terminal. |
| Dart SDK is too old | Install the Flutter version above or a compatible newer release. |
| No Android device | Start the emulator or check USB debugging, authorization, cable, and drivers. |
| Android SDK/licenses missing | Install Command-line Tools in SDK Manager and follow the Android steps above. |
| Email/password sign-in disabled | Enable Email/Password in Firebase Authentication. |
| Firebase initialization fails | Verify the configuration for the platform and the registered app identifiers. |
| Port 8080 is in use | Choose another port using `--web-port`, or change the Python server port. |
| Stale build after configuration changes | Stop the app, run `flutter clean` and `flutter pub get`, then rebuild. |
