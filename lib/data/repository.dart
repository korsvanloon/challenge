import 'package:translation_challenge/data/api.dart';
import 'package:translation_challenge/data/model.dart';

class Repository {
  final Api _api;

  List<Language> _languages;

  Repository(this._api);

  Future<List<Language>> get languages async => _languages ??= await _api.getLanguages();
}