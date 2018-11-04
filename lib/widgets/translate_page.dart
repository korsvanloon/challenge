import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:translation_challenge/data/model.dart';
import 'package:translation_challenge/main.dart';

class TranslationPage extends StatefulWidget {
  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final db = FirebaseDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  String result;
  List<Language> languages;
  Language source;
  Language target;
  TextEditingController _textController = TextEditingController();

  bool get isInitialized => languages != null;

  @override
  void initState() {
    super.initState();
    if (!isInitialized) {
      App.repository.languages.then((result) {
        setState(() {
          languages = result;
          source = languages[0];
          target = languages[1];
        });
      });
    }
  }

  Widget languageSelector(String label, Language value, void onChanged(Language v)) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(label),
        ),
        DropdownButton<Language>(
          isDense: true,
          items: languages.map(_languageToOption).toList(),
          onChanged: (s) => setState(() => onChanged(s)),
          value: value,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Translate'),
        ),
        body: isInitialized ? _body() : _loading());
  }

  void _submit() async {
    if (!_formKey.currentState.validate()) return;
    _formKey.currentState.save();

    // hackity hack... please have mercy :)

    final _translationsRef = db.reference().child('translations').reference();

    // look for an existing translation
    final query = _translationsRef
        .orderByChild(source.code)
        .equalTo(_textController.text)
        .limitToFirst(1);
    final entry = ((await query.onValue.first).snapshot.value as Map)?.entries?.first;

    if (entry == null) {
      // ad a new translation
      _translationsRef.onChildChanged.listen((e) {
        setState(() {
          result = (e.snapshot.value as Map)[target.code];
        });
      });
      _translationsRef.push().set({
        source.code: _textController.text,
        target.code: '',
      });
    } else {
      if (entry.key == target) {
        // if already translated in the right language, we're done!
        setState(() {
          result = entry.value;
        });
      } else {
        // update the translation for the new language
        _translationsRef.child(entry.key).update({
          source.code: _textController.text,
          target.code: '',
        });
        _translationsRef.onChildChanged.listen((e) {
          setState(() {
            result = (e.snapshot.value as Map)[target.code];
          });
        });
      }
    }
  }

  _loading() => Center(child: Text('loading...'));

  _body() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                languageSelector('From', source, (value) => source = value),
                languageSelector('To', target, (value) => target = value),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12.0),
            child: TextFormField(
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(hintText: 'Type here to translate'),
              validator: _validateTextInput,
              controller: _textController,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.all(Radius.circular(6.0))),
            child: Text(result ?? ''),
          ),
          MaterialButton(
            onPressed: _submit,
            child: Text('Translate'),
            color: theme.primaryColor,
            textColor: Colors.white,
          ),
          Divider(),
          Text('Test inserts: ', style: theme.textTheme.headline),
          ListView(
            shrinkWrap: true,
            children: [
              testInsertTile('This is a some test data, that can be inserted into the textfield'),
              testInsertTile(
                  'The Great Pyramid of Giza (also known as the Pyramid of Khufu or the Pyramid of Cheops) is the oldest and largest of the three pyramids in the Giza pyramid complex.'),
            ],
          )
        ],
      ),
    );
  }

  ListTile testInsertTile(String value) {
    return ListTile(
      leading: IconButton(
        icon: Icon(Icons.arrow_upward),
        onPressed: () => setState(() => _textController.text = value),
      ),
      title: Text(value, overflow: TextOverflow.ellipsis),
    );
  }
}

String _validateTextInput(String value) {
  if (value.isEmpty) return 'Please enter something to translate';
  return null;
}

DropdownMenuItem<Language> _languageToOption(Language language) {
  return DropdownMenuItem<Language>(
    value: language,
    child: Text(language.name),
  );
}