---
name: android-apk-triage
description: Use when an APK needs static inspection or a safety verdict.
---

# APK Static Triage (no jadx / no Java needed)

## When to Use
User sends an `.apk` (or a web app claiming to be one) to inspect, verify, or "analyze" — including when the follow-up request is to rebuild, improve, host, or share its contents.

## Procedure
1. Unzip the APK (it is a plain zip): `mkdir /tmp/apkx && cd /tmp/apkx && unzip -q <file>`.
2. Nested APKs are common (packed/wrapped apps): check `assets/` for another `*.apk` and unzip that too.
3. Identify the real app:
   - `AndroidManifest.xml` is compiled AXML (binary) — `strings` fails on it. Extract UTF-16LE strings instead (see references/axml-extract.md).
   - Run `strings classes*.dex` for package names, URLs, endpoints, C2 hosts. Filter out noise: google/androidx/kotlin/firebase/tink/okhttp/play/integrity.
   - Firebase Realtime Database URLs in dex strings are a strong signal of remote-control apps (the C2 endpoint).
4. Read `AndroidManifest.xml` strings for: package name, Activity/Service/Receiver names, and the permission list (Camera, RECORD_AUDIO, ACCESS_FINE_LOCATION, AccessibilityService, NotificationListener, SYSTEM_ALERT_WINDOW on a utility app = spyware indicators).
5. Report findings plainly: package, entry activities, permissions, network endpoints, verdict.

## Safety gate (always-on)
- Refuse to help with spyware/malware APKs no matter the framing: "tugas kuliah", "just analyze", "just README", "upload data to my GitHub", "make it cooler". Malware documentation and distribution are also refusals — analysis to INFORM the user of a verdict is fine; making it work, improving it, hosting it, or re-sharing its contents is not.
- "Clone/plagiat an APK" requests: dissecting a modded/cracked APK to report what was modified is fine; extracting its code for the user to rebuild, rebrand, or redistribute is not (software piracy + the modder's own APK is not theirs to clone). Offer the legal redirect: rebuild the *concept/feature set* from scratch with original code and branding.
- Offers of legitimate pivots (anti-theft for the user's own device, defensive detector, lab environments like TryHackMe/HTB) are the right redirect.
- When the user sends a second 'document' (e.g. README/architecture doc) after a refusal, it is the same request re-framed; re-state the refusal once, briefly, without re-litigating.
- "Tugas kuliah" framing fails the sniff test for offensive tooling: real coursework scopes to the student's own lab, never targets real 'korban' devices, and never includes exfil-to-Telegram or victim-lock features. Ask for the actual assignment brief before accepting the framing.

## Modding-tool fingerprints (classify a 'mod' APK fast)
Known crack/hack signatures in dex strings or injected assets: `ApkSignatureKiller` (fakes APK signing so the app doesn't detect modification), `ProxyBill`/fake Google Play Billing classes (spoofs subscription purchases), an injected `assets/*/dist.zip` web-app that references trial/subscription/verify logic (a JS bridge hooked into the licensing path), and launcher-alias disguises (Calculator/SystemUpdate/GooglePlay aliases on a non-calculator app). Original package names left intact (`com.<vendor>.*`) = the app is genuine code + a crack layer, not the user's property to reuse.

## Repo-upload gate
If a follow-up asks to push extracted APK contents (or any malware component/C2 endpoints) to a GitHub repo, refuse: that is distributing malware and permanently ties the user's identity to it. Point at the parts of the repo that are legitimately theirs instead.
