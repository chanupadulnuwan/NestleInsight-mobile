import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalizationService extends ChangeNotifier {
  LocalizationService._internal();
  static final LocalizationService instance = LocalizationService._internal();

  static const String _languageKey = 'nestle_insight_language';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _currentLocale = 'en';
  bool _isInitialized = false;

  String get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'settings_desc': 'Manage settings and security for your account.',
      'insights': 'Insights',
      'insights_desc': "View your shop's sales performance chart and top trending products.",
      'security': 'Security',
      'security_desc': 'Change your password by entering the current password and the new password twice.',
      'feedback': 'Feedback',
      'feedback_desc': 'Share product feedback, service notes, or quick shop updates from Settings.',
      'language_settings': 'Language Settings',
      'language_settings_desc': 'Choose your preferred language for the application.',
      'account': 'Account',
      'select_language': 'Select Language',
      'english': 'English',
      'sinhala': 'Sinhala (සිංහල)',
      'tamil': 'Tamil (தமிழ்)',
      'cancel': 'Cancel',
      'save': 'Save',
      'close': 'Close',
      'home': 'Home',
      'orders': 'Orders',
      'activity': 'Activity',
      'language_changed_msg': 'Language successfully updated to English.',
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'search_nestle_products': 'Search Nestle products...',
      'nestle_products': 'Nestle Products',
      'see_all': 'See all',
      'add_to_cart': 'Add to Cart',
      'proceed_order': 'Proceed the order',
      'view_deals': 'View Deals',
      'promotions': 'Promotions',
      'no_active_deals': 'No active deals right now.',
      'fetching_deals': 'Fetching deals...',
      'shop_insights': 'Shop Insights',
      'performance_summary': 'Performance Summary',
      'sales_performance': 'Sales Performance',
      'top_trending_products': 'Top Trending Products',
      'revenue': 'Revenue',
      'cases_sold': 'Cases Sold',
      'active_skus': 'Active SKUs',
      'vs_previous': 'Vs Previous',
    },
    'si': {
      'settings': 'සැකසුම්',
      'settings_desc': 'ඔබගේ ගිණුමේ සැකසුම් සහ ආරක්ෂාව මෙතැනින් කළමනාකරණය කරන්න.',
      'insights': 'තීක්ෂ්ණ බුද්ධිය (Insights)',
      'insights_desc': 'ඔබගේ වෙළඳසැලේ විකුණුම් කාර්ය සාධන ප්‍රස්ථාරය සහ ඉහළම ප්‍රවණතා නිෂ්පාදන බලන්න.',
      'security': 'ආරක්ෂාව (Security)',
      'security_desc': 'වත්මන් මුරපදය සහ නව මුරපදය දෙවරක් ඇතුළත් කිරීමෙන් ඔබගේ මුරපදය වෙනස් කරන්න.',
      'feedback': 'ප්‍රතිපෝෂණ (Feedback)',
      'feedback_desc': 'සැකසුම් වෙතින් නිෂ්පාදන ප්‍රතිපෝෂණ, සේවා සටහන් හෝ ඉක්මන් වෙළඳසැල් යාවත්කාලීන බෙදා ගන්න.',
      'language_settings': 'භාෂා සැකසුම් (Language)',
      'language_settings_desc': 'යෙදුම සඳහා ඔබ කැමති භාෂාව තෝරන්න.',
      'account': 'ගිණුම',
      'select_language': 'භාෂාව තෝරන්න',
      'english': 'English',
      'sinhala': 'සිංහල',
      'tamil': 'தமிழ்',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරකින්න',
      'close': 'වසන්න',
      'home': 'මුල් පිටුව',
      'orders': 'ඇණවුම්',
      'activity': 'ක්‍රියාකාරකම්',
      'language_changed_msg': 'භාෂාව සාර්ථකව සිංහලට යාවත්කාලීන කරන ලදී.',
      'good_morning': 'සුභ උදෑසනක්',
      'good_afternoon': 'සුභ දහවලක්',
      'good_evening': 'සුභ සැන්දෑවක්',
      'search_nestle_products': 'නෙස්ලේ නිෂ්පාදන සොයන්න...',
      'nestle_products': 'නෙස්ලේ නිෂ්පාදන',
      'see_all': 'සියල්ල බලන්න',
      'add_to_cart': 'කරත්තයට එක් කරන්න',
      'proceed_order': 'ඇණවුම ඉදිරියට ගෙනයන්න',
      'view_deals': 'දීමනා බලන්න',
      'promotions': 'ප්‍රවර්ධන සහ දීමනා',
      'no_active_deals': 'දැනට සක්‍රිය ප්‍රවර්ධන නොමැත.',
      'fetching_deals': 'දීමනා ලබා ගනිමින්...',
      'shop_insights': 'වෙළඳසැල් තීක්ෂ්ණ බුද්ධිය (Insights)',
      'performance_summary': 'කාර්ය සාධන සාරාංශය',
      'sales_performance': 'විකුණුම් කාර්ය සාධනය',
      'top_trending_products': 'ඉහළම ප්‍රවණතා නිෂ්පාදන',
      'revenue': 'ආදායම (Revenue)',
      'cases_sold': 'අලෙවි වූ ඇසුරුම්',
      'active_skus': 'සක්‍රිය නිෂ්පාදන (SKUs)',
      'vs_previous': 'පෙර කාලයට සාපේක්ෂව',
    },
    'ta': {
      'settings': 'அமைப்புகள்',
      'settings_desc': 'உங்கள் கணக்கிற்கான அமைப்புகளையும் பாதுகாப்பையும் நிர்வகிக்கவும்.',
      'insights': 'பகுப்பாய்வு (Insights)',
      'insights_desc': 'உங்கள் கடையின் விற்பனை செயல்திறன் விளக்கப்படம் மற்றும் பிரபலமான தயாரிப்புகளைப் பார்க்கவும்.',
      'security': 'பாதுகாப்பு (Security)',
      'security_desc': 'தற்போதைய கடவுச்சொல் மற்றும் புதிய கடவுச்சொல்லை இருமுறை உள்ளிட்டு உங்கள் கடவுச்சொல்லை மாற்றவும்.',
      'feedback': 'கருத்துகள் (Feedback)',
      'feedback_desc': 'தயாரிப்பு கருத்துக்கள், சேவை குறிப்புகள் அல்லது விரைவான கடை அறிவிப்புகளை இங்கிருந்து பகிரவும்.',
      'language_settings': 'மொழி அமைப்புகள் (Language)',
      'language_settings_desc': 'பயன்பாட்டிற்கான உங்கள் விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்.',
      'account': 'கணக்கு',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'english': 'English',
      'sinhala': 'සිங்களம்',
      'tamil': 'தமிழ்',
      'cancel': 'ரத்துசெய்',
      'save': 'சேமி',
      'close': 'மூடு',
      'home': 'முகப்பு',
      'orders': 'கட்டளைகள்',
      'activity': 'நடவடிக்கை',
      'language_changed_msg': 'மொழி வெற்றிகரமாக தமிழுக்கு மாற்றப்பட்டது.',
      'good_morning': 'காலை வணக்கம்',
      'good_afternoon': 'மதிய வணக்கம்',
      'good_evening': 'மாலை வணக்கம்',
      'search_nestle_products': 'நெஸ்லே தயாரிப்புகளைத் தேடுங்கள்...',
      'nestle_products': 'நெஸ்லே தயாரிப்புகள்',
      'see_all': 'அனைத்தையும் காட்டு',
      'add_to_cart': 'வண்டியில் சேர்',
      'proceed_order': 'கட்டளையைத் தொடரவும்',
      'view_deals': 'சலுகைகளைப் பார்க்கவும்',
      'promotions': 'சலுகைகள்',
      'no_active_deals': 'தற்போது செயலில் உள்ள சலுகைகள் இல்லை.',
      'fetching_deals': 'சலுகைகளைப் பெறுகிறது...',
      'shop_insights': 'கடை பகுப்பாய்வு (Insights)',
      'performance_summary': 'செயல்திறன் சுருக்கம்',
      'sales_performance': 'விற்பனை செயல்திறன்',
      'top_trending_products': 'பிரபலமான தயாரிப்புகள்',
      'revenue': 'வருவாய் (Revenue)',
      'cases_sold': 'விற்கப்பட்ட பெட்டிகள்',
      'active_skus': 'செயலில் உள்ள தயாரிப்புகள்',
      'vs_previous': 'முந்தைய காலத்துடன்',
    },
  };

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final stored = await _storage.read(key: _languageKey);
      if (stored != null && _translations.containsKey(stored)) {
        _currentLocale = stored;
      }
    } catch (_) {
      // Fallback to default English
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!_translations.containsKey(languageCode)) return;
    _currentLocale = languageCode;
    try {
      await _storage.write(key: _languageKey, value: languageCode);
    } catch (_) {}
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLocale]?[key] ?? _translations['en']?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String translate(String key) {
    return LocalizationService.instance.translate(key);
  }
}
