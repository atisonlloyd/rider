
import 'dart:io';


import '../db/app_database.dart';
import '../features/language/domain/models/language_listing_model.dart';

class AppConstants {
  static const String title = 'Rides365 Rider';
  static const String baseUrl = 'https://spot.rides365.app/';
  static String firbaseApiKey = (Platform.isAndroid)
      ? "AIzaSyBt2CXINSMgFhUN2HGRTOewVhGtSHwaFyE"
      : "ios firebase api key";
  static String firebaseAppId =
      (Platform.isAndroid) ? "1:209561528478:android:12ca1169b8c5c21a1bb38f" : "ios firebase app id";
  static String firebasemessagingSenderId = (Platform.isAndroid)
      ? "209561528478"
      : "ios firebase sender id";
  static String firebaseProjectId = (Platform.isAndroid)
      ? "rides365-ef6c5"
      : "ios firebase project id";

  static String mapKey =
      (Platform.isAndroid) ? "AIzaSyAi56YGt4wbuAjnueI7VX0rWezD6atgXBc" : 'ios map key';
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
