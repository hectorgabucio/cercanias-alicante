import 'package:flutter/material.dart';
import 'localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stations.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F8FC), Color(0xFFE9F0FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            t(lang, 'settings'),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: Text(t(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: lang,
                        icon: const Icon(Icons.language, color: Color(0xFF4EC7B3)),
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
                        borderRadius: BorderRadius.circular(32),
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Default Origin
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: Text(t(lang, 'defaultOrigin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: defaultOrigin,
                        icon: const Icon(Icons.train, color: Color(0xFF4EC7B3)),
                        items: stations.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              defaultOrigin = value;
                            });
                            await saveSettings();
                          }
                        },
                        borderRadius: BorderRadius.circular(32),
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Default Destination
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: Text(t(lang, 'defaultDestination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: defaultDestination,
                        icon: const Icon(Icons.flag, color: Color(0xFF4EC7B3)),
                        items: stations.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              defaultDestination = value;
                            });
                            await saveSettings();
                          }
                        },
                        borderRadius: BorderRadius.circular(32),
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Custom Footer ---
                  const Divider(height: 40, thickness: 1, color: Color(0xFFE0E0E0)),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Made with ❤️ by Héctor Gabucio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse('https://github.com/hectorgabucio/cercanias-alicante');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Text(
                            'Open source project, found at github.com/hectorgabucio/cercanias-alicante',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4EC7B3),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
