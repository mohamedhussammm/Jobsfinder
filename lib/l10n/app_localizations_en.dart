// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchHint => 'Search events, venues, or roles';

  @override
  String get curatedListings => 'CURATED LISTINGS';

  @override
  String get trendingNearYou => 'Trending Near You';

  @override
  String get seeAll => 'See all';

  @override
  String get availableShifts => 'Available Shifts';

  @override
  String get noShiftsAvailable => 'No shifts available';

  @override
  String get allCategories => 'All Categories';

  @override
  String spots(int count) {
    return '$count spots';
  }

  @override
  String get open => 'Open';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get date => 'Date';

  @override
  String get shift => 'Shift';

  @override
  String get capacity => 'Capacity';

  @override
  String get description => 'Description';

  @override
  String get requirements => 'Requirements';

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
  String get myProfile => 'My Profile';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get recentReviews => 'Recent Reviews';

  @override
  String get viewAll => 'View All';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get showLess => 'Show Less';

  @override
  String get readMore => 'Read More';

  @override
  String get location => 'Location';

  @override
  String get tryAdjustingSearch =>
      'Try adjusting your search to find what you\'re looking for.';

  @override
  String get highPay => 'High Pay';

  @override
  String get instantBook => 'Instant Book';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get aboutTheRole => 'About the Role';
}
