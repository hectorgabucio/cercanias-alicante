import 'package:flutter/material.dart';
import 'localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String lang;
  final String defaultOrigin;
  final String defaultDestination;
  const SettingsPage({super.key, required this.lang, required this.defaultOrigin, required this.defaultDestination});

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

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    await prefs.setString('defaultOrigin', defaultOrigin);
    await prefs.setString('defaultDestination', defaultDestination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(t(lang, 'settings'), style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: lang,
              items: [
                DropdownMenuItem(value: 'es', child: Text(t(lang, 'spanish'))),
                DropdownMenuItem(value: 'en', child: Text(t(lang, 'english'))),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    lang = value;
                  });
                  await saveSettings();
                }
              },
            ),
            const SizedBox(height: 24),
            Text(t(lang, 'defaultOrigin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: defaultOrigin,
              items: [
                DropdownMenuItem(value: '60913', child: Text('Sant Vicent Centre')),
                DropdownMenuItem(value: '60911', child: Text('Alacant Terminal')),
                // Add more stations as needed
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    defaultOrigin = value;
                  });
                  await saveSettings();
                }
              },
            ),
            const SizedBox(height: 24),
            Text(t(lang, 'defaultDestination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: defaultDestination,
              items: [
                DropdownMenuItem(value: '60913', child: Text('Sant Vicent Centre')),
                DropdownMenuItem(value: '60911', child: Text('Alacant Terminal')),
                // Add more stations as needed
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    defaultDestination = value;
                  });
                  await saveSettings();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
