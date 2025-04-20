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

  static const Map<String, String> stations = {
    "07004": "Aguilas",
    "07007": "Aguilas el Labradorcico",
    "07009": "Almendricos",
    "06013": "Altet",
    "06014": "Aspe",
    "06015": "Beniel",
    "06016": "Callosa de Segura",
    "06017": "Carrús",
    "06018": "Catral",
    "06019": "Crevillente",
    "06020": "Elche Parque/Elx Parc",
    "06021": "Elche Carrús/Elx Carrús",
    "06022": "Elda-Petrer",
    "06023": "La Encina",
    "06024": "Monforte del Cid",
    "06025": "Murcia del Carmen",
    "06026": "Orihuela-Miguel Hernández",
    "06027": "San Isidro-Albatera-Catral",
    "06028": "San Vicente Centre/Sant Vicent Centre",
    "06029": "Torre-Pacheco",
    "06030": "Torrevieja",
    "06031": "Totana",
    "06032": "Villena",
    "60911": "Alacant Terminal",
    "60913": "Sant Vicent Centre",
    // ...add all other stations as needed
  };

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
                          color: Colors.black.withOpacity(0.04),
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
                          color: Colors.black.withOpacity(0.04),
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
                          color: Colors.black.withOpacity(0.04),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
