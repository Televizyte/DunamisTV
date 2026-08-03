# Dunamis TV (AdMob-compliant) — Play Store Update Scaffold

This zip is a **starter scaffold** for the Dunamis TV Lite rebuild with:
- 4 bottom tabs: Home, Watch, Explore, More
- In-app playback: HLS (m3u8) + YouTube (embedded) + Web links (in-app WebView)
- Notes + Quote Creator (simple v1)
- AdMob wiring with **strict screen gating** (NO ads on replicated-content screens)

## IMPORTANT (Play Store update safety)

These are the **only** values that matter for uploading as an **UPDATE** (not a new app):

- **Application ID (Android package):** `com.digitxtramedia.dunamistv`
- **App Name (display):** `Dunamis TV`
- **VersionName / VersionCode:** `3.46.0.12 (13)` → Flutter version format in this project is `3.46.0.12+13`

The ZIP/folder name does **not** affect Play Store.

## Quick start (Windows / macOS / Linux)

1) Install Flutter (stable) and Android Studio.
2) In this project folder, run:

```bash
flutter pub get
flutter run
```

> If you get a platform-folder error (because this is a lightweight scaffold), run:
```bash
flutter create --org com.digitxtramedia .
flutter pub get
flutter run
```

## Important policy note (why ads are gated)
Ads are **disabled** on any screens that show embedded/replicated content (YouTube playlists, WebView pages, iframe channels, etc.).  
Ads are only enabled on **original content / tool screens** (Home, Inside Dunamis articles list/detail, SOD Key Points, SOD Quotes, Notes, Quote Creator).

## Configure your real AdMob IDs
Edit: `lib/app_config.dart`

- Keep `useTestAds = true` while testing.
- Replace with your real unit IDs before release.

## Configure your content / URLs
Edit: `lib/content/links.dart`


### Android package + app name

After `flutter create --org com.digitxtramedia .`, confirm the Android applicationId is:

- `android/app/build.gradle` → `applicationId "com.digitxtramedia.dunamistv"`

If Flutter generated a different id, edit it back to `com.digitxtramedia.dunamistv` before building the AAB.

Set the display name to **Dunamis TV** in:

- `android/app/src/main/res/values/strings.xml` → `<string name="app_name">Dunamis TV</string>`

