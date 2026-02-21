// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get searchHint => 'ابحث عن الأحداث أو الأماكن أو الأدوار';

  @override
  String get curatedListings => 'قوائم مختارة';

  @override
  String get trendingNearYou => 'شائع بالقرب منك';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get availableShifts => 'المناوبات المتاحة';

  @override
  String get noShiftsAvailable => 'لا توجد مناوبات متاحة';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String spots(int count) {
    return '$count أماكن';
  }

  @override
  String get open => 'مفتوح';

  @override
  String get applyNow => 'قدم الآن';

  @override
  String get eventDetails => 'تفاصيل الحدث';

  @override
  String get date => 'التاريخ';

  @override
  String get shift => 'المناوبة';

  @override
  String get capacity => 'السعة';

  @override
  String get description => 'الوصف';

  @override
  String get requirements => 'المتطلبات';

  @override
  String get validIdRequired => 'Valid ID Required';

  @override
  String get professionalAttire => 'Professional Attire';

  @override
  String get experiencePreferred => 'Experience Preferred';

  @override
  String get searchEvents => 'Search Events';

  @override
  String get noEventsFound => 'No events found';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get language => 'اللغة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get recentReviews => 'المراجعات الأخيرة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get location => 'الموقع';

  @override
  String get tryAdjustingSearch => 'حاول تعديل بحثك للعثور على ما تبحث عنه.';

  @override
  String get highPay => 'أجر مرتفع';

  @override
  String get instantBook => 'حجز فوري';

  @override
  String get upcoming => 'قادم';

  @override
  String get aboutTheRole => 'عن الدور';
}
