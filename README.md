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

## 4. Project layout

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

## 5. Firestore schema

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

## 6. Role capabilities at a glance

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

## 7. Notes on the multi-date calendar

The reservation flow computes blocked dates **in real time** by intersecting
the selected unit IDs with existing `pending`/`confirmed` bookings for the
venue. Only once the user picks at least one unit do blocked dates appear
(so availability is accurate to the exact chosen unit combination). See
`BookingService.computeBlockedDates` for the exact logic.

## 8. Where to go next

- **Push notifications** on booking status change (FCM + a Cloud Function).
- **Images per unit** stored in Firebase Storage.
- **ICS export** for owners to subscribe to their venue agenda from their
  calendar app.
- **Payments later**: swap "Pay on-site" with Stripe/RevenueCat flow by
  adding a `paymentIntentId` to `bookings`.
