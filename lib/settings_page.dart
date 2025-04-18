import 'package:flutter/material.dart';
import 'localization.dart';

class SettingsPage extends StatefulWidget {
  final String lang;
  final String defaultOrigin;
  final String defaultDestination;

  const SettingsPage({
    super.key,
    required this.lang,
    required this.defaultOrigin,
    required this.defaultDestination,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String lang;
  late String defaultOrigin;
  late String defaultDestination;

  @override
  void initState() {
    super.initState();
    lang = widget.lang;
    defaultOrigin = widget.defaultOrigin;
    defaultDestination = widget.defaultDestination;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingsAppBar(),
      body: SettingsBody(
        lang: lang,
        defaultOrigin: defaultOrigin,
        defaultDestination: defaultDestination,
        onChanged: (String newLang, String newOrigin, String newDestination) {
          setState(() {
            lang = newLang;
            defaultOrigin = newOrigin;
            defaultDestination = newDestination;
          });
        },
        onSave: () {
          Navigator.pop(context, {
            'lang': lang,
            'defaultOrigin': defaultOrigin,
            'defaultDestination': defaultDestination,
          });
        },
      ),
    );
  }
}

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Text(t('es', 'settings_title'), style: const TextStyle(color: Colors.black)),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }
}

class SettingsBody extends StatelessWidget {
  final String lang;
  final String defaultOrigin;
  final String defaultDestination;
  final void Function(String, String, String) onChanged;
  final VoidCallback onSave;

  const SettingsBody({
    super.key,
    required this.lang,
    required this.defaultOrigin,
    required this.defaultDestination,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: lang,
            items: [
              DropdownMenuItem(
                value: 'es',
                child: Text(t(lang, 'spanish')),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(t(lang, 'english')),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                onChanged(value, defaultOrigin, defaultDestination);
              }
            },
          ),
          const SizedBox(height: 24),
          Text(t(lang, 'default_origin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: defaultOrigin,
            items: [
              DropdownMenuItem(
                value: '60913',
                child: Text(t(lang, 'sant_vicent_centre')),
              ),
              DropdownMenuItem(
                value: '60911',
                child: Text(t(lang, 'alacant_terminal')),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                onChanged(lang, value, defaultDestination);
              }
            },
          ),
          const SizedBox(height: 24),
          Text(t(lang, 'default_destination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: defaultDestination,
            items: [
              DropdownMenuItem(
                value: '60913',
                child: Text(t(lang, 'sant_vicent_centre')),
              ),
              DropdownMenuItem(
                value: '60911',
                child: Text(t(lang, 'alacant_terminal')),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                onChanged(lang, defaultOrigin, value);
              }
            },
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(t(lang, 'save')),
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}
