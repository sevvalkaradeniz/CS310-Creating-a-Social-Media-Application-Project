import 'package:firebase_analytics/firebase_analytics.dart';

class AppAnalytics {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> setUserId(String userID) async {
    await analytics.setUserId(id: userID);
  }

  static Future<void> setCurrentName(String screenName) async {
    await analytics.setCurrentScreen(screenName: screenName);
  }

  static Future<void> logCustomEvent(
      String logName, Map<String, dynamic> map) async {
    await analytics.logEvent(name: logName, parameters: map);
  }
}
