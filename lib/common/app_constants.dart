
import 'dart:io';


import '../db/app_database.dart';
import '../features/language/domain/models/language_listing_model.dart';

class AppConstants {
  static const String title = 'Rider';
  static const String baseUrl = '';
  static String firbaseApiKey = (Platform.isAndroid)
      ? ""
      : "ios firebase api key";
  static String firebaseAppId =
      (Platform.isAndroid) ? "" : "ios firebase app id";
  static String firebasemessagingSenderId = (Platform.isAndroid)
      ? ""
      : "ios firebase sender id";
  static String firebaseProjectId = (Platform.isAndroid)
      ? ""
      : "ios firebase project id";

  static String mapKey =
      (Platform.isAndroid) ? "" : 'ios map key';
  static const String privacyPolicy = 'your privacy policy url';
  static const String termsCondition = 'your terms and condition url';

  static List<LocaleLanguageList> languageList = [
    LocaleLanguageList(name: 'English', lang: 'en'),
  ];
  static String packageName = '';
  static String signKey = '';
  double headerSize = 18.0;
  double subHeaderSize = 16.0;
  double buttonTextSize = 20.0;
}

bool showBubbleIcon = false;
bool subscriptionSkip = false;
String choosenLanguage = 'en';
String mapType = '';
bool isAppMapChange = false;

AppDatabase db = AppDatabase();
