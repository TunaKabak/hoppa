# Build Instructions for Hoppa Application

This document provides the official commands for creating a release build of the application with security best practices, including code obfuscation, enabled.

## Code Obfuscation

To prevent reverse-engineering and protect the application's source code, all release builds **must** be generated with the `--obfuscate` flag. This makes the compiled code significantly harder for humans to read and understand.

---

## Android Release Build (App Bundle)

To build the Android App Bundle (`.aab`) for submission to the Google Play Store, run the following command from the project's root directory:

```bash
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
```

- **`--obfuscate`**: Enables code obfuscation.
- **`--split-debug-info`**: Creates a directory with the debug symbols, which are necessary for de-obfuscating crash reports from the Play Console. **Store this directory in a secure location.**

The generated app bundle will be located at `build/app/outputs/bundle/release/app-release.aab`.

---

## iOS Release Build (Archive)

To build the iOS archive (`.xcarchive`) for submission to the App Store, run the following command from the project's root directory:

```bash
flutter build ipa --obfuscate --split-debug-info=build/app/outputs/symbols
```

- **`--obfuscate`**: Enables code obfuscation.
- **`--split-debug-info`**: Creates a directory with the debug symbols, which are necessary for de-obfuscating crash reports from App Store Connect. **Store this directory in a secure location.**

After the command completes, the output in your terminal will provide the path to the generated `.xcarchive`. You can then use Xcode to upload this archive to App Store Connect.
