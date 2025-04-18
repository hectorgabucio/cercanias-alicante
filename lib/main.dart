import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';

void main() {
  runApp(const CercaniasScheduleApp());
}

class CercaniasScheduleApp extends StatelessWidget {
  const CercaniasScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: t('es', 'appTitle'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String lang;
  String selectedOrigin = '60913'; // Sant Vicent Centre
  String selectedDestination = '60911'; // Alacant Terminal
  String defaultOrigin = '60913';
  String defaultDestination = '60911';
  String selectedDay = 'today';
  late Future<List<TrainSchedule>> futureSchedule;
  bool showPastTrains = false;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('lang');
    final savedOrigin = prefs.getString('defaultOrigin');
    final savedDestination = prefs.getString('defaultDestination');
    setState(() {
      if (savedLang != null) lang = savedLang;
      if (savedOrigin != null && stations.containsKey(savedOrigin)) defaultOrigin = savedOrigin;
      if (savedDestination != null && stations.containsKey(savedDestination)) defaultDestination = savedDestination;
      selectedOrigin = defaultOrigin;
      selectedDestination = defaultDestination;
      futureSchedule = fetchSchedule();
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    await prefs.setString('defaultOrigin', defaultOrigin);
    await prefs.setString('defaultDestination', defaultDestination);
  }

  @override
  void initState() {
    super.initState();
    final systemLang = ui.window.locale.languageCode;
    lang = systemLang;
    selectedOrigin = defaultOrigin;
    selectedDestination = defaultDestination;
    futureSchedule = fetchSchedule();
    loadSettings();
  }

  void openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          lang: lang,
          defaultOrigin: defaultOrigin,
          defaultDestination: defaultDestination,
        ),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        lang = result['lang'] ?? lang;
        defaultOrigin = result['defaultOrigin'] ?? defaultOrigin;
        defaultDestination = result['defaultDestination'] ?? defaultDestination;
        selectedOrigin = defaultOrigin;
        selectedDestination = defaultDestination;
        futureSchedule = fetchSchedule();
      });
      await saveSettings();
    }
  }

  static const Map<String, String> stations = {
    "07004": "Aguilas",
    "07007": "Aguilas el Labradorcico",
    "60911": "Alacant Terminal",
    "06008": "Alcantarilla-Los Romanos",
    "06002": "Alhama de Murcia",
    "06100": "Almendricos",
    "62001": "Beniel",
    "62003": "Callosa de Segura",
    "62101": "Crevillent",
    "62108": "Elche-Mercancias",
    "62102": "Elx Carrùs",
    "62103": "Elx Parc",
    "07003": "Jaravia",
    "06004": "La Hoya",
    "06001": "Librilla",
    "06005": "Lorca San Diego",
    "06006": "Lorca-Sutullena",
    "61200": "Murcia del Carmen",
    "61101": "Murcia Mercancias",
    "62002": "Orihuela Miguel Hernández",
    "06007": "Puerto Lumbreras",
    "07001": "Pulpi",
    "62100": "San Isidro-Albatera-Catral",
    "62109": "Sant Gabriel",
    "60913": "Sant Vicent Centre",
    "62104": "Torrellano",
    "06003": "Totana",
    "60914": "Universidad de Alicante",
  };

  static const Map<String, dynamic> stationIcons = {
    "60911": Icons.beach_access, // Alicante - beach
    "60913": Icons.school,       // Sant Vicent Centre - university
    "61200": Icons.location_city, // Murcia del Carmen - city
    "62103": Icons.park,         // Elx Parc - palm park
    "62102": Icons.nature,       // Elx Carrùs - nature
    "62002": Icons.church,       // Orihuela - cathedral
    "62101": Icons.grass,        // Crevillent - grass
    "62100": Icons.landscape,    // San Isidro - landscape
    "60914": Icons.account_balance, // Universidad de Alicante
    // Generic or less known stations
    "07004": Icons.train,
    "07007": Icons.train,
    "06008": Icons.train,
    "06002": Icons.train,
    "06100": Icons.train,
    "62001": Icons.train,
    "62003": Icons.train,
    "62108": Icons.train,
    "07003": Icons.train,
    "06004": Icons.train,
    "06001": Icons.train,
    "06005": Icons.train,
    "06006": Icons.train,
    "61101": Icons.train,
    "06007": Icons.train,
    "07001": Icons.train,
    "62109": Icons.train,
    "62104": Icons.train,
    "06003": Icons.train,
  };

  Future<void> _pickStation({
    required bool isOrigin,
    required BuildContext context,
  }) async {
    final exclude = isOrigin ? selectedDestination : selectedOrigin;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = stations.entries
                .where((e) => e.key != exclude && (query.isEmpty || e.value.toLowerCase().contains(query.toLowerCase())))
                .toList();
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t(lang, 'searchStation'),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (val) => setSheetState(() => query = val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final entry = filtered[i];
                        return ListTile(
                          leading: Icon(
                            stationIcons[entry.key] ?? Icons.train,
                            color: isOrigin ? Color(0xFF5B86E5) : Color(0xFF283E51),
                          ),
                          title: Text(entry.value),
                          onTap: () => Navigator.pop(context, entry.key),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (isOrigin) {
          selectedOrigin = selected;
        } else {
          selectedDestination = selected;
        }
        futureSchedule = fetchSchedule();
      });
    }
  }

  Future<List<TrainSchedule>> fetchSchedule() async {
    final now = DateTime.now();
    final date = selectedDay == 'today' ? now : now.add(const Duration(days: 1));
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('https://horarios.renfe.com/cer/HorariosServlet');
    final body = jsonEncode({
      "nucleo": "41",
      "origen": selectedOrigin,
      "destino": selectedDestination,
      "fchaViaje": formattedDate,
      "validaReglaNegocio": true,
      "tiempoReal": false,
      "servicioHorarios": "VTI",
      "horaViajeOrigen": "00",
      "horaViajeLlegada": "26",
      "accesibilidadTrenes": false
    });
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> horarios = data['horario'] ?? [];
      return horarios.map((h) => TrainSchedule.fromJson(h)).toList();
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open navigation menu',
          ),
        ),
        title: Text(
          t(lang, 'appTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF5B86E5),
              ),
              child: Center(
                child: Text(
                  t(lang, 'settings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(t(lang, 'settings')),
              onTap: () {
                Navigator.pop(context);
                openSettings();
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283E51), Color(0xFF485563), Color(0xFF5B86E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    child: Column(
                      children: [
                        // Day selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: Text(t(lang, 'today')),
                              selected: selectedDay == 'today',
                              onSelected: (selected) {
                                if (selected && selectedDay != 'today') {
                                  setState(() {
                                    selectedDay = 'today';
                                    futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(t(lang, 'tomorrow')),
                              selected: selectedDay == 'tomorrow',
                              onSelected: (selected) {
                                if (selected && selectedDay != 'tomorrow') {
                                  setState(() {
                                    selectedDay = 'tomorrow';
                                    futureSchedule = fetchSchedule();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: showPastTrains,
                              onChanged: (value) {
                                setState(() {
                                  showPastTrains = value;
                                });
                              },
                            ),
                            Text(t(lang, 'showPast')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF5B86E5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickStation(isOrigin: true, context: context),
                                child: Card(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          stationIcons[selectedOrigin] ?? Icons.location_on,
                                          color: Color(0xFF5B86E5),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stations[selectedOrigin] ?? t(lang, 'selectOrigin'),
                                            style: theme.textTheme.bodyLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.expand_more, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: t(lang, 'swapTooltip'),
                              child: FloatingActionButton(
                                heroTag: 'swap',
                                mini: true,
                                backgroundColor: Color(0xFF485563),
                                onPressed: () {
                                  setState(() {
                                    final temp = selectedOrigin;
                                    selectedOrigin = selectedDestination;
                                    selectedDestination = temp;
                                    futureSchedule = fetchSchedule();
                                  });
                                },
                                child: const Icon(Icons.swap_horiz, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.flag_circle, color: Color(0xFF283E51)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickStation(isOrigin: false, context: context),
                                child: Card(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          stationIcons[selectedDestination] ?? Icons.flag_circle,
                                          color: Color(0xFF283E51),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stations[selectedDestination] ?? t(lang, 'selectDestination'),
                                            style: theme.textTheme.bodyLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.expand_more, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<TrainSchedule>>(
                  future: futureSchedule,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No trains found for today.'));
                    }
                    final trains = snapshot.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: trains.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final train = trains[i];
                        final now = DateTime.now();
                        bool isPast = false;
                        if (selectedDay == 'today') {
                          final departureTime = train.departureTime;
                          final parts = departureTime.split(':');
                          if (parts.length == 2) {
                            final h = int.tryParse(parts[0]) ?? 0;
                            final m = int.tryParse(parts[1]) ?? 0;
                            final depTime = DateTime(now.year, now.month, now.day, h, m);
                            if (depTime.isBefore(now)) {
                              isPast = true;
                            }
                          }
                        }
                        if (isPast && !showPastTrains) {
                          return const SizedBox.shrink();
                        }
                        return Opacity(
                          opacity: isPast ? 0.4 : 1.0,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            color: isPast ? Colors.grey[100] : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  train.line,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${t(lang, 'origin')}: ${train.departureTime}  →  ${t(lang, 'destination')}: ${train.arrivalTime}',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPast)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          t(lang, 'past'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${t(lang, 'duration')}: ${train.duration}', style: theme.textTheme.bodySmall),
                                  Text('${t(lang, 'train')}: ${train.trainCode}', style: theme.textTheme.bodySmall),
                                ],
                              ),
                              trailing: train.accessible
                                  ? const Icon(Icons.accessible, color: Colors.green)
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainSchedule {
  final String line;
  final String trainCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final bool accessible;

  TrainSchedule({
    required this.line,
    required this.trainCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.accessible,
  });

  factory TrainSchedule.fromJson(Map<String, dynamic> json) {
    return TrainSchedule(
      line: json['linea'] ?? '',
      trainCode: json['cdgoTren'] ?? '',
      departureTime: json['horaSalida'] ?? '',
      arrivalTime: json['horaLlegada'] ?? '',
      duration: json['duracion'] ?? '',
      accessible: json['accesible'] ?? false,
    );
  }
}

// SETTINGS PAGE
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
              onChanged: (value) => setState(() => lang = value!),
            ),
            const SizedBox(height: 24),
            Text(t(lang, 'defaultOrigin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: defaultOrigin,
              items: _ScheduleScreenState.stations.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => defaultOrigin = value!),
            ),
            const SizedBox(height: 24),
            Text(t(lang, 'defaultDestination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: defaultDestination,
              items: _ScheduleScreenState.stations.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) => setState(() => defaultDestination = value!),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(t(lang, 'save')),
                onPressed: () {
                  Navigator.pop(context, {
                    'lang': lang,
                    'defaultOrigin': defaultOrigin,
                    'defaultDestination': defaultDestination,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
