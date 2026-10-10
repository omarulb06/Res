import 'package:flutter/widgets.dart';

/// App-wide i18n table.
///
/// Not using the full `.arb` / `gen_l10n` pipeline because the string count is
/// moderate and keeping all three languages in one Dart file is easier to
/// scan + edit for a demo. For a production app with ~500+ strings or
/// multiple contributors, migrate to ARB files + `flutter gen-l10n`.
///
/// Access via `S.of(context).discoverVenues`.
///
/// Hebrew (he) and Arabic (ar) are right-to-left; Flutter handles layout
/// mirroring automatically via `Directionality` when `MaterialApp.locale`
/// is set to those languages (see `app.dart`).

enum AppLocale { en, he, ar }

extension AppLocaleX on AppLocale {
  String get code => switch (this) {
        AppLocale.en => 'en',
        AppLocale.he => 'he',
        AppLocale.ar => 'ar',
      };

  String get flag => switch (this) {
        AppLocale.en => '🇺🇸',
        AppLocale.he => '🇮🇱',
        AppLocale.ar => '🇸🇦',
      };

  String get nativeName => switch (this) {
        AppLocale.en => 'English',
        AppLocale.he => 'עברית',
        AppLocale.ar => 'العربية',
      };

  Locale get locale => Locale(code);

  static AppLocale parse(String? code) {
    switch (code) {
      case 'he':
        return AppLocale.he;
      case 'ar':
        return AppLocale.ar;
      default:
        return AppLocale.en;
    }
  }
}

class S {
  final AppLocale locale;
  const S(this.locale);

  static S of(BuildContext ctx) {
    final code = Localizations.localeOf(ctx).languageCode;
    return S(AppLocaleX.parse(code));
  }

  String _t(String en, String he, String ar) => switch (locale) {
        AppLocale.en => en,
        AppLocale.he => he,
        AppLocale.ar => ar,
      };

  // --- Common ---------------------------------------------------------------
  String get appName => _t('Venue Reservation', 'הזמנת אולמות', 'حجز قاعات');
  String get ok => _t('OK', 'אישור', 'موافق');
  String get cancel => _t('Cancel', 'ביטול', 'إلغاء');
  String get save => _t('Save', 'שמור', 'حفظ');
  String get delete => _t('Delete', 'מחק', 'حذف');
  String get edit => _t('Edit', 'ערוך', 'تعديل');
  String get retry => _t('Retry', 'נסה שוב', 'إعادة المحاولة');
  String get loading => _t('Loading…', 'טוען…', 'جار التحميل…');
  String get required => _t('Required', 'שדה חובה', 'مطلوب');
  String get or => _t('or', 'או', 'أو');
  String get done => _t('Done', 'סיום', 'تم');

  // --- Discover screen ------------------------------------------------------
  String get discoverVenues => _t('Discover Venues', 'גלה אולמות', 'اكتشف القاعات');
  String get searchHint => _t(
      'Search venues or locations…',
      'חפש אולמות או מקומות…',
      'ابحث عن قاعات أو أماكن…');
  String get signIn => _t('Sign in', 'התחברות', 'تسجيل الدخول');
  String get signOut => _t('Sign out', 'יציאה', 'تسجيل الخروج');
  String get signedInAs => _t('Signed in as', 'מחובר בתור', 'مسجّل الدخول باسم');
  String get anyCapacity => _t('Any capacity', 'כל קיבולת', 'أي سعة');
  String get capacityAtLeast =>
      _t('Capacity ≥', 'קיבולת ≥', 'سعة ≥');
  String get minCapacity =>
      _t('Minimum capacity', 'קיבולת מינימלית', 'الحد الأدنى للسعة');
  String get any => _t('Any', 'הכל', 'الكل');
  String get clear => _t('Clear', 'נקה', 'مسح');
  String get apply => _t('Apply', 'החל', 'تطبيق');
  String get guests => _t('guests', 'אורחים', 'ضيوف');
  String get noVenuesMatch =>
      _t('No venues match', 'לא נמצאו אולמות', 'لا توجد قاعات مطابقة');
  String get noVenuesMatchHint => _t(
      'Try clearing filters or searching for a different name or location.',
      'נסה לנקות סינונים או לחפש שם או מקום אחר.',
      'جرّب مسح عوامل التصفية أو البحث باسم أو مكان آخر.');
  String get loadingVenues =>
      _t('Loading venues…', 'טוען אולמות…', 'جار تحميل القاعات…');
  String get failedToLoadVenues => _t(
      'Failed to load venues',
      'טעינת האולמות נכשלה',
      'فشل تحميل القاعات');

  // Categories
  String get categoryIndoor => _t('Indoor', 'מקום סגור', 'داخلي');
  String get categoryOutdoor => _t('Outdoor', 'מקום פתוח', 'خارجي');
  String get categoryMixed =>
      _t('Indoor + Outdoor', 'משולב', 'داخلي + خارجي');

  // --- Private venue PIN ----------------------------------------------------
  String get privateVenue =>
      _t('Private Venue', 'אולם פרטי', 'قاعة خاصة');
  String get privateVenueDescription =>
      _t(
          'is protected. Enter the 4–6 digit access code shared by the owner.',
          'מוגן. הזן את קוד הגישה (4-6 ספרות) שסופק על ידי בעל המקום.',
          'محمي. أدخل رمز الوصول المكوّن من 4-6 أرقام الذي شاركه المالك.');
  String get unlock => _t('Unlock', 'פתח', 'فتح');
  String get incorrectCode => _t(
      'Incorrect code. Please try again.',
      'קוד שגוי. נסה שוב.',
      'الرمز غير صحيح. حاول مرة أخرى.');
  String get enterPinLength => _t(
      'Enter a 4–6 digit access code.',
      'הזן קוד גישה בן 4-6 ספרות.',
      'أدخل رمز وصول من 4-6 أرقام.');

  // Venue badges
  String get badgePin => _t('PIN', 'קוד', 'رمز');
  String get badgePendingReview =>
      _t('Pending review', 'ממתין לאישור', 'بانتظار المراجعة');
  String get badgePublic => _t('Public', 'ציבורי', 'عام');
  String get badgePrivate => _t('Private', 'פרטי', 'خاص');

  // --- Venue detail screen --------------------------------------------------
  String get aboutThisVenue =>
      _t('About this venue', 'אודות המקום', 'عن هذه القاعة');
  String get availableUnits =>
      _t('Available Units', 'יחידות זמינות', 'الوحدات المتاحة');
  String get upToGuests =>
      _t('Up to', 'עד', 'حتى');
  String get fromPerDay =>
      _t('From', 'החל מ-', 'من');
  String perDay(Object price) =>
      _t('\$$price/day', '₪$price/יום', '\$$price/يوم');
  String capacityValue(Object n) =>
      _t('Capacity: $n guests', 'קיבולת: $n אורחים', 'السعة: $n ضيفًا');
  String get reserveDates =>
      _t('Reserve dates', 'הזמן תאריכים', 'احجز التواريخ');
  String get venueNotFound =>
      _t('Venue not found', 'האולם לא נמצא', 'لم يتم العثور على القاعة');
  String get venueNotFoundHint => _t(
      'This listing may have been removed by its owner.',
      'הרשומה הזו ייתכן שהוסרה על ידי בעל המקום.',
      'ربما تمت إزالة هذا الإعلان من قبل مالكه.');

  // --- Reservation wizard ---------------------------------------------------
  String get stepPickUnits => _t(
      'Pick unit(s) to reserve',
      'בחר יחידות להזמנה',
      'اختر الوحدات للحجز');
  String get stepPickUnitsHint => _t(
      'You can book several units together (e.g. Indoor Hall + Garden).',
      'ניתן להזמין מספר יחידות יחד (למשל אולם פנימי + גן).',
      'يمكنك حجز عدة وحدات معًا (مثل القاعة الداخلية + الحديقة).');
  String get stepPickDates => _t('Select dates', 'בחר תאריכים', 'اختر التواريخ');
  String get stepPickDatesHintPickUnits => _t(
      'Pick units above to see live availability.',
      'בחר יחידות למעלה כדי לראות זמינות בזמן אמת.',
      'اختر الوحدات أعلاه لرؤية التوافر مباشرة.');
  String get stepPickDatesHintTap => _t(
      'Tap each date you want. Non-consecutive dates allowed.',
      'הקש על כל תאריך רצוי. ניתן לבחור תאריכים לא רצופים.',
      'انقر على كل تاريخ تريده. يُسمح بتواريخ غير متتالية.');
  String get stepContactDetails =>
      _t('Your contact details', 'פרטי קשר', 'بيانات التواصل');
  String get stepContactDetailsHint => _t(
      'The owner will use this to confirm your reservation.',
      'בעל המקום ישתמש בפרטים אלה כדי לאשר את ההזמנה.',
      'سيستخدم المالك هذه البيانات لتأكيد حجزك.');
  String get fullName => _t('Full name', 'שם מלא', 'الاسم الكامل');
  String get phone => _t('Phone', 'טלפון', 'الهاتف');
  String get email => _t('Email', 'אימייל', 'البريد الإلكتروني');
  String get password => _t('Password', 'סיסמה', 'كلمة المرور');
  String get yourName =>
      _t('Your name', 'השם שלך', 'اسمك');
  String get invalidPhone => _t('Invalid phone', 'טלפון לא תקין', 'هاتف غير صالح');
  String get invalidEmail => _t('Invalid email', 'אימייל לא תקין', 'بريد غير صالح');
  String get min6chars => _t(
      'Minimum 6 characters', 'מינימום 6 תווים', '6 أحرف على الأقل');
  String get reservationSummary => _t(
      'Reservation summary', 'סיכום הזמנה', 'ملخص الحجز');
  String reservationSummaryLine(Object units, Object days) => _t(
      '$units unit(s) · $days day(s) · Pay on-site',
      '$units יחידות · $days ימים · תשלום במקום',
      '$units وحدة · $days يوم · الدفع في الموقع');
  String get confirmReservation => _t(
      'Confirm reservation (Pay on-site)',
      'אשר הזמנה (תשלום במקום)',
      'تأكيد الحجز (الدفع في الموقع)');
  String get pickAtLeastOneUnit => _t(
      'Pick at least one unit to reserve.',
      'בחר לפחות יחידה אחת להזמנה.',
      'اختر وحدة واحدة على الأقل للحجز.');
  String get pickAtLeastOneDate => _t(
      'Pick at least one date.',
      'בחר לפחות תאריך אחד.',
      'اختر تاريخًا واحدًا على الأقل.');
  String get reservationSubmitted => _t(
      'Reservation submitted!',
      'ההזמנה נשלחה!',
      'تم إرسال الحجز!');
  String reservationSubmittedDetail(Object days) => _t(
      'Your booking for $days day(s) is marked as "Pending Payment". The venue owner will confirm and collect payment on arrival.',
      'ההזמנה שלך ל-$days ימים מסומנת כ"ממתינה לתשלום". בעל המקום יאשר ויגבה תשלום בהגעה.',
      'تم تحديد حجزك لمدة $days يوم كـ "بانتظار الدفع". سيؤكد مالك القاعة ويحصّل الدفع عند الوصول.');
  String get failedToSubmit => _t(
      'Failed to submit', 'השליחה נכשלה', 'فشل الإرسال');

  // Calendar legend
  String get legendSelected => _t('Selected', 'נבחר', 'محدد');
  String get legendUnavailable =>
      _t('Unavailable', 'לא זמין', 'غير متاح');
  String get legendAvailable => _t('Available', 'זמין', 'متاح');

  // --- Login / Signup -------------------------------------------------------
  String get welcomeBack => _t('Welcome back', 'ברוך שובך', 'مرحبًا بعودتك');
  String get welcomeBackSubtitle => _t(
      'Sign in as a Venue Owner or Admin.',
      'התחבר כבעל אולם או מנהל.',
      'سجّل الدخول كمالك قاعة أو مسؤول.');
  String get continueWithGoogle => _t(
      'Continue with Google',
      'המשך עם Google',
      'المتابعة باستخدام Google');
  String get noAccount => _t(
      "Don't have an account? Create one",
      'אין לך חשבון? צור חשבון',
      'ليس لديك حساب؟ أنشئ حسابًا');
  String get createAccount => _t(
      'Create account', 'יצירת חשבון', 'إنشاء حساب');
  String get signupInfo => _t(
      'New accounts start as Clients. Ask an admin to promote you to Owner (venue manager) or Admin from the in-app Users panel.',
      'חשבונות חדשים מתחילים כלקוחות. בקש ממנהל לקדם אותך לבעל אולם או מנהל מתוך פאנל המשתמשים באפליקציה.',
      'تبدأ الحسابات الجديدة كعملاء. اطلب من المسؤول ترقيتك إلى مالك قاعة أو مسؤول من لوحة المستخدمين داخل التطبيق.');

  // --- Settings sheet -------------------------------------------------------
  String get settings => _t('Settings', 'הגדרות', 'الإعدادات');
  String get theme => _t('Theme', 'ערכת נושא', 'المظهر');
  String get themeLight => _t('Light', 'בהיר', 'فاتح');
  String get themeDark => _t('Dark', 'כהה', 'داكن');
  String get themeSystem => _t('System', 'מערכת', 'النظام');
  String get language => _t('Language', 'שפה', 'اللغة');

  // --- Owner / Admin (shorter coverage — these are admin tools, mostly English)
  String get myVenues => _t('My Venues', 'האולמות שלי', 'قاعاتي');
  String get bookings => _t('Bookings', 'הזמנות', 'الحجوزات');
  String get agenda => _t('Agenda', 'יומן', 'الأجندة');
  String get newVenue => _t('New venue', 'אולם חדש', 'قاعة جديدة');
  String get noVenuesYet =>
      _t('No venues yet', 'עדיין אין אולמות', 'لا توجد قاعات بعد');
  String get noBookingsYet =>
      _t('No bookings yet', 'עדיין אין הזמנות', 'لا توجد حجوزات بعد');
  String get browseAsClient =>
      _t('Browse as client', 'עיין כלקוח', 'تصفح كعميل');
  String get confirm => _t('Confirm', 'אשר', 'تأكيد');
  String get reject => _t('Reject', 'דחה', 'رفض');
  String get statusPending => _t('Pending Payment', 'ממתין לתשלום', 'بانتظار الدفع');
  String get statusConfirmed => _t('Confirmed', 'מאושר', 'مؤكد');
  String get statusCancelled => _t('Cancelled', 'בוטל', 'ملغى');
}
