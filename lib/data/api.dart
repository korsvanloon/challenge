import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:translation_challenge/data/model.dart';
import 'package:http/http.dart' as http;

/*
curl -s -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
    --data "{
  'q': 'The Great Pyramid of Giza (also known as the Pyramid of Khufu or the
        Pyramid of Cheops) is the oldest and largest of the three pyramids in
        the Giza pyramid complex.',
  'source': 'en',
  'target': 'es',
  'format': 'text'
}" "https://translation.googleapis.com/language/translate/v2"
  
 */

class Api {
  final client = http.Client();
  final String rawToken;

  Api(this.rawToken);

  Future<List<Language>> getLanguages() async {
    final db = FirebaseDatabase.instance;
    return db
        .reference()
        .child('languages')
        .reference()
        .orderByKey()
        .onValue
        .map((e) => e.snapshot.value as List)
        .first
        .then((i) => i.cast<Map>().map(_toLanguage).toList());

//    return Future.delayed(
//        Duration(seconds: 2), () => [Language('en', 'English'), Language('nl', 'Dutch')]);
//    final response = await client.get('');
//    return (json.decode(response.body) as List).cast<Map>().map(_toLanguage).toList();
  }

  Future<String> translate(String text, Language source, Language target) async {
    final response =
        await client.post('https://translation.googleapis.com/language/translate/v2', headers: {
      HttpHeaders.authorizationHeader: 'Bearer $rawToken',
    }, body: {
      'q': text,
      'source': source.code,
      'target': target.code,
      'format': 'text',
    });
    // lazy deserialization ^_^
    return ((((json.decode(response.body) as Map)['data'] as Map)['translations'] as List).first
        as Map)['translatedText'];
  }
}

Language _toLanguage(Map input) {
  return Language(input['code'], input['name']);
}
