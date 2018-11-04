import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:translation_challenge/data/api.dart';
import 'package:translation_challenge/data/repository.dart';

import 'package:translation_challenge/widgets/translate_page.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  static final analytics = FirebaseAnalytics();
  static final observer = FirebaseAnalyticsObserver(analytics: analytics);
  static final api = Api('');
  static final repository = Repository(api);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Translation Challenge',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      navigatorObservers: [observer],
      home: TranslationPage(),
    );
  }
}