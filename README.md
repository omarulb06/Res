# Venue Reservation — Flutter + Cloud Firestore

A production-shaped event venue daily reservation app with strict role-based
access (Client / Owner / Admin), multi-date non-consecutive booking,
private-venue PIN gating, and pay-on-site reservations.

> The app boots in **mock-data mode** automatically if Firebase isn't
> configured yet, so you can run `flutter run` immediately after `flutter
> pub get`. Hook up Firebase whenever you're ready.

---

## 1. Prerequisites

- Flutter SDK **3.19+** (Dart 3.3+)
- Android Studio or VS Code with the Flutter plugin
- (Optional, for real backend) A Firebase project with Firestore + Email/Password Auth enabled

Check your install:

```bash
flutter doctor
```

## 2. First run (mock mode — no backend needed)

```bash
flutter pub get
flutter run
```

- Guests land on the **Discover** screen and can browse approved venues.
- Tap the **Sign in** button in the AppBar; three one-click demo accounts
  are available: `admin@demo.app`, `owner@demo.app`, `client@demo.app`
  (any password works in mock mode).
- Try the private venue **Skyline Rooftop** — PIN is `2468`.

## 3. Wiring up real Firebase (optional)

1. Install the FlutterFire CLI once:

   ```bash
   dart pub global activate flutterfire_cli
   ```

2. From the project root, generate `lib/firebase_options.dart`:

   ```bash
   flutterfire configure
   ```

   (Pick your Firebase project and target Android/iOS platforms.)

3. In the Firebase console enable:

   - **Authentication → Sign-in method → Email/Password**
   - **Firestore Database** (start in production mode)

4. Deploy the security rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

   (The rules live in [`firestore.rules`](./firestore.rules) at the repo root.)

5. Create your first **admin** manually in the Firebase console by editing
   the `/users/{uid}` document (after signing up through the app) and setting
   `role: "admin"`. From then on, that admin can promote/demote others
   from the in-app **Admin → Users** tab.

6. Run the app again:

   ```bash
   flutter run
   ```

   On successful init you'll see `[boot] Firebase initialized -> using
   Cloud Firestore` in the console and the mock fallback is skipped.

## 4. Building the iOS app (requires macOS + Xcode)

> ⚠️ **iOS builds can only be produced on macOS** — Apple's codesign + Xcode
> toolchain is Mac-only. Windows and Linux cannot build iOS binaries, even
> for the Simulator. The commands below assume you are sitting at a Mac
> (local, lab, or a Mac-in-the-cloud service like MacStadium / MacInCloud).

### 4.1 One-time Mac setup

```bash
# 1. Install Xcode from the Mac App Store (~15 GB), then:
sudo xcode-select --install
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch

# 2. Install CocoaPods — pulls native Firebase / Google Sign-In pods.
sudo gem install cocoapods

# 3. Install Flutter 3.24.5 (same channel this project was built on).
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
flutter --version          # should print 3.24.x
flutter doctor             # all "iOS toolchain" lines must be green ✓
```

### 4.2 Get the project onto the Mac

Pick whichever is easiest for you:

| Method | How |
|---|---|
| **Git clone** (cleanest for repeat builds) | `git clone <your-remote> ~/Res` |
| **Zip + copy** (one-off) | On Windows: `Compress-Archive -Path C:\Res\* -DestinationPath C:\Res\res-src.zip -Exclude 'build','.dart_tool','.gradle','*.apk','firebase-tools'`<br>On Mac: `unzip ~/Downloads/res-src.zip -d ~/Res` |
| **OneDrive / iCloud** | Sync the `C:\Res` folder to the Mac |

### 4.3 Register iOS as a Firebase app (first time only)

The current `lib/firebase_options.dart` only has Android credentials. To use
real Firebase on iOS you must register the iOS bundle in your Firebase
project and regenerate the config:

```bash
cd ~/Res
dart pub global activate flutterfire_cli
flutterfire configure --project=resapp-4e5b2 --platforms=ios,android
# This writes ios/Runner/GoogleService-Info.plist and updates
# lib/firebase_options.dart with the iOS entries.
```

Then, in Xcode, make sure the generated `GoogleService-Info.plist` is
listed under **Runner > Build Phases > Copy Bundle Resources**
(FlutterFire usually does this automatically).

If you don't need Firebase on iOS right away, the app will fall back to
mock-data mode automatically — skip this step.

### 4.4 Install dependencies

```bash
cd ~/Res
flutter pub get
cd ios && pod install && cd ..
```

> **M1/M2/M3 Mac?** If `pod install` fails with ffi / arch errors:
> ```bash
> sudo arch -x86_64 gem install ffi
> arch -x86_64 pod install
> ```

### 4.5 Pick a build target

#### A — Run on the iOS Simulator (fastest, no Apple account needed)

```bash
open -a Simulator           # launch any simulator
flutter run                 # auto-targets the running simulator
```

Hot reload works just like Android.

#### B — Run on your own iPhone (free Apple ID, 7-day signing)

1. Plug the iPhone in via USB, tap **Trust** on the phone.
2. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace    # NOT the .xcodeproj
   ```
3. In Xcode:
   - Select the **Runner** target → **Signing & Capabilities**.
   - Check **Automatically manage signing**.
   - **Team** → *Add an Account…* → sign in with your Apple ID (free is fine).
   - Change **Bundle Identifier** to something unique, e.g.
     `com.yourname.venuereservation` (the default `com.example.*` will be
     rejected by Apple's provisioning).
4. Pick your iPhone from the device dropdown and press ▶ Play — or from
   the terminal:
   ```bash
   flutter run --release
   ```
5. First launch on the phone: **Settings → General → VPN & Device
   Management → Trust** the developer certificate.

> ⏱ Free Apple ID signed apps expire every **7 days** and are capped at
> 3 self-signed apps. Fine for personal use; use the paid program below
> for TestFlight distribution.

#### C — Build an `.ipa` for TestFlight / App Store ($99/yr Apple Developer Program required)

```bash
# Build a release .ipa
flutter build ipa --release
# Output: build/ios/ipa/*.ipa

# Upload to App Store Connect (TestFlight + App Store)
xcrun altool --upload-app \
  -f build/ios/ipa/Runner.ipa \
  -t ios \
  -u YOUR_APPLE_ID \
  -p APP_SPECIFIC_PASSWORD
```

Generate an **app-specific password** at
<https://appleid.apple.com/account/manage> → Sign-In and Security →
App-Specific Passwords (don't use your real Apple ID password).

Alternatively open `build/ios/archive/Runner.xcarchive` in Xcode and use
the **Organizer** window → *Distribute App* for a GUI flow.

#### D — Unsigned `.app` for a running simulator (dropdown-install, no device/account)

```bash
flutter build ios --simulator
# Output: build/ios/iphonesimulator/Runner.app
# Drag the Runner.app onto a running simulator window to install.
```

### 4.6 Google Sign-In — one extra iOS step

If you want the "Continue with Google" button to work on iOS, add this
block to `ios/Runner/Info.plist` (just before the closing `</dict>`),
replacing `REVERSED_CLIENT_ID` with the value from
`GoogleService-Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 4.7 Common iOS build errors

| Error | Fix |
|---|---|
| `No profiles for 'com.example.res' were found` | Change the bundle ID in Xcode to something unique (`com.yourname.venuereservation`) |
| `GoogleService-Info.plist not found` | Re-run `flutterfire configure --platforms=ios` and ensure the file is in `ios/Runner/` + added to the Runner target in Xcode |
| `CocoaPods could not find compatible versions` | `cd ios && pod repo update && pod install` |
| `ffi` native errors on Apple Silicon | `arch -x86_64 pod install` (see §4.4) |
| App launches then crashes immediately with Google Sign-In | You skipped §4.6 — add the URL scheme to Info.plist |
| White screen forever on first launch | Open Console.app, filter by the device — usually a missing `GoogleService-Info.plist` or wrong bundle ID |

### 4.8 Minimum iOS version

The project targets **iOS 12.0+** by default (set in `ios/Podfile`). If
you need a newer floor (e.g. for a package that requires iOS 13), edit:

```ruby
# ios/Podfile
platform :ios, '13.0'
```

Then run `cd ios && pod install` again.

## 5. Project layout

```
lib/
├── main.dart                  # Firebase init + mock fallback
├── app.dart                   # MaterialApp + MultiProvider
├── firebase_options.dart      # Stub — replace with flutterfire output
├── theme/app_theme.dart       # Material 3 theme (Inter font)
├── models/                    # AppUser, Venue, VenueUnit, Booking
├── services/
│   ├── app_config.dart        # Runtime flags (useMockData)
│   ├── mock_backend.dart      # In-memory seed data for demo mode
│   ├── auth_service.dart      # Firebase Auth + /users CRUD
│   ├── venue_service.dart     # /venues CRUD + streams
│   └── booking_service.dart   # /bookings CRUD + availability math
├── providers/                 # Provider ChangeNotifiers
├── widgets/
│   ├── venue_card.dart        # Grid tile
│   ├── multi_date_calendar.dart  # Non-consecutive date picker
│   ├── pin_dialog.dart        # 4–6 digit PIN gate
│   └── state_views.dart       # Loading / Empty / Error reusables
└── screens/
    ├── splash_screen.dart     # Routes by auth + role
    ├── auth/                  # Login + Signup
    ├── client/                # Discover · VenueDetail · Reservation
    ├── owner/                 # Dashboard · VenueEdit · AgendaCalendar
    └── admin/                 # Overview · Approvals · Users
firestore.rules                # Deployable security rules (RBAC)
```

## 6. Firestore schema

```jsonc
users/{uid} = {
  uid, email, displayName,
  role: "admin" | "owner" | "client",
  createdAt, suspended
}

venues/{venueId} = {
  id, ownerId, title, description, location, imageUrl,
  isPublic, accessCode?,       // 4–6 digit PIN when !isPublic
  isApprovedByAdmin,           // Admin gate before clients can see it
  category: "indoor" | "outdoor" | "mixed",
  units: [
    { unitId, name, capacity, pricePerDay },
    ...
  ]
}

bookings/{bookingId} = {
  id, venueId,
  unitIds: ["u1", "u2"],       // Multi-unit support
  dates:   ["2026-10-10", "2026-10-12", "2026-10-15"], // non-consecutive OK
  clientName, clientPhone, clientEmail,
  status: "pending" | "confirmed" | "cancelled",
  totalPrice, createdAt
}
```

## 7. Role capabilities at a glance

| Capability                                  | Guest | Client | Owner | Admin |
|---------------------------------------------|:-----:|:------:|:-----:|:-----:|
| Browse public approved venues               |  ✅   |   ✅   |  ✅   |  ✅   |
| Unlock private venues with PIN              |  ✅   |   ✅   |  ✅   |  ✅   |
| Submit multi-date pay-on-site reservation   |  ✅   |   ✅   |  ✅   |  ✅   |
| Create & edit own venues/units              |       |        |  ✅   |  ✅   |
| Set venue visibility + access code          |       |        |  ✅   |  ✅   |
| Approve/reject incoming bookings            |       |        |  ✅   |  ✅   |
| Approve/suspend venue listings              |       |        |       |  ✅   |
| Promote/demote users & suspend accounts     |       |        |       |  ✅   |
| View platform-wide metrics                  |       |        |       |  ✅   |

## 8. Notes on the multi-date calendar

The reservation flow computes blocked dates **in real time** by intersecting
the selected unit IDs with existing `pending`/`confirmed` bookings for the
venue. Only once the user picks at least one unit do blocked dates appear
(so availability is accurate to the exact chosen unit combination). See
`BookingService.computeBlockedDates` for the exact logic.

## 9. Where to go next

- **Push notifications** on booking status change (FCM + a Cloud Function).
- **Images per unit** stored in Firebase Storage.
- **ICS export** for owners to subscribe to their venue agenda from their
  calendar app.
- **Payments later**: swap "Pay on-site" with Stripe/RevenueCat flow by
  adding a `paymentIntentId` to `bookings`.
