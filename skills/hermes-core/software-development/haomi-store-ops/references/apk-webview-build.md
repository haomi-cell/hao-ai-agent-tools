# WebView APK build (no Android Studio, no gradle)

Build a signed APK that opens the store URL in a WebView — works on the server with only Java 17 + Android build-tools.

## Setup (once)
```
sudo apt-get install -y openjdk-17-jdk-headless unzip
mkdir -p ~/android-sdk/cmdline-tools
curl -sSL -o /tmp/cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q /tmp/cmdtools.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=$HOME/android-sdk 'platform-tools' 'platforms;android-34' 'build-tools;34.0.0'
```

## Project layout (minimal)
- `AndroidManifest.xml` — package, INTERNET permission, one exported activity, `Theme.NoTitleBar`, label + mipmap icon.
- `MainActivity.java` — WebView, JS + DOM storage enabled, `WebViewClient`/`WebChromeClient`, black background, `onBackPressed` → `web.goBack()`.
- `res/values/strings.xml`, `res/mipmap/ic_launcher.png` (make with PIL from the repo banner, center-crop square, resize 192).

## Build by hand (no gradle needed)
```
BT=~/android-sdk/build-tools/34.0.0; PLAT=~/android-sdk/platforms/android-34/android.jar
aapt2 compile --dir res -o build/res.zip
aapt2 link -o build/base.apk -I $PLAT --manifest AndroidManifest.xml -R build/res.zip --java build/gen --auto-add-overlay
javac -source 17 -target 17 -classpath $PLAT -d build/classes build/gen/**/R.java **/*.java
d8 --release --lib $PLAT --output build/dex build/classes/**/*.class
```
- `zip` binary may be absent — append `classes.dex` (MUST be named `classes.dex` at APK root) with Python `zipfile.ZipFile(base, 'a')` instead.
- Then `zipalign -f 4`, generate a keystore with `keytool`, sign with `apksigner sign`, verify with `apksigner verify` → `BUILD_OK`.

Result: ~60 KB APK. Note for the user: sideloaded APKs trigger a Play Protect warning — normal.