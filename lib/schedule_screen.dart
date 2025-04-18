import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization.dart';
import 'models/train_schedule.dart';
import 'settings_page.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String lang;
  String selectedOrigin = '60913';
  String selectedDestination = '60911';
  String defaultOrigin = '60913';
  String defaultDestination = '60911';
  String selectedDay = 'today';
  late Future<List<TrainSchedule>> futureSchedule;
  bool showPastTrains = false;
  late TextEditingController _originController;
  late TextEditingController _destinationController;

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
    "60911": Icons.beach_access,
    "60913": Icons.school,
    "61200": Icons.location_city,
    "62103": Icons.park,
    "62102": Icons.nature,
    "62002": Icons.church,
    "62101": Icons.grass,
    "62100": Icons.landscape,
    "60914": Icons.account_balance,
    // Generic
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

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: stations[selectedOrigin] ?? '');
    _destinationController = TextEditingController(text: stations[selectedDestination] ?? '');
    final systemLang = ui.window.locale.languageCode;
    lang = systemLang;
    selectedOrigin = defaultOrigin;
    selectedDestination = defaultDestination;
    futureSchedule = fetchSchedule();
    loadSettings();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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
      final List<TrainSchedule> allTrains = horarios.map((h) => TrainSchedule.fromJson(h)).toList();
      if (!showPastTrains) {
        final nowTime = DateFormat('HH:mm').format(now);
        // Only show trains with departureTime >= nowTime
        return allTrains.where((t) {
          try {
            return t.departureTime.compareTo(nowTime) >= 0;
          } catch (_) {
            return true;
          }
        }).toList();
      } else {
        return allTrains;
      }
    } else {
      throw Exception('Failed to load schedule');
    }
  }

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
                .where((entry) =>
                    entry.key != exclude &&
                    (entry.value.toLowerCase().contains(query.toLowerCase()) ||
                        entry.key.contains(query)))
                .toList();
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t(lang, 'searchStation'),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        return ListTile(
                          leading: Icon(stationIcons[entry.key] ?? Icons.train),
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
      drawer: ScheduleDrawer(
        lang: lang,
        defaultOrigin: defaultOrigin,
        defaultDestination: defaultDestination,
        onSettings: openSettings,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(lang, 'origin'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _originController.text = '';
                    }
                  },
                  child: Autocomplete<MapEntry<String, String>>(
                    key: const ValueKey('origin-autocomplete'),
                    initialValue: TextEditingValue(text: stations[selectedOrigin] ?? ''),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return stations.entries;
                      }
                      return stations.entries.where((entry) =>
                        entry.value.toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    displayStringForOption: (option) => option.value,
                    onSelected: (option) {
                      setState(() {
                        selectedOrigin = option.key;
                        futureSchedule = fetchSchedule();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _originController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: t(lang, 'searchStation'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onEditingComplete: onEditingComplete,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(t(lang, 'destination'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _destinationController.text = '';
                    }
                  },
                  child: Autocomplete<MapEntry<String, String>>(
                    key: const ValueKey('destination-autocomplete'),
                    initialValue: TextEditingValue(text: stations[selectedDestination] ?? ''),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return stations.entries;
                      }
                      return stations.entries.where((entry) =>
                        entry.value.toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    displayStringForOption: (option) => option.value,
                    onSelected: (option) {
                      setState(() {
                        selectedDestination = option.key;
                        futureSchedule = fetchSchedule();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _destinationController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: t(lang, 'searchStation'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onEditingComplete: onEditingComplete,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                      const SizedBox(width: 16),
                      Switch(
                        value: showPastTrains,
                        onChanged: (value) {
                          setState(() {
                            showPastTrains = value;
                            futureSchedule = fetchSchedule();
                          });
                        },
                      ),
                      Text(t(lang, 'showPast')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: FutureBuilder<List<TrainSchedule>>(
                    future: futureSchedule,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: \\${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(t(lang, 'noTrains')));
                      } else {
                        final schedules = snapshot.data!;
                        return ListView.separated(
                          itemCount: schedules.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final train = schedules[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.train),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${t(lang, 'origin')}: ${train.departureTime}  →  ${t(lang, 'destination')}: ${train.arrivalTime}',
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text('${t(lang, 'duration')}: ${train.duration}', style: theme.textTheme.bodySmall),
                                                Text('${t(lang, 'train')}: ${train.trainCode}', style: theme.textTheme.bodySmall),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            label: Text('${t(lang, 'duration')}: ${train.duration}'),
                                            backgroundColor: Colors.blue.shade50,
                                          ),
                                          Chip(
                                            label: Text('${t(lang, 'train')}: ${train.trainCode}'),
                                            backgroundColor: Colors.green.shade50,
                                          ),
                                          if (train.accessible)
                                            Chip(label: Text(t(lang, 'accessible')), avatar: const Icon(Icons.accessible, size: 16)),
                                          // Add more chips as needed for other train properties
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleDrawer extends StatelessWidget {
  final String lang;
  final String defaultOrigin;
  final String defaultDestination;
  final VoidCallback onSettings;

  const ScheduleDrawer({
    super.key,
    required this.lang,
    required this.defaultOrigin,
    required this.defaultDestination,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class TrainScheduleListItem extends StatelessWidget {
  final TrainSchedule train;
  final String lang;

  const TrainScheduleListItem({super.key, required this.train, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.train),
      // Fix: Wrap the Row in a SingleChildScrollView to avoid overflow
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '${t(lang, 'origin')}: ${train.departureTime}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 8),
            Text(
              '${t(lang, 'destination')}: ${train.arrivalTime}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${t(lang, 'duration')}: ${train.duration}'),
              backgroundColor: Colors.blue.shade50,
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${t(lang, 'train')}: ${train.trainCode}'),
              backgroundColor: Colors.green.shade50,
            ),
          ],
        ),
      ),
      subtitle: train.accessible
          ? Row(children: [Icon(Icons.accessible, color: Colors.green), SizedBox(width: 4), Text(t(lang, 'accessible'))])
          : null,
    );
  }
}
