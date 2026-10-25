# HubDine white-label builds

One codebase, one Supabase project, one Firebase project. Each restaurant is a
folder under `config/restaurants/<slug>/`:

| File | Required | Purpose |
|---|---|---|
| `restaurant.json` | yes | `RESTAURANT_ID`, `APP_NAME`, `ANDROID_APPLICATION_ID`, `IOS_BUNDLE_ID`, optional `PAYMENT_REDIRECT_BASE_URL`, `SLUG` |
| `google-services.json` | Android builds | downloaded from Firebase for **this** Android app |
| `GoogleService-Info.plist` | iOS builds | downloaded from Firebase for **this** iOS app |
| `icon.png` | optional | 1024x1024 launcher icon (no transparency for iOS) |

## Build

```
dart run tool/hubdine_build.dart cafe apk
dart run tool/hubdine_build.dart cafe appbundle
dart run tool/hubdine_build.dart cafe ios        # macOS only
dart run tool/hubdine_build.dart cafe run        # run on a connected device
```

Plain `flutter run` (no defines) still builds the original Cafe app.

## Add a restaurant
1. Copy `config/restaurants/cafe` to `config/restaurants/<slug>` and edit `restaurant.json`.
2. Firebase Console (same project): add an Android app (`ANDROID_APPLICATION_ID`) and an iOS app (`IOS_BUNDLE_ID`); download the two config files into the folder.
3. iOS push: upload the APNs key (.p8) once to Firebase; enable Push Notifications for the new Bundle ID in Apple Developer.
4. Build with the command above. The tool refuses to build if the Firebase files don't match the ids.

## Not covered by this tool
- Creating the Firebase apps and Apple/Google Play accounts and signing (release signing is still the debug key in `android/app/build.gradle.kts`).
- Data isolation: RLS in Supabase is what isolates restaurants, not the app's `RESTAURANT_ID`.
- Paymob / Kashier / Fawry are unchanged (`PAYMENT_REDIRECT_BASE_URL` only makes the existing return URL configurable; default = current value).
