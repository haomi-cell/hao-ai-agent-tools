---
name: android-apk-build
description: Use when building an APK, e.g. a WebView app of a site.
version: 1.0.0
author: Haomi sessions
license: MIT
---

# Headless Android APK build (no Android Studio)

## When to Use
The user asks to 'buat apk' — most often a WebView wrapper of their live website.

## Scope check first
- 'buat apk' is ambiguous: clarify WebView-wrapper-of-their-site vs something else, and who installs it (personal vs distributed) before building.

## Setup (once per machine)
```bash
sudo apt-get install -y openjdk-17-jdk-headless unzip   # no Java preinstalled
# Android cmdline-tools + build-tools + platform android-34 (~60s download)
mkdir -p ~/android-sdk/cmdline-tools
cd /tmp && curl -sSL -o ct.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q ct.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=$HOME/android-sdk 'platform-tools' 'platforms;android-34' 'build-tools;34.0.0'
```
No gradle needed — build manually with aapt2/javac/d8/zipalign/apksigner.

## Build procedure (WebView app)
1. Write the project: `AndroidManifest.xml` (package, INTERNET permission, launcher activity), `MainActivity.java` (WebView, JS+DOM storage enabled, WebViewClient/ChromeClient, onBackPressed → goBack), `res/values/strings.xml`, launcher icon.
2. Icon: crop the site's banner image square with PIL, resize 192px → `res/mipmap/ic_launcher.png`.
3. Compile (BT=build-tools dir, PLAT=platforms/android-34/android.jar):
   ```bash
   aapt2 compile --dir app/src/main/res -o build/res.zip
   aapt2 link -o build/base.apk -I $PLAT --manifest app/src/main/AndroidManifest.xml -R build/res.zip --java build/gen --auto-add-overlay
   javac -source 17 -target 17 -classpath $PLAT -d build/classes build/gen/**/R.java app/src/main/java/**/*.java
   d8 --release --lib $PLAT --output build/dex build/classes/**/*.class
   ```
4. Package: copy base.apk, then append `classes.dex` at the APK root — `zip` is NOT installed on this host; use Python `zipfile.ZipFile(apk,'a').write(dex,'classes.dex')` (the entry name MUST be exactly `classes.dex`).
5. Sign: `keytool -genkeypair` a local debug keystore (pass via CLI flags), `zipalign -f 4`, `apksigner sign`, `apksigner verify` — verify output is the success gate before delivering.
6. Deliver as MEDIA: file; expect Play Protect warnings on personal (non-Play) APKs and say so up front.

## Pitfalls
- Generate `build/` dirs before aapt2 link (`--java build/gen` fails on a missing directory).
- Sanity-check the final apk with `unzip -l`: classes.dex must sit at the archive root.